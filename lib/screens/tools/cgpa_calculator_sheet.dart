import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const Map<String, double> _gradePoints = {
  'A': 4.00,
  'A-': 3.67,
  'B+': 3.33,
  'B': 3.00,
  'B-': 2.67,
  'C+': 2.33,
  'C': 2.00,
  'C-': 1.67,
  'D+': 1.33,
  'D': 1.00,
  'F': 0.00,
};

class _CourseEntry {
  final TextEditingController nameController = TextEditingController();
  int credits = 3;
  String? grade;
  bool isRetake = false;
  String? oldGrade;

  void dispose() {
    nameController.dispose();
  }
}

class CgpaCalculatorSheet extends StatefulWidget {
  const CgpaCalculatorSheet({super.key});

  @override
  State<CgpaCalculatorSheet> createState() => _CgpaCalculatorSheetState();
}

class _CgpaCalculatorSheetState extends State<CgpaCalculatorSheet> {
  final TextEditingController _prevCgpaCtrl = TextEditingController();
  final TextEditingController _prevCreditsCtrl = TextEditingController();
  final TextEditingController _targetCgpaCtrl = TextEditingController();
  final TextEditingController _remainingCreditsCtrl = TextEditingController(text: '30');

  final List<_CourseEntry> _courses = [];
  bool _prevExpanded = false;
  bool _targetExpanded = false;
  bool _calculated = false;

