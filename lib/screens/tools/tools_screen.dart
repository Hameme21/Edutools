import 'package:flutter/material.dart';
import '../../state/calendar_state.dart';
import '../../theme/app_theme.dart';
import 'cgpa_calculator_sheet.dart';
import 'tuition_calculator_sheet.dart';

class _ToolItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<String> chips;
  final String action;

  const _ToolItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.chips,
    required this.action,
  });
}

class ToolsScreen extends StatelessWidget {
  final CalendarState state;

  const ToolsScreen({super.key, required this.state});

  static const _tools = <_ToolItem>[
    _ToolItem(
      title: 'Academic Calendar',
      description: 'Interactive monthly calendar with holiday conflict resolution, class schedules, exam dates, and automated reminders.',
      icon: Icons.calendar_month_rounded,
      color: AppTheme.primaryLight,
      bgColor: Color(0x1A3B82F6),
      chips: ['Holidays', 'Exams', 'Reminders'],
      action: 'dashboard',
    ),
    _ToolItem(
      title: 'Academic Notices & Deadlines',
      description: 'Track official university notices — holidays, fee payment dates, midterm & final exams, and course withdrawal deadlines.',
      icon: Icons.campaign_rounded,
      color: AppTheme.feeColor,
      bgColor: Color(0x1AF59E0B),
      chips: ['Fees', 'Exams', 'Drops'],
      action: 'notices',
    ),
    _ToolItem(
      title: 'Routine Setup & .ICS Export',
      description: 'Build your weekly class timetable, import .ICS / JSON / CSV files, sync official calendar, and export schedules.',
      icon: Icons.edit_calendar_rounded,
      color: AppTheme.accentColor,
      bgColor: Color(0x1A10B981),
      chips: ['.ICS Export', 'Import', 'Sync'],
      action: 'setup',
    ),
    _ToolItem(
      title: 'CGPA Calculator',
      description: 'Calculate your cumulative GPA across semesters. Add semester-wise GPA and credits to get an accurate CGPA instantly.',
      icon: Icons.calculate_rounded,
      color: AppTheme.examColor,
      bgColor: Color(0x1A8B5CF6),
      chips: ['Multi-Semester', 'UIU Scale'],
      action: 'cgpa',
    ),
    _ToolItem(
      title: 'Tuition Fee Calculator',
      description: 'Estimate your semester tuition fees based on credits, department, and waiver percentage with installment breakdown.',
      icon: Icons.account_balance_wallet_rounded,
      color: AppTheme.holidayColor,
      bgColor: Color(0x1AEF4444),
      chips: ['Credits', 'Waivers', 'Installments'],
      action: 'tuition',
    ),
    _ToolItem(
      title: 'Holiday Planner',
      description: 'View all official university holidays at a glance — plan trips, track remaining off-days, and set custom reminders.',
      icon: Icons.beach_access_rounded,
      color: Color(0xFF14B8A6),
      bgColor: Color(0x1A14B8A6),
      chips: ['2026 Calendar', 'Reminders'],
      action: 'holidays',
    ),
  ];

  void _handleToolTap(BuildContext context, String action) {
    switch (action) {
      case 'dashboard':
        state.setTabIndex(0);
      case 'notices':
        state.setTabIndex(1);
      case 'setup':
        state.setTabIndex(2);
      case 'cgpa':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CgpaCalculatorSheet(),
        );
      case 'tuition':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const TuitionCalculatorSheet(),
        );
      case 'holidays':
        state.setTabIndex(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Hero header
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.construction_rounded, color: AppTheme.primaryLight, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Academic Toolkit',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'All your essential university tools in one place.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tools grid
        ..._tools.map((tool) => _ToolCard(
          tool: tool,
          isDark: isDark,
          onTap: () => _handleToolTap(context, tool.action),
        )),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  final bool isDark;
  final VoidCallback onTap;

  const _ToolCard({
    required this.tool,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: tool.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tool.icon, color: tool.color, size: 22),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x1A10B981),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  tool.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tool.description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tool.chips.map((chip) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            chip,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
