import 'package:flutter/material.dart';
import '../../models/calendar_day_schedule.dart';
import '../../models/academic_notice.dart';

class HolidayBannerWidget extends StatelessWidget {
  final CalendarDaySchedule schedule;
  final Function(AcademicNotice)? onCustomizeHolidayReminder;

  const HolidayBannerWidget({
    super.key,
    required this.schedule,
    this.onCustomizeHolidayReminder,
  });

  @override
  Widget build(BuildContext context) {
    if (!schedule.isHoliday) return const SizedBox.shrink();

    final holidayNames = schedule.holidayNotices.map((n) => n.title).join(' • ');
    final holidayDescs = schedule.holidayNotices.map((n) => n.description).where((d) => d.isNotEmpty).join(' ');
    final primaryHoliday = schedule.holidayNotices.isNotEmpty ? schedule.holidayNotices.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.beach_access_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'OFFICIAL ACADEMIC HOLIDAY',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      holidayNames,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (holidayDescs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              holidayDescs,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Bottom Bar with Silenced Tag & Custom Reminder Action
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.notifications_off_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'No classes held today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (primaryHoliday != null && onCustomizeHolidayReminder != null)
                InkWell(
                  onTap: () => onCustomizeHolidayReminder!(primaryHoliday),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.alarm_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Reminder settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
