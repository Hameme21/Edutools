import 'package:intl/intl.dart';
import '../models/class_schedule.dart';
import '../models/academic_notice.dart';
import '../models/calendar_day_schedule.dart';
import '../models/routine_date_range.dart';

class CalendarService {
  final List<ClassSchedule> _classes = [];
  final List<AcademicNotice> _notices = [];

  // Active routine date range window (optional or auto-figured)
  DateTime? _routineStartDate;
  DateTime? _routineEndDate;
  bool _isRoutineAutoFigured = true;
  String? _routineSourceDescription;
  RoutineDateRange? _activeRoutineRange;

  List<ClassSchedule> get classes => List.unmodifiable(_classes);
  List<AcademicNotice> get notices => List.unmodifiable(_notices);

  DateTime? get routineStartDate => _routineStartDate;
  DateTime? get routineEndDate => _routineEndDate;
  bool get isRoutineAutoFigured => _isRoutineAutoFigured;
  String? get routineSourceDescription => _routineSourceDescription;
  RoutineDateRange? get activeRoutineRange => _activeRoutineRange;

  void setClasses(List<ClassSchedule> newClasses) {
    _classes.clear();
    _classes.addAll(newClasses);
  }

  void addClass(ClassSchedule classSchedule) {
    _classes.add(classSchedule);
  }

  void removeClass(String id) {
    _classes.removeWhere((c) => c.id == id);
  }

