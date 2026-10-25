import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/services/calendar_service.dart';
import 'package:educal/services/sample_data_service.dart';
import 'package:educal/state/calendar_state.dart';
import 'package:educal/screens/setup/routine_date_config_dialog.dart';

void main() {
  group('Routine Lifecycle & Auto-Figure Tests', () {
    late CalendarService calendarService;

    setUp(() {
      calendarService = CalendarService();
      calendarService.setNotices(SampleDataService.getOfficialAcademicCalendar());
      calendarService.setClasses(SampleDataService.getSampleClasses());
    });

    test('Auto-figure routine dates when reference date is AFTER classes are suspended', () {
      // Classes will remain suspended from 2026-10-07.
      // Reference date is 2026-10-15 (after suspension).
      final postSuspensionDate = DateTime(2026, 10, 15);
      final range = calendarService.autoFigureRoutineDates(referenceDate: postSuspensionDate);

      expect(range.isCurrentDatePastSuspension, isTrue);
      // Summer classes begin on 2026-07-07
      expect(range.startDate, equals(DateTime(2026, 7, 7)));
      // Classes suspended on 2026-10-07 -> Routine ends on 2026-10-06 (day before)
      expect(range.endDate, equals(DateTime(2026, 10, 6)));
      expect(range.classesSuspendedDate, equals(DateTime(2026, 10, 7)));
      expect(range.isAutoFigured, isTrue);
    });

    test('Auto-figure routine dates when reference date is DURING active trimester', () {
      // In mid-August 2026 (during classes)
      final midSemesterDate = DateTime(2026, 8, 20);
      final range = calendarService.autoFigureRoutineDates(referenceDate: midSemesterDate);

      expect(range.isCurrentDatePastSuspension, isFalse);
      expect(range.startDate, equals(DateTime(2026, 7, 7)));
      expect(range.endDate, equals(DateTime(2026, 10, 6)));
      expect(range.isAutoFigured, isTrue);
    });

    test('Classes are active during routine dates and automatically ended after routine ends', () {
      // Auto-apply routine dates: 2026-07-07 to 2026-10-06
      final range = calendarService.autoFigureRoutineDates(referenceDate: DateTime(2026, 8, 1));
      calendarService.setRoutineDateRange(
        startDate: range.startDate,
        endDate: range.endDate,
        isAutoFigured: true,
      );

      // Tuesday during active routine: 2026-08-11
      final tuesdayActive = DateTime(2026, 8, 11);
      final activeSchedule = calendarService.getDaySchedule(tuesdayActive);
      expect(activeSchedule.isOutsideRoutineRange, isFalse);
      expect(activeSchedule.scheduledClasses.isNotEmpty, isTrue);

      // Tuesday after classes are suspended: 2026-10-13 (during Final Exams)
      final tuesdaySuspended = DateTime(2026, 10, 13);
      final suspendedSchedule = calendarService.getDaySchedule(tuesdaySuspended);
      expect(suspendedSchedule.isOutsideRoutineRange, isTrue);
      expect(suspendedSchedule.isAfterRoutineEnd, isTrue);
      // Scheduled classes are suppressed after routine ends
      expect(suspendedSchedule.scheduledClasses.isEmpty, isTrue);
      expect(suspendedSchedule.activeClasses.isEmpty, isTrue);
    });

    test('Semester break between final exam end and next trimester begin is recognized as official holiday', () {
      // Summer 2026 Final Exams: 2026-10-10 to 2026-10-17
      // Fall 2026 Trimester Begins: 2026-10-27
      // Dates 2026-10-18 to 2026-10-26 are Semester Break
      final breakDate = DateTime(2026, 10, 19); // Monday
      expect(calendarService.isSemesterBreak(breakDate), isTrue);
      expect(calendarService.isHoliday(breakDate), isTrue);

      final schedule = calendarService.getDaySchedule(breakDate);
      expect(schedule.isHoliday, isTrue);
      expect(schedule.holidayNotices.any((n) => n.title.contains('Semester Break')), isTrue);
      expect(schedule.activeClasses.isEmpty, isTrue);
    });

    test('User can customize and override routine active dates manually', () {
      final customStart = DateTime(2026, 7, 1);
      final customEnd = DateTime(2026, 9, 30);

      calendarService.setRoutineDateRange(
        startDate: customStart,
        endDate: customEnd,
        isAutoFigured: false,
        sourceDescription: 'Custom dates for shortened term',
      );

      expect(calendarService.isRoutineAutoFigured, isFalse);
      expect(calendarService.routineStartDate, equals(customStart));
      expect(calendarService.routineEndDate, equals(customEnd));

      // 2026-10-02 is now after the custom routine ending
      final oct2 = DateTime(2026, 10, 2);
      final schedule = calendarService.getDaySchedule(oct2);
      expect(schedule.isAfterRoutineEnd, isTrue);
      expect(schedule.scheduledClasses.isEmpty, isTrue);
    });
  });

  group('RoutineDateConfigDialog Widget Tests', () {
    testWidgets('Renders detected dates and allows applying auto-figured window', (tester) async {
      final state = CalendarState();
      state.loadSampleData(notify: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (_) => RoutineDateConfigDialog(
                      state: state,
                      isAfterUpload: true,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Routine Schedule Window'), findsOneWidget);
      expect(find.text('Use Auto-Figured Dates'), findsOneWidget);
      expect(find.text('Edit Dates Manually'), findsOneWidget);

      // Tap 'Use Auto-Figured Dates'
      await tester.tap(find.text('Use Auto-Figured Dates'));
      await tester.pumpAndSettle();

      expect(find.text('Routine Schedule Window'), findsNothing);
      expect(state.routineRange, isNotNull);
      expect(state.isRoutineAutoFigured, isTrue);
    });
  });
}
