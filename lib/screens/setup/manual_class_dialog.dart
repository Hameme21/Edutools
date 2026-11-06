import 'package:flutter/material.dart';
import '../../models/class_schedule.dart';
import '../../models/course_catalog.dart';
import '../../models/section_offering.dart';
import '../../services/section_catalog_service.dart';
import '../../widgets/searchable_input.dart';

class ManualClassDialog extends StatefulWidget {
  final ClassSchedule? initialClass;
  final Function(ClassSchedule) onSave;

  const ManualClassDialog({super.key, this.initialClass, required this.onSave});

  @override
  State<ManualClassDialog> createState() => _ManualClassDialogState();
}

class _ManualClassDialogState extends State<ManualClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _codeController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _roomController;
  late TextEditingController _instructorController;
  final _sectionController = TextEditingController();
  List<SectionOffering> _sections = [];

  int _dayOfWeek = 1;
  List<String> _faculty = [];
  String _selectedColorHex = '#2563EB';

  final List<String> _colorOptions = [
    '#2563EB', // Blue
    '#059669', // Emerald
    '#7C3AED', // Violet
    '#D97706', // Amber
    '#DB2777', // Pink
    '#0891B2', // Cyan
    '#DC2626', // Red
    '#4F46E5', // Indigo
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialClass;
    _subjectController = TextEditingController(text: init?.subject ?? '');
    _codeController = TextEditingController(text: init?.courseCode ?? '');
    _startController = TextEditingController(text: init?.startTime ?? '09:00');
    _endController = TextEditingController(text: init?.endTime ?? '10:30');
    _roomController = TextEditingController(text: init?.room ?? 'Room 101');
    _instructorController = TextEditingController(text: init?.instructor ?? '');
    _sectionController.text = init?.section ?? '';
    SectionCatalogService.sections().then((values) {
      if (!mounted) return;
      setState(() {
        _sections = values;
        if (missingInstructor(_instructorController.text)) _assignInstructor();
      });
    });
    SectionCatalogService.faculty().then((values) {
      if (mounted) setState(() => _faculty = values);
    });
    _dayOfWeek = init?.dayOfWeek ?? 1;
    _selectedColorHex = init?.colorHex ?? '#2563EB';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _codeController.dispose();
    _startController.dispose();
    _endController.dispose();
    _roomController.dispose();
    _instructorController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cls = ClassSchedule(
        id: widget.initialClass?.id ??
            'CLS-${DateTime.now().millisecondsSinceEpoch}',
        subject: _subjectController.text.trim(),
        courseCode: _codeController.text.trim(),
        section: _sectionController.text.split(' — ').first.trim(),
        dayOfWeek: _dayOfWeek,
        startTime: _startController.text.trim(),
        endTime: _endController.text.trim(),
        room: _roomController.text.trim(),
        instructor: _instructorController.text.trim(),
        colorHex: _selectedColorHex,
      );
      widget.onSave(cls);
      Navigator.of(context).pop();
    }
  }

  void _assignInstructor() {
    final input = _sectionController.text;
    final parts = input.split(' — ');
    final match = assignedSection(_sections, _codeController.text, parts.first,
        program: parts.length > 1 ? parts.last : null);
    if (match != null) {
      _sectionController.text = match.section;
      _instructorController.text = match.facultyName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.initialClass == null
                              ? 'Add Class Routine'
                              : 'Edit Class',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subject Name
                  SearchableInput(
                    controller: _subjectController,
                    options: plannerCourses.map((c) => c.name).toList(),
                    label: 'Subject / Course Title',
                    hint: 'Search course planner courses',
                    onChanged: (value) {
                      final code = courseCodeForTitle(value);
                      if (code != null) {
                        setState(() {
                          _codeController.text = code;
                          _instructorController.clear();
                          _assignInstructor();
                        });
                      }
                    },
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Subject is required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Course Code & Day of Week
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: SearchableInput(
                          controller: _codeController,
                          options: plannerCourses.map((c) => c.code).toList(),
                          label: 'Course Code',
                          hint: 'Search course code',
                          onChanged: (value) {
                            _instructorController.clear();
                            for (final course in plannerCourses) {
                              if (course.code.toLowerCase() ==
                                  value.toLowerCase()) {
                                _subjectController.text = course.name;
                              }
                            }
                            setState(_assignInstructor);
                          },
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Code is required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          initialValue: _dayOfWeek,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Day of Week'),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Monday')),
                            DropdownMenuItem(value: 2, child: Text('Tuesday')),
                            DropdownMenuItem(
                                value: 3, child: Text('Wednesday')),
                            DropdownMenuItem(value: 4, child: Text('Thursday')),
                            DropdownMenuItem(value: 5, child: Text('Friday')),
                            DropdownMenuItem(value: 6, child: Text('Saturday')),
                            DropdownMenuItem(value: 7, child: Text('Sunday')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _dayOfWeek = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Start & End Time (24h)
                  SearchableInput(
                      controller: _sectionController,
                      options: _sections
                          .where((s) =>
                              s.courseKey ==
                              _codeController.text
                                  .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                                  .toUpperCase())
                          .map((s) =>
                              '${s.section} — ${s.facultyName} — ${s.program}')
                          .toList(),
                      label: 'Section',
                      hint: 'Select section to fill instructor',
                      onChanged: (_) {
                        _instructorController.clear();
                        setState(_assignInstructor);
                      }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startController,
                          decoration: const InputDecoration(
                              labelText: 'Start Time (HH:mm)',
                              hintText: '09:00'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Start time required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _endController,
                          decoration: const InputDecoration(
                              labelText: 'End Time (HH:mm)', hintText: '10:30'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'End time required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Room & Instructor
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _roomController,
                          decoration: const InputDecoration(
                              labelText: 'Room / Lab', hintText: 'Lab 402'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SearchableInput(
                          controller: _instructorController,
                          options: _faculty,
                          label: 'Instructor',
                          hint: 'Search name or initial',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Color picker
                  const Text('Card Accent Color',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _colorOptions.map((hex) {
                      final color = Color(
                          int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                      final isSelected =
                          _selectedColorHex.toUpperCase() == hex.toUpperCase();
                      return InkWell(
                        onTap: () => setState(() => _selectedColorHex = hex),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: color.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1)
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(widget.initialClass == null
                          ? 'Add Class'
                          : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
