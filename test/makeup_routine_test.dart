import 'package:flutter_test/flutter_test.dart';
import 'package:educal/models/academic_notice.dart';
import 'package:educal/models/class_schedule.dart';
import 'package:educal/models/routine_day_override.dart';
import 'package:educal/models/reminder_notification.dart';
import 'package:educal/services/calendar_service.dart';
import 'package:educal/services/file_parser_service.dart';
import 'package:educal/services/reminder_service.dart';
import 'package:educal/services/sample_data_service.dart';

void main() {
  test('understands source weekdays, abbreviations and description fallback', () {
    expect(routineDayFromNotice('Make-up class (Tue Classes)', ''), 2);
    expect(routineDayFromNotice('Regular Sunday Class (online)',
        'Sunday classes held on Thursday'), 7);
    expect(routineDayFromNotice('Makeup classes', 'Follow Saturday routine on Thursday'), 6);
    expect(routineDayFromNotice('Registration deadline on Sunday', ''), isNull);
    expect(routineDayFromNotice('Saturday classes and Sunday classes', ''), isNull);
  });

  late CalendarService calendar;
  setUp(() {
    calendar = CalendarService();
    calendar.setNotices(SampleDataService.getOfficialAcademicCalendar());
    for (final day in [4, 6, 7, 3, 2]) {
      calendar.addClass(ClassSchedule(id: 'class-$day', subject: 'Subject $day',
          courseCode: 'CSE$day', dayOfWeek: day, startTime: '09:51',
          endTime: '11:10', room: '827', instructor: 'Faculty'));
    }
  });

  test('official makeup dates use only the source routine and leave normal days intact', () {
    for (final entry in {
      DateTime(2026, 11, 5): 6, DateTime(2026, 11, 12): 6,
      DateTime(2026, 11, 26): 7, DateTime(2026, 12, 17): 3,
      DateTime(2026, 12, 31): 6, DateTime(2026, 4, 13): 2,
    }.entries) {
      final classes = calendar.getDaySchedule(entry.key).activeClasses;
      expect(classes.map((c) => c.id), ['class-${entry.value}']);
      expect(classes.single.startTime, '09:51');
    }
    expect(calendar.getDaySchedule(DateTime(2026, 11, 19)).activeClasses.single.id, 'class-4');
    expect(calendar.classes.where((c) => c.dayOfWeek == 6).length, 1);
    calendar.removeClass('class-6');
    expect(calendar.getDaySchedule(DateTime(2026, 11, 12)).activeClasses, isEmpty);
  });

  test('makeup reminders and exported classes use the destination date', () {
    final date = DateTime(2026, 11, 12);
    final reminders = ReminderService(calendar);
    reminders.refreshReminders(referenceDate: date, daysAhead: 0, scheduleNative: false);
    final classes = reminders.notifications.where((n) => n.type == NotificationType.classReminder);
    expect(classes.single.relatedId, 'class-6');
    expect(classes.single.scheduledFor, DateTime(2026, 11, 12, 9, 41));
    final ics = FileParserService.exportCalendarToIcs(calendar, startDate: date, endDate: date);
    expect(ics, contains('UID:CLS-class-6-20261112'));
    expect(ics, contains('DTSTART:20261112T095100'));
    expect(ics, isNot(contains('UID:CLS-class-4-')));
  });

  test('holidays and routine date limits still suppress makeup classes', () {
    final date = DateTime(2026, 11, 12);
    calendar.setRoutineDateRange(startDate: DateTime(2026, 11, 13), endDate: DateTime(2027, 1, 20));
    expect(calendar.getDaySchedule(date).activeClasses, isEmpty);
    calendar.clearRoutineDateRange();
    calendar.addNotice(AcademicNotice(id: 'closure', title: 'Holiday', description: '',
        startDate: date, endDate: date, category: NoticeCategory.holiday, isHoliday: true));
    expect(calendar.getDaySchedule(date).activeClasses, isEmpty);
  });
}
