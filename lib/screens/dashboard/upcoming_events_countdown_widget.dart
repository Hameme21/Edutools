import 'package:flutter/material.dart';
import '../../models/academic_notice.dart';

class UpcomingEventsCountdownWidget extends StatelessWidget {
  final List<AcademicNotice> notices;
  final Function(DateTime) onSelectDate;
  final Function(AcademicNotice)? onCustomizeReminder;

  const UpcomingEventsCountdownWidget({
    super.key,
    required this.notices,
    required this.onSelectDate,
    this.onCustomizeReminder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the immediate next upcoming or ongoing notice
    final upcomingList = notices.where((n) {
      final end = DateTime(n.endDate.year, n.endDate.month, n.endDate.day);
      return !end.isBefore(today);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (upcomingList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Only take the single next immediate event
    final nextEvent = upcomingList.first;
    final days = nextEvent.daysRemaining();
    final isUrgent = nextEvent.isHoliday ||
        nextEvent.category == NoticeCategory.semesterFee ||
        nextEvent.category == NoticeCategory.exam ||
        (days >= 0 && days <= 3);

    return InkWell(
      onTap: () => onSelectDate(nextEvent.startDate),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Colors.white, const Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUrgent
                ? nextEvent.categoryColor.withValues(alpha: 0.5)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isUrgent ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Section label & Countdown Badge ("3 days left")
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: nextEvent.categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(nextEvent.categoryIcon, size: 16, color: nextEvent.categoryColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'NEXT UPCOMING MILESTONE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Countdown badge (e.g. "3 days left")
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: isUrgent ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: isUrgent ? const Color(0xFFEF4444) : Colors.grey[700],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            nextEvent.countdownText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isUrgent ? const Color(0xFFEF4444) : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Event Title
            Text(
              nextEvent.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            if (nextEvent.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                nextEvent.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Footer: Date range + Category pill + Reminder action
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: nextEvent.categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    nextEvent.categoryName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: nextEvent.categoryColor,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventDate(nextEvent.startDate, nextEvent.endDate),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (onCustomizeReminder != null) ...[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: InkWell(
                      onTap: () => onCustomizeReminder!(nextEvent),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: nextEvent.reminderEnabled
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              nextEvent.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                              size: 13,
                              color: nextEvent.reminderEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              nextEvent.reminderEnabled ? 'Reminder' : 'Off',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: nextEvent.reminderEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                Text(
                  'Calendar →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatEventDate(DateTime start, DateTime end) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${months[start.month - 1]} ${start.day}, ${start.year}';
    } else if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.day} - ${end.day}, ${start.year}';
    } else {
      return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}, ${start.year}';
    }
  }
}