  void updateClass(ClassSchedule updated) {
    final index = _classes.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _classes[index] = updated;
    }
  }

  void setNotices(List<AcademicNotice> newNotices) {
    _notices.clear();
    _notices.addAll(newNotices);
  }

  void addNotice(AcademicNotice notice) {
    _notices.add(notice);
  }

  void removeNotice(String id) {
    _notices.removeWhere((n) => n.id == id);
  }

  void updateNotice(AcademicNotice updated) {
    final index = _notices.indexWhere((n) => n.id == updated.id);
    if (index >= 0) {
      _notices[index] = updated;
    }
  }

  /// Sets or updates the active routine schedule window
  void setRoutineDateRange({
    required DateTime startDate,
    required DateTime endDate,
    bool isAutoFigured = false,
    String? title,
    String? sourceDescription,
    DateTime? classesSuspendedDate,
    DateTime? finalExamDate,
    DateTime? nextSemesterBeginDate,
  }) {
    _routineStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    _routineEndDate = DateTime(endDate.year, endDate.month, endDate.day);
    _isRoutineAutoFigured = isAutoFigured;
    _routineSourceDescription = sourceDescription ??
        (isAutoFigured
            ? 'Auto-figured from Academic Calendar'
            : 'Customized by user');

    _activeRoutineRange = RoutineDateRange(
      startDate: _routineStartDate!,
      endDate: _routineEndDate!,
      title: title ?? 'Active Trimester Routine',
      sourceDescription: _routineSourceDescription!,
      isAutoFigured: isAutoFigured,
      classesSuspendedDate: classesSuspendedDate,
      finalExamDate: finalExamDate,
      nextSemesterBeginDate: nextSemesterBeginDate,
    );
  }

  /// Clears custom/auto-figured routine window constraints
  void clearRoutineDateRange() {
    _routineStartDate = null;
    _routineEndDate = null;
    _activeRoutineRange = null;
    _routineSourceDescription = null;
    _isRoutineAutoFigured = true;
  }

  /// Checks whether a specific date is within the routine's active start-to-end window
  bool isDateWithinRoutine(DateTime date) {
    if (_routineStartDate == null || _routineEndDate == null) return true;
    final clean = DateTime(date.year, date.month, date.day);
    return (clean.isAtSameMomentAs(_routineStartDate!) ||
            clean.isAfter(_routineStartDate!)) &&
        (clean.isAtSameMomentAs(_routineEndDate!) ||
            clean.isBefore(_routineEndDate!));
  }

  /// Auto-figures routine dates based on official academic calendar notices.
  /// When a notice says "semester begins" or "classes begin", the semester begins directly
  /// from that date (e.g. Oct 27, 2026), never defaulting to the 1st of the month.
  RoutineDateRange autoFigureRoutineDates({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Identify candidate milestone notices
    final rawBeginNotices = _notices.where((n) {
      final t = n.title.toLowerCase();
      return (t.contains('classes begin') ||
              t.contains('trimester begins') ||
              t.contains('semester begins') ||
              t.contains('commencement') ||
              t.contains('begins')) &&
          !t.contains('registration') &&
          !t.contains('advising') &&
          !t.contains('orientation');
    }).toList();

    rawBeginNotices.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Deduplicate notices sharing the exact same begin calendar date
    final List<AcademicNotice> beginNotices = [];
    for (final b in rawBeginNotices) {
      final bDay = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
      if (beginNotices.isEmpty ||
          !DateTime(beginNotices.last.startDate.year, beginNotices.last.startDate.month, beginNotices.last.startDate.day).isAtSameMomentAs(bDay)) {
        beginNotices.add(b);
      }
    }

    final suspensionNotices = _notices.where((n) {
      final t = n.title.toLowerCase();
      return t.contains('suspended') ||
          t.contains('no classes') ||
          t.contains('exam prep');
    }).toList();

    final examNotices = _notices.where((n) {
      final t = n.title.toLowerCase();
      return (t.contains('final exam') || t.contains('final exams')) &&
          n.category == NoticeCategory.exam;
    }).toList();

    // If no notices are available, return a 14-week fallback window
    if (beginNotices.isEmpty) {
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(const Duration(days: 98)); // ~14 weeks
      return RoutineDateRange(
        startDate: start,
        endDate: end,
        title: 'Default Routine Window',
        sourceDescription: 'Default 14-week academic cycle (No notices loaded)',
        isAutoFigured: true,
        isCurrentDatePastSuspension: false,
      );
    }

    // Extract and structure all semesters defined in calendar notices
    final List<_SemesterPeriod> semesters = [];

    for (int i = 0; i < beginNotices.length; i++) {
      final bNotice = beginNotices[i];
      final bStart = DateTime(bNotice.startDate.year, bNotice.startDate.month, bNotice.startDate.day);

      final correspondingSuspension = suspensionNotices.firstWhere(
        (s) => s.startDate.isAfter(bStart),
        orElse: () => AcademicNotice(
          id: '',
          title: '',
          description: '',
          startDate: DateTime(2099),
          endDate: DateTime(2099),
          category: NoticeCategory.other,
        ),
      );

      final correspondingExam = examNotices.firstWhere(
        (e) => e.startDate.isAfter(bStart),
        orElse: () => AcademicNotice(
          id: '',
          title: '',
          description: '',
          startDate: DateTime(2099),
          endDate: DateTime(2099),
          category: NoticeCategory.exam,
        ),
      );

      DateTime? susp = correspondingSuspension.id.isNotEmpty
          ? DateTime(correspondingSuspension.startDate.year,
              correspondingSuspension.startDate.month,
              correspondingSuspension.startDate.day)
          : null;

      DateTime? ex = correspondingExam.id.isNotEmpty
          ? DateTime(correspondingExam.startDate.year,
              correspondingExam.startDate.month,
              correspondingExam.startDate.day)
          : null;

      DateTime effectiveSuspension = susp ?? ex ?? bStart.add(const Duration(days: 90));
      if (susp != null && ex != null && ex.isBefore(effectiveSuspension)) {
        effectiveSuspension = ex;
      }

      DateTime? nextBegin;
      if (i + 1 < beginNotices.length) {
        nextBegin = DateTime(beginNotices[i + 1].startDate.year,
            beginNotices[i + 1].startDate.month, beginNotices[i + 1].startDate.day);
      }

      semesters.add(_SemesterPeriod(
        title: bNotice.title,
        startDate: bStart,
        effectiveSuspension: effectiveSuspension,
        suspensionDate: susp,
        finalExamDate: ex,
        nextSemesterBegin: nextBegin,
      ));
    }

    // Match the active semester
    _SemesterPeriod? matched;
    bool isPastSuspension = false;

    for (int i = 0; i < semesters.length; i++) {
      final sem = semesters[i];
      final termEnd = sem.semesterEndDate;
      if ((today.isAtSameMomentAs(sem.startDate) || today.isAfter(sem.startDate)) &&
          today.isBefore(termEnd)) {
        // If prior semester's final examinations and routine have concluded (after exam week),
        // and we are in the semester vacation or registration period before the next trimester begins,
        // switch to the upcoming trimester!
        if (i + 1 < semesters.length) {
          final nextSem = semesters[i + 1];
          final examConcluded = sem.finalExamDate != null
              ? sem.finalExamDate!.add(const Duration(days: 8))
              : sem.effectiveSuspension.add(const Duration(days: 10));
          if (today.isAfter(examConcluded) || today.isAtSameMomentAs(examConcluded)) {
            matched = nextSem;
            isPastSuspension = false;
            break;
          }
        }
        matched = sem;
        isPastSuspension = today.isAtSameMomentAs(sem.effectiveSuspension) ||
            today.isAfter(sem.effectiveSuspension);
        break;
      }
    }

    // If today is past all semesters in the calendar
    if (matched == null && semesters.isNotEmpty) {
      if (today.isAfter(semesters.last.semesterEndDate) ||
          today.isAtSameMomentAs(semesters.last.effectiveSuspension) ||
          today.isAfter(semesters.last.effectiveSuspension)) {
        matched = semesters.last;
        isPastSuspension = true;
      } else {
        matched = semesters.first;
        isPastSuspension = false;
      }
    }

    matched ??= semesters.first;

    final selectedStart = matched.startDate;
    final selectedEnd = matched.routineEndDate;

    final String reason = isPastSuspension
        ? 'Current date is after classes were suspended (${matched.suspensionDate != null ? DateFormat('MMM d').format(matched.suspensionDate!) : 'Final Exams'}). Auto-figured full routine span from semester begin (${DateFormat('MMM d').format(selectedStart)}) until day before class suspension (${DateFormat('MMM d').format(selectedEnd)}).'
        : 'Auto-figured active routine window from semester begin (${DateFormat('MMM d').format(selectedStart)}) until classes suspended / final exams (${DateFormat('MMM d').format(selectedEnd)}).';

    return RoutineDateRange(
      startDate: selectedStart,
      endDate: selectedEnd,
      title: matched.title,
      sourceDescription: reason,
      isAutoFigured: true,
      isCurrentDatePastSuspension: isPastSuspension,
      classesSuspendedDate: matched.suspensionDate,
      finalExamDate: matched.finalExamDate,
      nextSemesterBeginDate: matched.nextSemesterBegin,
    );
  }

  /// Finds whether date falls into an official Semester Break (holiday between final exams and next trimester begin)
  bool isSemesterBreak(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);

    final examNotices = _notices.where((n) {
      final t = n.title.toLowerCase();
      return (t.contains('final exam') || t.contains('final exams')) &&
          n.category == NoticeCategory.exam;
    }).toList();

    final beginNotices = _notices.where((n) {
      final t = n.title.toLowerCase();
      return (t.contains('classes begin') ||
              t.contains('begins') ||
              t.contains('commencement')) &&
          !t.contains('registration');
    }).toList();

    for (final exam in examNotices) {
      final examEnd = DateTime(exam.endDate.year, exam.endDate.month, exam.endDate.day);
      // Find the next semester begin notice that starts after this exam
      final nextBegin = beginNotices.firstWhere(
        (b) => b.startDate.isAfter(examEnd),
        orElse: () => AcademicNotice(
          id: '',
          title: '',
          description: '',
          startDate: DateTime(2099),
          endDate: DateTime(2099),
          category: NoticeCategory.other,
        ),
      );

      if (nextBegin.id.isNotEmpty) {
        final breakStart = examEnd.add(const Duration(days: 1));
        final breakEnd = DateTime(nextBegin.startDate.year,
                nextBegin.startDate.month, nextBegin.startDate.day)
            .subtract(const Duration(days: 1));

        if ((clean.isAtSameMomentAs(breakStart) || clean.isAfter(breakStart)) &&
            (clean.isAtSameMomentAs(breakEnd) || clean.isBefore(breakEnd))) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks whether a given date is marked as a holiday in the academic calendar or is a Semester Break
  bool isHoliday(DateTime date) {
    if (isSemesterBreak(date)) return true;
    return _notices.any((n) => n.isHoliday && n.coversDate(date));
  }

  /// Returns holiday notices that cover the given date, including auto-generated Semester Break notices
  List<AcademicNotice> getHolidayNotices(DateTime date) {
    final list = _notices.where((n) => n.isHoliday && n.coversDate(date)).toList();

    if (isSemesterBreak(date) && !list.any((n) => n.title.toLowerCase().contains('semester break'))) {
      list.add(AcademicNotice(
        id: 'HOL-SEMESTER-BREAK-${DateFormat('yyyyMMdd').format(date)}',
        title: 'Semester Break (Holiday)',
        description: 'Official university recess between final examinations and next trimester commencement. All classes suspended.',
        startDate: date,
        endDate: date,
        category: NoticeCategory.holiday,
        isHoliday: true,
        priority: NoticePriority.high,
      ));
    }
    return list;
  }

  /// Returns non-holiday academic notices active on that date (fees, exams, events)
  List<AcademicNotice> getOtherNotices(DateTime date) {
    return _notices.where((n) => !n.isHoliday && n.coversDate(date)).toList();
  }

  /// Returns scheduled classes for the day-of-week (1 = Mon ... 7 = Sun)
  List<ClassSchedule> getScheduledClassesForDayOfWeek(int dayOfWeek) {
    final list = _classes.where((c) => c.dayOfWeek == dayOfWeek).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  /// Computes day schedule and enforces:
  /// 1. Holiday Conflict Resolution: classes cancelled on holidays.
  /// 2. Routine Active Date Range: classes suppressed before semester start or after classes suspended / final exams.
  CalendarDaySchedule getDaySchedule(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final hol = isHoliday(cleanDate);
    final holNotices = getHolidayNotices(cleanDate);
    final otherNotices = getOtherNotices(cleanDate);

    final isWithinRoutine = isDateWithinRoutine(cleanDate);
    final scheduledClasses = isWithinRoutine
        ? getScheduledClassesForDayOfWeek(date.weekday)
        : <ClassSchedule>[];

    final isBefore = _routineStartDate != null && cleanDate.isBefore(_routineStartDate!);
    final isAfter = _routineEndDate != null && cleanDate.isAfter(_routineEndDate!);

    String? statusMsg;
    if (!isWithinRoutine && _routineStartDate != null && _routineEndDate != null) {
      if (isBefore) {
        statusMsg = 'Classes have not begun yet for this term (Begins ${DateFormat('MMM d, yyyy').format(_routineStartDate!)}).';
      } else if (isAfter) {
        statusMsg = 'Classes ended / suspended for this term (Concluded ${DateFormat('MMM d, yyyy').format(_routineEndDate!)}).';
      }
    }

    return CalendarDaySchedule(
      date: cleanDate,
      isHoliday: hol,
      holidayNotices: holNotices,
      otherNotices: otherNotices,
      scheduledClasses: scheduledClasses,
      isOutsideRoutineRange: !isWithinRoutine && _routineStartDate != null,
      isBeforeRoutineStart: isBefore,
      isAfterRoutineEnd: isAfter,
      routineStatusMessage: statusMsg,
    );
  }

  /// Returns filtered and sorted upcoming notices from a given date
  List<AcademicNotice> getUpcomingNotices({
    DateTime? fromDate,
    NoticeCategory? category,
    String? query,
    bool includePast = false,
  }) {
    final baseDate = fromDate ?? DateTime.now();
    final today = DateTime(baseDate.year, baseDate.month, baseDate.day);

    var filtered = _notices.where((n) {
      if (!includePast) {
        final end = DateTime(n.endDate.year, n.endDate.month, n.endDate.day);
        if (end.isBefore(today)) return false;
      }

      if (category != null && n.category != category) {
        return false;
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchTitle = n.title.toLowerCase().contains(q);
        final matchDesc = n.description.toLowerCase().contains(q);
        final matchCat = n.categoryName.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchCat) return false;
      }

      return true;
    }).toList();

    int getEffectiveDays(AcademicNotice n) {
      if (n.isHappeningNow(today)) {
        final rem = DateTime(n.endDate.year, n.endDate.month, n.endDate.day).difference(today).inDays;
        return rem < 0 ? 0 : rem;
      }
      final start = DateTime(n.startDate.year, n.startDate.month, n.startDate.day);
      return start.difference(today).inDays;
    }

    filtered.sort((a, b) {
      final daysA = getEffectiveDays(a);
      final daysB = getEffectiveDays(b);
      final diff = daysA.compareTo(daysB);
      if (diff != 0) return diff;
      return a.startDate.compareTo(b.startDate);
    });
    return filtered;
  }

  /// Summary statistics for the dashboard
  Map<String, int> getDashboardStats([DateTime? forDate]) {
    final date = forDate ?? DateTime.now();
    final daySched = getDaySchedule(date);

    final upcomingHolidays = _notices.where((n) {
      if (!n.isHoliday) return false;
      return !n.endDate.isBefore(DateTime(date.year, date.month, date.day));
    }).length;

    final pendingFees = _notices.where((n) {
      if (n.category != NoticeCategory.semesterFee) return false;
      return !n.endDate.isBefore(DateTime(date.year, date.month, date.day));
    }).length;

    return {
      'classesToday': daySched.activeClasses.length,
      'isHolidayToday': daySched.isHoliday ? 1 : 0,
      'cancelledClassesToday': daySched.classesCancelledDueToHoliday ? daySched.scheduledClasses.length : 0,
      'upcomingHolidays': upcomingHolidays,
      'pendingFees': pendingFees,
      'totalClassesLoaded': _classes.length,
      'totalNoticesLoaded': _notices.length,
    };
  }
}

class _SemesterPeriod {
  final String title;
  final DateTime startDate;
  final DateTime effectiveSuspension;
  final DateTime? suspensionDate;
  final DateTime? finalExamDate;
  final DateTime? nextSemesterBegin;

  _SemesterPeriod({
    required this.title,
    required this.startDate,
    required this.effectiveSuspension,
    this.suspensionDate,
    this.finalExamDate,
    this.nextSemesterBegin,
  });

  DateTime get routineEndDate => effectiveSuspension.subtract(const Duration(days: 1));
  DateTime get semesterEndDate => nextSemesterBegin ?? effectiveSuspension.add(const Duration(days: 30));
}

