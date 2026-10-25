import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/models/class_schedule.dart';
import 'package:educal/models/academic_notice.dart';
import 'package:educal/models/reminder_notification.dart';
import 'package:educal/services/calendar_service.dart';
import 'package:educal/services/reminder_service.dart';

void main() {
  group('CalendarService & Holiday Conflict Resolution Tests', () {
    late CalendarService calendarService;
    late ReminderService reminderService;

    setUp(() {
      calendarService = CalendarService();
      reminderService = ReminderService(calendarService);

      // Add a recurring Monday class (dayOfWeek = 1, 09:00 - 10:30)
      calendarService.addClass(ClassSchedule(
        id: 'CS101-MON',
        subject: 'Data Structures',
        courseCode: 'CSE-201',
        dayOfWeek: 1, // Monday
        startTime: '09:00',
        endTime: '10:30',
        room: 'Lab 402',
        instructor: 'Dr. Sarah Connor',
      ));

      // Add a recurring Tuesday class (dayOfWeek = 2, 10:00 - 11:30)
      calendarService.addClass(ClassSchedule(
        id: 'CS103-TUE',
        subject: 'Operating Systems',
        courseCode: 'CSE-301',
        dayOfWeek: 2, // Tuesday
        startTime: '10:00',
        endTime: '11:30',
        room: 'Room 204',
        instructor: 'Dr. Linus Torvalds',
      ));
    });

    test('Regular day has active classes and is NOT a holiday', () {
      final monday = DateTime(2026, 8, 24);
      expect(monday.weekday, equals(1));

      final schedule = calendarService.getDaySchedule(monday);
      expect(schedule.isHoliday, isFalse);
      expect(schedule.scheduledClasses.length, equals(1));
      expect(schedule.activeClasses.length, equals(1));
      expect(schedule.classesCancelledDueToHoliday, isFalse);
      expect(schedule.activeClasses.first.subject, equals('Data Structures'));
    });

    test('Holiday on a class day cancels classes and marks day as Holiday', () {
      final monday = DateTime(2026, 8, 24);
      calendarService.addNotice(AcademicNotice(
        id: 'HOL-001',
        title: 'National Holiday',
        description: 'University closed',
        startDate: monday,
        endDate: monday,
        category: NoticeCategory.holiday,
        isHoliday: true,
      ));

      final schedule = calendarService.getDaySchedule(monday);
      expect(schedule.isHoliday, isTrue);
      expect(schedule.holidayNotices.length, equals(1));
      expect(schedule.holidayNotices.first.title, equals('National Holiday'));

      // Crucial requirement: holidays do not have class
      expect(schedule.scheduledClasses.length, equals(1));
      expect(schedule.activeClasses.isEmpty, isTrue);
      expect(schedule.classesCancelledDueToHoliday, isTrue);
    });

    test('Default reminder timings: Holiday at 8 AM, Class 10m before, Normal event day before at 10 PM', () {
      final monday = DateTime(2026, 8, 24);
      final tuesday = DateTime(2026, 8, 25);

      // Add a fee deadline on Tuesday
      calendarService.addNotice(AcademicNotice(
        id: 'FEE-001',
        title: 'Last Date of 1st Installment',
        description: 'Pay fees without surcharge',
        startDate: tuesday,
        endDate: tuesday,
        category: NoticeCategory.semesterFee,
      ));

      reminderService.refreshReminders(referenceDate: monday, daysAhead: 1);

      // Class reminder on Monday (09:00 -> 08:50)
      final classReminders = reminderService.notifications
          .where((n) => n.type == NotificationType.classReminder && !n.isMutedDueToHoliday)
          .toList();
      final monClass = classReminders.firstWhere((n) => n.scheduledFor.day == 24);
      expect(monClass.scheduledFor.hour, equals(8));
      expect(monClass.scheduledFor.minute, equals(50)); // 10 mins before 09:00

      // Normal event reminder for Tuesday's fee deadline: Day before (Monday) at 10:00 PM (22:00)
      final feeReminders = reminderService.notifications
          .where((n) => n.type == NotificationType.feeReminder)
          .toList();
      expect(feeReminders.length, equals(1));
      expect(feeReminders.first.scheduledFor.day, equals(24)); // Monday
      expect(feeReminders.first.scheduledFor.hour, equals(22)); // 10:00 PM
      expect(feeReminders.first.scheduledFor.minute, equals(0));
    });

    test('Customizing reminder for a single course only vs all courses', () {
      final monday = DateTime(2026, 8, 24);

      // Customize only Monday class (CSE-201) to 20 minutes before, while Tuesday (CSE-301) stays default (10m)
      final monCls = calendarService.classes.firstWhere((c) => c.courseCode == 'CSE-201');
      calendarService.updateClass(monCls.copyWith(customReminderMinutes: 20));

      reminderService.refreshReminders(referenceDate: monday, daysAhead: 1);

      final classReminders = reminderService.notifications
          .where((n) => n.type == NotificationType.classReminder && !n.isMutedDueToHoliday)
          .toList();

      final monReminder = classReminders.firstWhere((n) => n.scheduledFor.day == 24);
      expect(monReminder.scheduledFor.hour, equals(8));
      expect(monReminder.scheduledFor.minute, equals(40)); // 20 mins before 09:00

      final tueReminder = classReminders.firstWhere((n) => n.scheduledFor.day == 25);
      expect(tueReminder.scheduledFor.hour, equals(9));
      expect(tueReminder.scheduledFor.minute, equals(50)); // Default 10 mins before 10:00
    });

    test('Customizing reminder for a single holiday only vs all holidays', () {
      final monday = DateTime(2026, 8, 24);

      // Add a holiday with a custom reminder time (e.g. 09:15 AM)
      calendarService.addNotice(AcademicNotice(
        id: 'HOL-CUSTOM',
        title: 'Special Holiday',
        description: 'University closed',
        startDate: monday,
        endDate: monday,
        category: NoticeCategory.holiday,
        isHoliday: true,
        customReminderTime: const TimeOfDay(hour: 9, minute: 15),
      ));

      reminderService.refreshReminders(referenceDate: monday, daysAhead: 0);

      final holReminders = reminderService.notifications
          .where((n) => n.type == NotificationType.holidayAlert)
          .toList();

      expect(holReminders.length, equals(1));
      expect(holReminders.first.scheduledFor.hour, equals(9));
      expect(holReminders.first.scheduledFor.minute, equals(15));
    });
  });
}
