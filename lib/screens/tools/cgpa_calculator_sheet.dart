import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CgpaCalculatorSheet extends StatefulWidget {
  const CgpaCalculatorSheet({super.key});

  @override
  State<CgpaCalculatorSheet> createState() => _CgpaCalculatorSheetState();
}

class _SemesterEntry {
  final TextEditingController gpaController = TextEditingController();
  final TextEditingController creditsController = TextEditingController();

  void dispose() {
    gpaController.dispose();
    creditsController.dispose();
  }
}

class _CgpaCalculatorSheetState extends State<CgpaCalculatorSheet> {
  final List<_SemesterEntry> _semesters = [];
  double? _cgpa;
  double _totalCredits = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _semesters.add(_SemesterEntry());
    }
  }

  @override
  void dispose() {
    for (final s in _semesters) {
      s.dispose();
    }
    super.dispose();
  }

  void _addSemester() {
    setState(() {
      _semesters.add(_SemesterEntry());
    });
  }

  void _removeSemester(int index) {
    if (_semesters.length <= 1) return;
    setState(() {
      _semesters[index].dispose();
      _semesters.removeAt(index);
      _cgpa = null;
    });
  }

  void _calculate() {
    double totalPoints = 0;
    double totalCredits = 0;

    for (final s in _semesters) {
      final gpa = double.tryParse(s.gpaController.text);
      final credits = double.tryParse(s.creditsController.text);
      if (gpa != null && credits != null && credits > 0) {
        totalPoints += gpa * credits;
        totalCredits += credits;
      }
    }

    setState(() {
      _totalCredits = totalCredits;
      _cgpa = totalCredits > 0 ? totalPoints / totalCredits : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                        'UIU 4.00 GPA Scale',
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

          // Semester list
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 16),
              shrinkWrap: true,
              children: [
                for (int i = 0; i < _semesters.length; i++)
                  _SemesterRow(
                    index: i,
                    entry: _semesters[i],
                    isDark: isDark,
                    canRemove: _semesters.length > 1,
                    onRemove: () => _removeSemester(i),
                  ),

                const SizedBox(height: 10),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addSemester,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Semester', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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

                // Result
                if (_cgpa != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x1A8B5CF6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x338B5CF6)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CUMULATIVE GPA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _cgpa!.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.examColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Credits: ${_totalCredits.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterRow extends StatelessWidget {
  final int index;
  final _SemesterEntry entry;
  final bool isDark;
  final bool canRemove;
  final VoidCallback onRemove;

  const _SemesterRow({
    required this.index,
    required this.entry,
    required this.isDark,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Semester ${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: entry.gpaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'GPA',
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
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: entry.creditsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Credits',
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
            ),
          ),
          if (canRemove)
            IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          else
            const SizedBox(width: 32),
        ],
      ),
    );
  }
}