  double _trimesterGpa = 0;
  double _cumulativeCgpa = 0;
  double _totalCredits = 0;
  double _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _courses.add(_CourseEntry());
    }
  }

  @override
  void dispose() {
    _prevCgpaCtrl.dispose();
    _prevCreditsCtrl.dispose();
    _targetCgpaCtrl.dispose();
    _remainingCreditsCtrl.dispose();
    for (final c in _courses) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCourse() {
    setState(() {
      _courses.add(_CourseEntry());
      _calculated = false;
    });
  }

  void _removeCourse(int index) {
    if (_courses.length <= 1) return;
    setState(() {
      _courses[index].dispose();
      _courses.removeAt(index);
      _calculated = false;
    });
  }

  void _calculate() {
    final prevCgpa = double.tryParse(_prevCgpaCtrl.text) ?? 0;
    final prevCredits = double.tryParse(_prevCreditsCtrl.text) ?? 0;

    double prevPoints = prevCgpa * prevCredits;
    double cumPoints = prevPoints;
    double cumCredits = prevCredits;

    double trimPoints = 0;
    double trimCredits = 0;

    for (final c in _courses) {
      if (c.grade == null) continue;
      final gp = _gradePoints[c.grade] ?? 0;
      final cr = c.credits.toDouble();

      if (c.isRetake && c.oldGrade != null) {
        final oldGp = _gradePoints[c.oldGrade] ?? 0;
        if (oldGp == 0) {
          // Old grade was F — credits weren't earned before
          trimPoints += gp * cr;
          trimCredits += cr;
          cumPoints += gp * cr;
          cumCredits += cr;
        } else {
          // Old grade was not F — credits already counted
          trimPoints += gp * cr;
          trimCredits += cr;
          cumPoints += (gp - oldGp) * cr;
        }
      } else {
        trimPoints += gp * cr;
        trimCredits += cr;
        cumPoints += gp * cr;
        cumCredits += cr;
      }
    }

    setState(() {
      _trimesterGpa = trimCredits > 0 ? trimPoints / trimCredits : 0;
      _cumulativeCgpa = cumCredits > 0 ? cumPoints / cumCredits : 0;
      _totalCredits = cumCredits;
      _totalPoints = cumPoints;
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0x1A8B5CF6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calculate_rounded, color: AppTheme.examColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CGPA Calculator',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'UIU 4.00 Scale • Course-by-Course with Retake',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

          // Scrollable body
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 16),
              children: [
                // Previous Results (collapsible)
                _buildSectionHeader(
                  isDark: isDark,
                  icon: Icons.history_rounded,
                  title: 'Previous Results',
                  subtitle: 'Your CGPA before this trimester',
                  expanded: _prevExpanded,
                  onTap: () => setState(() => _prevExpanded = !_prevExpanded),
                ),
                if (_prevExpanded) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _prevCgpaCtrl,
                          hint: 'Previous CGPA',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _prevCreditsCtrl,
                          hint: 'Credits Completed',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Course list header
                const SizedBox(height: 4),
                _buildLabel('CURRENT TRIMESTER COURSES', isDark),
                const SizedBox(height: 8),

                // Course entries
                for (int i = 0; i < _courses.length; i++)
                  _CourseRow(
                    index: i,
                    entry: _courses[i],
                    isDark: isDark,
                    canRemove: _courses.length > 1,
                    onRemove: () => _removeCourse(i),
                    onChanged: () => setState(() => _calculated = false),
                  ),

                const SizedBox(height: 10),

                // Add Course + Calculate buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addCourse,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Course', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.functions_rounded, size: 16),
                        label: const Text('Calculate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Results
                if (_calculated) ...[
                  const SizedBox(height: 16),
                  _buildResultsCard(isDark),

                  // Target CGPA Planner
                  const SizedBox(height: 12),
                  _buildSectionHeader(
                    isDark: isDark,
                    icon: Icons.track_changes_rounded,
                    title: 'Target CGPA Planner',
                    subtitle: 'Plan your path to a higher CGPA',
                    expanded: _targetExpanded,
                    onTap: () => setState(() => _targetExpanded = !_targetExpanded),
                  ),
                  if (_targetExpanded) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _targetCgpaCtrl,
                            hint: 'Target CGPA',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _remainingCreditsCtrl,
                            hint: 'Remaining Credits',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTargetResult(isDark),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x1A8B5CF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x338B5CF6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _resultColumn(
                  'TRIMESTER GPA',
                  _trimesterGpa.toStringAsFixed(2),
                  isDark,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: _resultColumn(
                  'CUMULATIVE CGPA',
                  _cumulativeCgpa.toStringAsFixed(2),
                  isDark,
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total Credits: ${_totalCredits.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultColumn(String label, String value, bool isDark, {bool highlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 32 : 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.examColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetResult(bool isDark) {
    final targetCgpa = double.tryParse(_targetCgpaCtrl.text);
    final remaining = double.tryParse(_remainingCreditsCtrl.text);

    if (targetCgpa == null || remaining == null || remaining <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Enter your target CGPA and remaining credits above.',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
        ),
      );
    }

    final requiredGpa = (targetCgpa * (_totalCredits + remaining) - _totalPoints) / remaining;

    Color msgColor;
    String msg;
    if (requiredGpa <= 0) {
      msgColor = AppTheme.accentColor;
      msg = 'You have already surpassed your target CGPA of ${targetCgpa.toStringAsFixed(2)}!';
    } else if (requiredGpa > 4.0) {
      msgColor = AppTheme.holidayColor;
      msg = 'Target CGPA ${targetCgpa.toStringAsFixed(2)} is not achievable with $remaining credits. You would need a ${requiredGpa.toStringAsFixed(2)} GPA which exceeds 4.00.';
    } else {
      msgColor = AppTheme.primaryLight;
      msg = 'You need a ${requiredGpa.toStringAsFixed(2)} GPA over ${remaining.toStringAsFixed(0)} credits to reach ${targetCgpa.toStringAsFixed(2)} CGPA.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: msgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: msgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            requiredGpa <= 0
                ? Icons.emoji_events_rounded
                : (requiredGpa > 4.0 ? Icons.warning_amber_rounded : Icons.info_outline_rounded),
            size: 18,
            color: msgColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: msgColor, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.examColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 20,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        color: isDark ? Colors.white54 : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final int index;
  final _CourseEntry entry;
  final bool isDark;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _CourseRow({
    required this.index,
    required this.entry,
    required this.isDark,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Row 1: Course name + delete
          Row(
            children: [
              Text(
                '${index + 1}.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: entry.nameController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Course (e.g. CSE 4502)',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Credits + Grade + Retake checkbox
          Row(
            children: [
              // Credits dropdown
              _DropdownBox<int>(
                value: entry.credits,
                items: const [1, 2, 3, 4],
                labelBuilder: (v) => '$v cr',
                isDark: isDark,
                width: 60,
                onChanged: (v) {
                  entry.credits = v!;
                  onChanged();
                },
              ),
              const SizedBox(width: 6),

              // Grade dropdown
              Expanded(
                child: _DropdownBox<String>(
                  value: entry.grade,
                  hint: 'Grade',
                  items: _gradePoints.keys.toList(),
                  labelBuilder: (v) => '$v (${_gradePoints[v]!.toStringAsFixed(2)})',
                  isDark: isDark,
                  onChanged: (v) {
                    entry.grade = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 6),

              // Retake checkbox
              SizedBox(
                height: 32,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: entry.isRetake,
                        onChanged: (v) {
                          entry.isRetake = v ?? false;
                          if (!entry.isRetake) entry.oldGrade = null;
                          onChanged();
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Retake',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Old grade dropdown (visible when retake is checked)
          if (entry.isRetake) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.replay_rounded, size: 14, color: AppTheme.holidayColor.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  'Old Grade:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownBox<String>(
                    value: entry.oldGrade,
                    hint: 'Select old grade',
                    items: _gradePoints.keys.toList(),
                    labelBuilder: (v) => '$v (${_gradePoints[v]!.toStringAsFixed(2)})',
                    isDark: isDark,
                    onChanged: (v) {
                      entry.oldGrade = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final List<T> items;
  final String Function(T) labelBuilder;
  final bool isDark;
  final double? width;
  final ValueChanged<T?> onChanged;

  const _DropdownBox({
    required this.value,
    this.hint,
    required this.items,
    required this.labelBuilder,
    required this.isDark,
    this.width,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null
              ? Text(hint!, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)))
              : null,
          isExpanded: true,
          isDense: true,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelBuilder(item), style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
