import 'class_schedule.dart';
import 'academic_notice.dart';

class CalendarDaySchedule {
  final DateTime date;
  final bool isHoliday;
  final List<AcademicNotice> holidayNotices;
  final List<AcademicNotice> otherNotices;
  final List<ClassSchedule> scheduledClasses;
  final bool isOutsideRoutineRange;
  final bool isBeforeRoutineStart;
  final bool isAfterRoutineEnd;
  final String? routineStatusMessage;

  CalendarDaySchedule({
    required this.date,
    required this.isHoliday,
    required this.holidayNotices,
    required this.otherNotices,
    required this.scheduledClasses,
    this.isOutsideRoutineRange = false,
    this.isBeforeRoutineStart = false,
    this.isAfterRoutineEnd = false,
    this.routineStatusMessage,
  });

  /// When a holiday falls on a day with scheduled classes,
  /// classes are cancelled and reminders are suppressed.
  bool get classesCancelledDueToHoliday => isHoliday && scheduledClasses.isNotEmpty;

  /// Returns only active classes if NOT a holiday and inside routine window.
  List<ClassSchedule> get activeClasses =>
      (isHoliday || isOutsideRoutineRange) ? [] : scheduledClasses;

  /// Returns true if this day has any notices (holidays, exams, fee deadlines, events)
  bool get hasNotices => holidayNotices.isNotEmpty || otherNotices.isNotEmpty;

  /// Returns total event count (classes + notices)
  int get totalEventCount =>
      ((isHoliday || isOutsideRoutineRange) ? 0 : scheduledClasses.length) +
      holidayNotices.length +
      otherNotices.length;

  /// Holiday names joined
  String get holidayNameSummary =>
      holidayNotices.map((n) => n.title).join(', ');
}

