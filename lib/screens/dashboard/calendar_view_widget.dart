import 'package:flutter/material.dart';
import '../../services/calendar_service.dart';
import '../../models/academic_notice.dart';

class CalendarViewWidget extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final CalendarService calendarService;

  const CalendarViewWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.calendarService,
  });

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  late DateTime _displayedMonth;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
    });
    widget.onDateSelected(now);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final monthName = _getMonthName(_displayedMonth.month);
    final yearStr = _displayedMonth.year.toString();

    // Days in current month
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Weekday of 1st day (1=Mon ... 7=Sun)
    final startingWeekday = firstDayOfMonth.weekday; // 1 to 7

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dragDistance = 0,
      onHorizontalDragUpdate: (details) => _dragDistance += details.primaryDelta ?? 0,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_dragDistance < -40 || velocity < -100) {
          _nextMonth();
        } else if (_dragDistance > 40 || velocity > 100) {
          _previousMonth();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Month & Year + Prev/Next + Today
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$monthName $yearStr',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _goToToday,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      onPressed: _previousMonth,
                      splashRadius: 18,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 22),
                      onPressed: _nextMonth,
                      splashRadius: 18,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Day of week labels
            Row(
              children: const [
                _WeekdayHeader('Mon'),
                _WeekdayHeader('Tue'),
                _WeekdayHeader('Wed'),
                _WeekdayHeader('Thu'),
                _WeekdayHeader('Fri'),
                _WeekdayHeader('Sat'),
                _WeekdayHeader('Sun'),
              ],
            ),
            const SizedBox(height: 8),

            // Calendar Grid
            _buildCalendarGrid(daysInMonth, startingWeekday, today, isDark),
            const SizedBox(height: 12),

            // Legend
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 6,
              children: [
                _buildLegendItem(const Color(0xFFEF4444), 'Holiday'),
                _buildLegendItem(const Color(0xFF3B82F6), 'Class'),
                _buildLegendItem(const Color(0xFFF59E0B), 'Fee Deadline'),
                _buildLegendItem(const Color(0xFF8B5CF6), 'Exam'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int startingWeekday, DateTime today, bool isDark) {
    final List<Widget> dayWidgets = [];

    // Empty cells before 1st day
    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox(height: 42));
    }

    // Days of current month
    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isSelected = widget.selectedDate.year == cellDate.year &&
          widget.selectedDate.month == cellDate.month &&
          widget.selectedDate.day == cellDate.day;
      final isToday = today.year == cellDate.year &&
          today.month == cellDate.month &&
          today.day == cellDate.day;

      final isHoliday = widget.calendarService.isHoliday(cellDate);
      final otherNotices = widget.calendarService.getOtherNotices(cellDate);
      final hasClasses = widget.calendarService.getScheduledClassesForDayOfWeek(cellDate.weekday).isNotEmpty;

      final hasFeeNotice = otherNotices.any((n) => n.category == NoticeCategory.semesterFee);
      final hasExamNotice = otherNotices.any((n) => n.category == NoticeCategory.exam);
      final hasEventNotice = otherNotices.any((n) => n.category == NoticeCategory.event || n.category == NoticeCategory.administrative);

      dayWidgets.add(
        InkWell(
          onTap: () => widget.onDateSelected(cellDate),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (isHoliday
                      ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.12)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isHoliday
                            ? const Color(0xFFDC2626)
                            : (isDark ? Colors.white : const Color(0xFF1E293B))),
                  ),
                ),
                const SizedBox(height: 3),
                // Indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isHoliday)
                      _dot(isSelected ? Colors.white : const Color(0xFFEF4444))
                    else if (hasClasses)
                      _dot(isSelected ? Colors.white : const Color(0xFF3B82F6)),
                    if (hasFeeNotice) ...[
                      const SizedBox(width: 2),
                      _dot(isSelected ? Colors.amberAccent : const Color(0xFFF59E0B)),
                    ],
                    if (hasExamNotice) ...[
                      const SizedBox(width: 2),
                      _dot(isSelected ? Colors.purpleAccent : const Color(0xFF8B5CF6)),
                    ],
                    if (hasEventNotice && !hasFeeNotice && !hasExamNotice) ...[
                      const SizedBox(width: 2),
                      _dot(isSelected ? Colors.tealAccent : const Color(0xFF10B981)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: dayWidgets,
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String text;
  const _WeekdayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
