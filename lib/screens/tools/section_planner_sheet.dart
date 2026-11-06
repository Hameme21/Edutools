import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/section_offering.dart';
import '../../models/section_plan_lifecycle.dart';
import '../../models/class_schedule.dart';
import '../../services/section_catalog_service.dart';
import '../../state/calendar_state.dart';
import '../../widgets/searchable_input.dart';
import '../../widgets/unified_routine_grid.dart';

class SectionPlannerSheet extends StatefulWidget {
  final CalendarState state;
  final Future<List<SectionOffering>> Function() sectionsLoader;
  const SectionPlannerSheet(
      {super.key,
      required this.state,
      this.sectionsLoader = SectionCatalogService.sections});
  @override
  State<SectionPlannerSheet> createState() => _SectionPlannerSheetState();
}

class _SectionPlannerSheetState extends State<SectionPlannerSheet>
    with WidgetsBindingObserver {
  List<SectionOffering>? _catalog;
  final Set<String> _selected = {};
  final Map<String, String> _primary = {};
  String _query = '', _sectionQuery = '', _program = 'All';
  final _courseSearch = TextEditingController();
  final _sectionSearch = TextEditingController();
  String? _error;
  int _limit = 12;
  String? _clearedForEndDate;
  int _savedAtMs = 0;
  Timer? _termTimer;
  String? get _expiredEnd =>
      expiredPlannerEnd(widget.state.routineRange, DateTime.now());
  List<ClassSchedule> get _configured =>
      _expiredEnd == null ? widget.state.classes : [];
  String get _key =>
      'section_plan_fall2026_${widget.state.currentStudent?.email.toLowerCase() ?? 'guest'}';
  List<SectionOffering> get _chosen =>
      _catalog!.where((s) => _selected.contains(s.id)).toList();
  List<SectionOffering> get _active =>
      _chosen.where((s) => _primary[s.courseKey] == s.id).toList();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _termTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _checkTerm());
    _load();
  }

  void _checkTerm() {
    if (mounted &&
        _catalog != null &&
        _expiredEnd != null &&
        _expiredEnd != _clearedForEndDate) {
      _change(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkTerm();
  }

  @override
  void dispose() {
    _termTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _courseSearch.dispose();
    _sectionSearch.dispose();
    super.dispose();
  }

  void _removeSection(SectionOffering section) {
    _change(() {
      _selected.remove(section.id);
      if (_primary[section.courseKey] == section.id) {
        _primary.remove(section.courseKey);
        final remaining =
            _chosen.where((s) => s.courseKey == section.courseKey);
        if (remaining.isNotEmpty) {
          _primary[section.courseKey] = remaining.first.id;
        }
      }
    });
  }

  Future<void> _load() async {
    try {
      final catalog = await widget.sectionsLoader();
      final prefs = await SharedPreferences.getInstance();
      Map? saved;
      try {
        saved = jsonDecode(prefs.getString(_key) ?? 'null') as Map?;
      } catch (_) {}
      saved = rolloverSectionDraft(saved, _expiredEnd, DateTime.now());
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _clearedForEndDate = saved?['clearedForEndDate'] as String?;
        _savedAtMs = (saved?['savedAtMs'] as num?)?.toInt() ?? 0;
        final valid = catalog.map((s) => s.id).toSet();
        _selected.addAll((saved?['selected'] as List? ?? [])
            .whereType<String>()
            .where(valid.contains));
        for (final section in _chosen) {
          _primary.putIfAbsent(section.courseKey, () => section.id);
          if ((saved?['primary'] as Map?)?[section.courseKey] == section.id) {
            _primary[section.courseKey] = section.id;
          }
        }
      });
      if (_expiredEnd != null) await _persistDraft();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Could not load the Fall 2026 section catalog. Reopen this tool to retry.');
      }
    }
  }

  Future<void> _change(VoidCallback action) async {
    if (!mounted) return;
    setState(() {
      if (_expiredEnd != null && _expiredEnd != _clearedForEndDate) {
        final fresh = rolloverSectionDraft({
          'selected': _selected.toList(),
          'primary': _primary,
          'clearedForEndDate': _clearedForEndDate,
          'savedAtMs': _savedAtMs
        }, _expiredEnd, DateTime.now());
        _selected
          ..clear()
          ..addAll((fresh['selected'] as List).cast<String>());
        _primary
          ..clear()
          ..addAll(Map<String, String>.from(fresh['primary'] as Map));
        _clearedForEndDate = fresh['clearedForEndDate'];
      }
      action();
    });
    await _persistDraft();
  }

  Future<void> _persistDraft() async {
    try {
      _savedAtMs = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key,
          jsonEncode({
            'selected': _selected.toList(),
            'primary': _primary,
            'clearedForEndDate': _clearedForEndDate,
            'savedAtMs': _savedAtMs
          }));
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'This draft could not be saved on this device.');
      }
    }
  }

  List<String> _clashes(SectionOffering section) =>
      sectionClashes(section, _active, _configured)
          .map((c) => '${c.courseCode} · ${c.dayName} ${c.timeRangeFormatted}')
          .toSet()
          .toList();
  Widget _card(SectionOffering section, {required bool chosen}) {
    final clashes = _clashes(section);
    final primary = _primary[section.courseKey] == section.id;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  '${section.courseCode} · Section ${section.section} · ${section.program}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(section.title),
              Text(section.facultyLabel,
                  style: Theme.of(context).textTheme.bodySmall),
              if (section.sectionNote.isNotEmpty)
                const Text('Offered if required',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              for (final meeting in section.meetings)
                Text(
                    '${meeting.dayName} ${meeting.timeRangeFormatted} · Room ${meeting.room}'),
              const SizedBox(height: 8),
              Text(
                  clashes.isEmpty
                      ? 'No clash with active plan / configured classes'
                      : 'Clash with ${clashes.join('; ')}',
                  style: TextStyle(
                      color: clashes.isEmpty
                          ? Colors.teal
                          : Theme.of(context).colorScheme.error,
                      fontSize: 12)),
              if (chosen)
                Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(primary ? 'Active section' : 'Backup only',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (!primary)
                        TextButton(
                            onPressed: () => _change(
                                () => _primary[section.courseKey] = section.id),
                            child: const Text('Make active')),
                      TextButton(
                          onPressed: () => _removeSection(section),
                          child: const Text('Remove')),
                    ])
              else
                TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(_primary.containsKey(section.courseKey)
                        ? 'Add backup'
                        : 'Add section'),
                    onPressed: () => _change(() {
                          _selected.add(section.id);
                          _primary.putIfAbsent(
                              section.courseKey, () => section.id);
                        })),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    if (catalog == null) {
      return SafeArea(
          child: SizedBox(
              height: 220,
              child: Center(
                  child: _error == null
                      ? const CircularProgressIndicator()
                      : Text(_error!))));
    }
    final options = catalog
        .where((s) =>
            _query.trim().isNotEmpty &&
            !_selected.contains(s.id) &&
            (_program == 'All' || s.program == _program) &&
            matchesSectionFaculty(s, _sectionQuery) &&
            ('${s.courseCode} ${s.title} ${s.facultyName} ${s.facultyCode}'
                    .toLowerCase()
                    .contains(_query.split(' — ').first.toLowerCase()) ||
                s.courseKey.contains(_query
                    .split(' — ')
                    .first
                    .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                    .toUpperCase())))
        .toList();
    final hasClashes = _active.any((s) => _clashes(s).isNotEmpty);
    return SafeArea(
        child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.92,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(children: [
                    const Expanded(
                        child: Text('Section Planner · Fall 2026',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ])),
              Expanded(
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                if (_expiredEnd != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                          'The previous routine ended on $_expiredEnd. Old semester classes are cleared from this planner. Your new selections are kept.')),
                const Text(
                    'BSCSE / BSDS offerings from the supplied routine. TBA means To be announced. Backups are alternatives and are not added to your routine.'),
                const SizedBox(height: 12),
                SearchableInput(
                    controller: _courseSearch,
                    options: {
                      for (final s in catalog)
                        s.courseCode: '${s.courseCode} — ${s.title}'
                    }.values.toList(),
                    label: '1. Search course',
                    hint: 'Course code or title',
                    onChanged: (value) => setState(() {
                          _query = value;
                          _limit = 12;
                        })),
                const SizedBox(height: 12),
                TextField(
                    controller: _sectionSearch,
                    decoration: const InputDecoration(
                        labelText: '2. Search section or faculty',
                        hintText: 'Section, faculty name or initial',
                        prefixIcon: Icon(Icons.filter_list)),
                    onChanged: (value) => setState(() {
                          _sectionQuery = value;
                          _limit = 12;
                        })),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                    initialValue: _program,
                    decoration: const InputDecoration(labelText: 'Program'),
                    items: ['All', 'BSCSE', 'BSDS']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (p) => setState(() {
                          _program = p!;
                          _limit = 12;
                        })),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 16),
                Text('Available sections · ${options.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_query.trim().isEmpty)
                  const Text(
                      'Search a course, then search or choose a section to add.'),
                for (final section in options.take(_limit))
                  _card(section, chosen: false),
                if (options.length > _limit)
                  TextButton(
                      onPressed: () => setState(() => _limit += 12),
                      child: const Text('Show more sections')),
                const SizedBox(height: 20),
                const Text('Unified Class Routine',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold)),
                Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear section plan'),
                        onPressed: _chosen.isEmpty
                            ? null
                            : () => _change(() {
                                  _selected.clear();
                                  _primary.clear();
                                }))),
                UnifiedRoutineGrid(
                    active: _active,
                    configured: _configured,
                    onRemove: _removeSection),
                const SizedBox(height: 20),
                const Text('Section plan',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    'My plan · ${_active.length} active courses · ${_chosen.length - _active.length} backups'),
                for (final section in _chosen) _card(section, chosen: true),
              ])),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            hasClashes
                                ? 'Resolve active-section clashes before applying.'
                                : _expiredEnd != null
                                    ? 'Apply starts a new routine without the previous semester’s classes. Set the new routine dates in Class Setup afterward.'
                                    : 'Apply replaces configured meetings for these courses. Other courses stay in place.',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        FilledButton(
                            onPressed: _active.isEmpty || hasClashes
                                ? null
                                : () {
                                    widget.state.applyPlannedSections(_active);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Active sections added to your routine. Backups remain in the planner.')));
                                  },
                            child: Text(
                                'Apply ${_active.length} active sections to routine')),
                      ])),
            ])));
  }
}
