import 'package:flutter/material.dart';
import '../../state/calendar_state.dart';
import '../../models/class_schedule.dart';
import '../../models/academic_notice.dart';
import 'calendar_view_widget.dart';
import 'daily_schedule_widget.dart';
import 'upcoming_events_countdown_widget.dart';
import '../reminders/class_reminder_dialog.dart';
import '../reminders/notice_reminder_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final CalendarState state;

  const DashboardScreen({super.key, required this.state});

  void _openClassReminderDialog(BuildContext context, ClassSchedule cls) {
    showDialog(
      context: context,
      builder: (ctx) => ClassReminderDialog(
        classSchedule: cls,
        defaultMinutes: state.reminderSettings.classReminderMinutesBefore,
        onSave: ({
          required minutesBefore,
          required applyToAll,
          required enabled,
        }) {
          state.customizeClassReminder(
            classSchedule: cls,
            minutesBefore: minutesBefore,
            applyToAll: applyToAll,
            enabled: enabled,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                applyToAll
                    ? 'Updated reminder for all course classes!'
                    : 'Updated reminder for ${cls.courseCode} (${cls.subject})!',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _openNoticeReminderDialog(BuildContext context, AcademicNotice notice) {
    showDialog(
      context: context,
      builder: (ctx) => NoticeReminderDialog(
        notice: notice,
        defaultSettings: state.reminderSettings,
        onSave: ({
          required reminderTime,
          required dayBefore,
          required applyToAll,
          required enabled,
        }) {
          state.customizeNoticeReminder(
            notice: notice,
            reminderTime: reminderTime,
            dayBefore: dayBefore,
            applyToAll: applyToAll,
            enabled: enabled,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                applyToAll
                    ? (notice.isHoliday ? 'Updated reminder for all holidays!' : 'Updated reminder for all ${notice.categoryName.toLowerCase()} events!')
                    : 'Updated reminder for "${notice.title}"!',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = state.dashboardStats;
    final schedule = state.selectedDaySchedule;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards banner
          _buildStatsRow(stats, isDark, context),
          const SizedBox(height: 16),

          // Upcoming Milestones & Countdowns
          UpcomingEventsCountdownWidget(
            notices: state.notices,
            onSelectDate: (date) => state.selectDate(date),
            onCustomizeReminder: (notice) => _openNoticeReminderDialog(context, notice),
          ),
          const SizedBox(height: 16),

          // Interactive Calendar
          CalendarViewWidget(
            selectedDate: state.selectedDate,
            onDateSelected: (newDate) => state.selectDate(newDate),
            calendarService: state.calendarService,
          ),
          const SizedBox(height: 20),

          // Selected Day Agenda & Class Schedule
          DailyScheduleWidget(
            schedule: schedule,
            onCustomizeClassReminder: (cls) => _openClassReminderDialog(context, cls),
            onCustomizeNoticeReminder: (notice) => _openNoticeReminderDialog(context, notice),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, int> stats, bool isDark, BuildContext context) {
    final classesToday = stats['classesToday'] ?? 0;
    final isHolidayToday = (stats['isHolidayToday'] ?? 0) == 1;
    final cancelledClasses = stats['cancelledClassesToday'] ?? 0;
    final upcomingHolidays = stats['upcomingHolidays'] ?? 0;
    final pendingFees = stats['pendingFees'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 460;
        if (isNarrow) {
          return Column(
            children: [
              _buildStatCard(
                title: 'Classes Today',
                value: isHolidayToday ? 'No Class' : '$classesToday Active',
                subtitle: isHolidayToday ? '$cancelledClasses cancelled (Holiday)' : 'Regular Schedule',
                icon: isHolidayToday ? Icons.beach_access_rounded : Icons.school_rounded,
                accentColor: isHolidayToday ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Holidays Left',
                      value: '$upcomingHolidays Days',
                      icon: Icons.celebration_rounded,
                      accentColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Fee Deadlines',
                      value: '$pendingFees Pending',
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            // Classes today
            Expanded(
              child: _buildStatCard(
                title: 'Classes Today',
                value: isHolidayToday ? 'No Class' : '$classesToday Active',
                subtitle: isHolidayToday ? '$cancelledClasses cancelled (Holiday)' : 'Regular Schedule',
                icon: isHolidayToday ? Icons.beach_access_rounded : Icons.school_rounded,
                accentColor: isHolidayToday ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Upcoming holidays
            Expanded(
              child: _buildStatCard(
                title: 'Holidays Left',
                value: '$upcomingHolidays Days',
                icon: Icons.celebration_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Pending Fees
            Expanded(
              child: _buildStatCard(
                title: 'Fee Deadlines',
                value: '$pendingFees Pending',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
