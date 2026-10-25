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

    int getEffectiveDays(AcademicNotice n) {
      if (n.isHappeningNow(today)) {
        final rem = DateTime(n.endDate.year, n.endDate.month, n.endDate.day).difference(today).inDays;
        return rem < 0 ? 0 : rem;
      }
      return DateTime(n.startDate.year, n.startDate.month, n.startDate.day).difference(today).inDays;
    }

    // Find the immediate next upcoming or ongoing notice (never past, least days left first)
    final upcomingList = notices.where((n) {
      final end = DateTime(n.endDate.year, n.endDate.month, n.endDate.day);
      return !end.isBefore(today);
    }).toList()
      ..sort((a, b) {
        final cmp = getEffectiveDays(a).compareTo(getEffectiveDays(b));
        if (cmp != 0) return cmp;
        return a.startDate.compareTo(b.startDate);
      });

    if (upcomingList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Only take the single next immediate event
    final nextEvent = upcomingList.first;
    final isHappening = nextEvent.isHappeningNow();
    final days = nextEvent.daysRemaining();
    final remainingDays = isHappening ? nextEvent.endDate.difference(today).inDays : days;
    final isUrgent = nextEvent.isHoliday ||
        nextEvent.category == NoticeCategory.semesterFee ||
        nextEvent.category == NoticeCategory.exam ||
        remainingDays <= 3;

    // Distinct, vibrant high-contrast color scheme for countdown badge
    final Color badgeBg;
    final Color badgeBorder;
    final Color badgeContentColor;

    if (nextEvent.isHoliday) {
      badgeBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFD1FAE5);
      badgeBorder = isDark ? const Color(0xFF10B981) : const Color(0xFF34D399);
      badgeContentColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
    } else if (remainingDays <= 1 || isHappening || nextEvent.category == NoticeCategory.exam) {
      badgeBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFEE2E2);
      badgeBorder = isDark ? const Color(0xFFEF4444) : const Color(0xFFF87171);
      badgeContentColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
    } else if (remainingDays <= 3 || nextEvent.category == NoticeCategory.semesterFee) {
      badgeBg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.5) : const Color(0xFFFEF3C7);
      badgeBorder = isDark ? const Color(0xFFF59E0B) : const Color(0xFFFBBF24);
      badgeContentColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    } else {
      badgeBg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.5) : const Color(0xFFDBEAFE);
      badgeBorder = isDark ? const Color(0xFF3B82F6) : const Color(0xFF60A5FA);
      badgeContentColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
    }

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
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeBorder, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: badgeContentColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            nextEvent.countdownText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: badgeContentColor,
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
