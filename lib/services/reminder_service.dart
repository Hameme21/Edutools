import '../models/reminder_notification.dart';
import '../models/academic_notice.dart';
import '../models/reminder_settings.dart';
import 'calendar_service.dart';

class ReminderService {
  final CalendarService _calendarService;
  final List<ReminderNotification> _notifications = [];
  ReminderSettings _settings = const ReminderSettings();

  ReminderService(this._calendarService);

  List<ReminderNotification> get notifications => List.unmodifiable(_notifications);
  ReminderSettings get settings => _settings;

  int get unreadCount => _notifications.where((n) => !n.isRead && !n.isMutedDueToHoliday).length;

  void updateSettings(ReminderSettings newSettings, {DateTime? referenceDate}) {
    _settings = newSettings;
    refreshReminders(referenceDate: referenceDate);
  }

  /// Generates reminders for a given date range.
  /// Enforces Holiday Rule: Class reminders are SUPPRESSED if the date is a holiday.
  /// Reminder Rules:
  /// - Holidays: Default 8:00 AM on holiday morning (Customizable per holiday or for all holidays).
  /// - Classes: Default 10 mins before class start time (Customizable per course or for all courses).
  /// - Normal events: Default day before at 10:00 PM (Customizable per event or for all events).
  void refreshReminders({DateTime? referenceDate, int daysAhead = 21}) {
    final base = referenceDate ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    _notifications.clear();

    for (int d = 0; d <= daysAhead; d++) {
      final date = today.add(Duration(days: d));
      final daySchedule = _calendarService.getDaySchedule(date);

      // 1. HOLIDAY REMINDERS (Default: 8:00 AM, or notice custom override)
      if (daySchedule.isHoliday) {
        if (_settings.enableHolidayReminders) {
          for (var holiday in daySchedule.holidayNotices) {
            if (!holiday.reminderEnabled) continue;

            final reminderTimeOfDay = holiday.customReminderTime ?? _settings.holidayReminderTime;
            final holReminderTime = DateTime(
              date.year,
              date.month,
              date.day,
              reminderTimeOfDay.hour,
              reminderTimeOfDay.minute,
            );

            _notifications.add(ReminderNotification(
              id: 'REM-HOL-${holiday.id}-${date.toIso8601String().split('T').first}',
              title: '🎉 Holiday Alert: ${holiday.title}',
              body: d == 0
                  ? 'Today is an official holiday (${holiday.title}). All classes are cancelled!'
                  : 'Upcoming holiday on ${_formatDate(date)}. Campus closed and classes suspended.',
              scheduledFor: holReminderTime,
              type: NotificationType.holidayAlert,
              relatedId: holiday.id,
              isMutedDueToHoliday: false,
            ));
          }
        }

        // Suppress classes on this day
        if (daySchedule.scheduledClasses.isNotEmpty) {
          for (var cls in daySchedule.scheduledClasses) {
            _notifications.add(ReminderNotification(
              id: 'MUTED-CLS-${cls.id}-${date.toIso8601String().split('T').first}',
              title: 'Class Cancelled: ${cls.subject}',
              body: 'Silenced: No class due to holiday (${daySchedule.holidayNameSummary}).',
              scheduledFor: DateTime(date.year, date.month, date.day, cls.parsedStartTime.hour, cls.parsedStartTime.minute),
              type: NotificationType.classReminder,
              relatedId: cls.id,
              isMutedDueToHoliday: true, // Marked muted / silenced
            ));
          }
        }
      } else {
        // 2. CLASS REMINDERS (Default: 10 mins before class, or class custom override)
        if (_settings.enableClassReminders) {
          for (var cls in daySchedule.activeClasses) {
            if (!cls.reminderEnabled) continue;

            final minutesBefore = cls.customReminderMinutes ?? _settings.classReminderMinutesBefore;
            final classTime = DateTime(
              date.year,
              date.month,
              date.day,
              cls.parsedStartTime.hour,
              cls.parsedStartTime.minute,
            );
            final reminderTime = classTime.subtract(Duration(minutes: minutesBefore));

            _notifications.add(ReminderNotification(
              id: 'REM-CLS-${cls.id}-${date.toIso8601String().split('T').first}',
              title: '📚 Class in $minutesBefore mins: ${cls.subject}',
              body: '${cls.courseCode} at ${cls.startTime} in ${cls.room} (${cls.instructor}).',
              scheduledFor: reminderTime,
              type: NotificationType.classReminder,
              relatedId: cls.id,
              isMutedDueToHoliday: false,
            ));
          }
        }
      }

      // 3. NORMAL EVENT REMINDERS (Default: Day before at 10:00 PM / 22:00, or notice custom override)
      if (_settings.enableNormalEventReminders) {
        for (var notice in daySchedule.otherNotices) {
          if (!notice.reminderEnabled) continue;

          final remindDayBefore = notice.customRemindDayBefore ?? _settings.normalEventRemindDayBefore;
          final timeOfDay = notice.customReminderTime ?? _settings.normalEventReminderTime;

          DateTime eventReminderTime;
          String reminderTitlePrefix;

          if (remindDayBefore) {
            final dayBefore = date.subtract(const Duration(days: 1));
            eventReminderTime = DateTime(
              dayBefore.year,
              dayBefore.month,
              dayBefore.day,
              timeOfDay.hour,
              timeOfDay.minute,
            );
            reminderTitlePrefix = '⏰ Tomorrow:';
          } else {
            eventReminderTime = DateTime(
              date.year,
              date.month,
              date.day,
              timeOfDay.hour,
              timeOfDay.minute,
            );
            reminderTitlePrefix = '📢 Today:';
          }

          if (notice.category == NoticeCategory.semesterFee) {
            _notifications.add(ReminderNotification(
              id: 'REM-FEE-${notice.id}-${date.toIso8601String().split('T').first}',
              title: '$reminderTitlePrefix ${notice.title}',
              body: 'Semester fee deadline on ${_formatDate(date)}. ${notice.description}',
              scheduledFor: eventReminderTime,
              type: NotificationType.feeReminder,
              relatedId: notice.id,
            ));
          } else if (notice.category == NoticeCategory.exam) {
            _notifications.add(ReminderNotification(
              id: 'REM-EXAM-${notice.id}-${date.toIso8601String().split('T').first}',
              title: '$reminderTitlePrefix ${notice.title}',
              body: 'Examination scheduled for ${_formatDate(date)}. Prepare your student ID & materials.',
              scheduledFor: eventReminderTime,
              type: NotificationType.examReminder,
              relatedId: notice.id,
            ));
          } else {
            _notifications.add(ReminderNotification(
              id: 'REM-NOT-${notice.id}-${date.toIso8601String().split('T').first}',
              title: '$reminderTitlePrefix ${notice.title}',
              body: notice.description.isNotEmpty ? notice.description : 'Scheduled for ${_formatDate(date)}.',
              scheduledFor: eventReminderTime,
              type: NotificationType.generalNotice,
              relatedId: notice.id,
            ));
          }
        }
      }
    }

    // Sort by scheduled time
    _notifications.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx].isRead = true;
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
  }

  void clearAll() {
    _notifications.clear();
  }

  static String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
