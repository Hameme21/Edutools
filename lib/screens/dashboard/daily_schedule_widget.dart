import 'package:flutter/material.dart';
import '../../models/calendar_day_schedule.dart';
import '../../models/class_schedule.dart';
import '../../models/academic_notice.dart';
import 'holiday_banner_widget.dart';

class DailyScheduleWidget extends StatelessWidget {
  final CalendarDaySchedule schedule;
  final Function(ClassSchedule)? onCustomizeClassReminder;
  final Function(AcademicNotice)? onCustomizeNoticeReminder;

  const DailyScheduleWidget({
    super.key,
    required this.schedule,
    this.onCustomizeClassReminder,
    this.onCustomizeNoticeReminder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = schedule.date;
    final formattedDate = _formatSelectedDate(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schedule.isHoliday
                        ? 'Academic Holiday • All Classes Removed'
                        : (schedule.isOutsideRoutineRange
                            ? (schedule.isAfterRoutineEnd
                                ? 'Classes Suspended / Term Ended'
                                : 'Term Not Started Yet')
                            : '${schedule.activeClasses.length} ${schedule.activeClasses.length == 1 ? 'class' : 'classes'} scheduled'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: schedule.isHoliday
                          ? const Color(0xFFEF4444)
                          : (schedule.isOutsideRoutineRange
                              ? const Color(0xFFF59E0B)
                              : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            if (schedule.isHoliday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.beach_access_rounded, size: 14, color: Color(0xFFEF4444)),
                    SizedBox(width: 4),
                    Text(
                      'Holiday',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Routine boundary status banner (outside semester / suspended)
        if (schedule.isOutsideRoutineRange && !schedule.isHoliday)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy_rounded, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    schedule.routineStatusMessage ??
                        (schedule.isAfterRoutineEnd
                            ? 'Classes are suspended / semester completed. No routine classes.'
                            : 'Semester has not begun yet. No routine classes.'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 1. Holiday Banner
        if (schedule.isHoliday)
          HolidayBannerWidget(
            schedule: schedule,
            onCustomizeHolidayReminder: onCustomizeNoticeReminder,
          ),

        // 2. Non-Holiday Academic Notices (Fees, Exams, Administrative)
        if (schedule.otherNotices.isNotEmpty) ...[
          Text(
            'TODAY\'S NOTICES & DEADLINES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          ...schedule.otherNotices.map((notice) => _buildNoticeCard(notice, isDark)),
          const SizedBox(height: 16),
        ],

        // 3. Classes Schedule (Completely omitted if isHoliday == true)
        if (!schedule.isHoliday) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLASS TIMETABLE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              if (schedule.activeClasses.isNotEmpty)
                Flexible(
                  child: Text(
                    'Tap 🔔 on class to customize reminder',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (schedule.activeClasses.isEmpty)
            _buildEmptyScheduleCard(isDark)
          else
            ...schedule.activeClasses.map((cls) => _buildActiveClassCard(cls, isDark, context)),
        ],
      ],
    );
  }

  Widget _buildNoticeCard(AcademicNotice notice, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notice.categoryColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notice.categoryColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notice.categoryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(notice.categoryIcon, color: notice.categoryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: notice.categoryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notice.categoryName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      notice.countdownText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: notice.categoryColor,
                      ),
                    ),
                    if (onCustomizeNoticeReminder != null)
                      InkWell(
                        onTap: () => onCustomizeNoticeReminder!(notice),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: notice.reminderEnabled
                                ? notice.categoryColor.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                notice.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                                size: 12,
                                color: notice.reminderEnabled ? notice.categoryColor : Colors.grey,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                notice.reminderEnabled ? 'Reminder' : 'Off',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: notice.reminderEnabled ? notice.categoryColor : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notice.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (notice.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notice.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
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

  Widget _buildActiveClassCard(ClassSchedule cls, bool isDark, BuildContext context) {
    final minutes = cls.customReminderMinutes ?? 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color accent stripe
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: cls.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cls.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cls.courseCode,
                            style: TextStyle(
                              color: cls.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  cls.timeRangeFormatted,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onCustomizeClassReminder != null) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => onCustomizeClassReminder!(cls),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cls.reminderEnabled
                                          ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          cls.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                                          size: 12,
                                          color: cls.reminderEnabled ? const Color(0xFF3B82F6) : Colors.grey,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          cls.reminderEnabled ? '${minutes}m' : 'Off',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: cls.reminderEnabled ? const Color(0xFF3B82F6) : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cls.subject,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.room_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          cls.room,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[800]),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cls.instructor,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[800]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScheduleCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: const [
          Icon(Icons.event_busy_rounded, size: 36, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No classes scheduled for this day',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  static String _formatSelectedDate(DateTime dt) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }
}
