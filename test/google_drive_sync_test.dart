import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/models/class_schedule.dart';
import 'package:educal/models/academic_notice.dart';
import 'package:educal/models/reminder_settings.dart';
import 'package:educal/models/student_profile.dart';
import 'package:educal/models/routine_date_range.dart';
import 'package:educal/services/google_drive_sync_service.dart';
import 'package:educal/state/calendar_state.dart';
import 'package:educal/screens/main_screen.dart';

void main() {
  group('Google Drive Cloud Sync Unit & Widget Tests', () {
    test('GoogleDriveSyncService builds comprehensive educal_sync_data.json payload', () {
      final student = StudentProfile(
        email: 'student@uiu.ac.bd',
        studentId: '011221001',
        fullName: 'Alex Chen',
        department: 'Computer Science & Engineering',
      );

      final classes = [
        ClassSchedule(
          id: 'CLS-1',
          courseCode: 'CSE-201',
          subject: 'Data Structures',
          dayOfWeek: 1,
          startTime: '09:00',
          endTime: '10:30',
          room: 'Lab 402',
          instructor: 'Dr. Sarah Connor',
        ),
      ];

      final notices = [
        AcademicNotice(
          id: 'NOT-1',
          title: 'Classes Begin',
          description: 'Semester begins',
          startDate: DateTime(2026, 7, 7),
          endDate: DateTime(2026, 7, 7),
          category: NoticeCategory.event,
        ),
      ];

      final routineRange = RoutineDateRange(
        startDate: DateTime(2026, 7, 7),
        endDate: DateTime(2026, 10, 6),
        sourceDescription: 'Auto-figured Summer 2026',
        isAutoFigured: true,
      );

      const settings = ReminderSettings();

      final payload = GoogleDriveSyncService.buildSyncPayload(
        student: student,
        classes: classes,
        notices: notices,
        routineRange: routineRange,
        settings: settings,
      );

      expect(payload['app'], equals('EduCal'));
      expect(payload['student']['email'], equals('student@uiu.ac.bd'));
      expect((payload['classes'] as List).length, equals(1));
      expect((payload['notices'] as List).length, equals(1));
      expect(payload['routineRange']['startDate'], equals('2026-07-07'));
      expect(payload['routineRange']['endDate'], equals('2026-10-06'));
      expect(payload['settings']['classMinutes'], equals(10));
    });

    test('RoutineDateRange JSON serialization roundtrip', () {
      final original = RoutineDateRange(
        startDate: DateTime(2026, 7, 7),
        endDate: DateTime(2026, 10, 6),
        title: 'Summer 2026 Routine',
        sourceDescription: 'Auto-figured',
        isAutoFigured: true,
        isCurrentDatePastSuspension: true,
        classesSuspendedDate: DateTime(2026, 10, 7),
        finalExamDate: DateTime(2026, 10, 10),
        nextSemesterBeginDate: DateTime(2026, 10, 27),
      );

      final json = original.toJson();
      final recovered = RoutineDateRange.fromJson(json);

      expect(recovered.startDate, equals(DateTime(2026, 7, 7)));
      expect(recovered.endDate, equals(DateTime(2026, 10, 6)));
      expect(recovered.title, equals('Summer 2026 Routine'));
      expect(recovered.isAutoFigured, isTrue);
      expect(recovered.isCurrentDatePastSuspension, isTrue);
      expect(recovered.classesSuspendedDate, equals(DateTime(2026, 10, 7)));
      expect(recovered.finalExamDate, equals(DateTime(2026, 10, 10)));
      expect(recovered.nextSemesterBeginDate, equals(DateTime(2026, 10, 27)));
    });

    test('CalendarState logs in student and executes syncWithGoogleDrive()', () async {
      final state = CalendarState();
      state.logoutStudent();
      expect(state.isLoggedIn, isFalse);

      state.loginStudent(
        email: 'student@uiu.ac.bd',
        studentId: '011221001',
        fullName: 'Alex Chen',
      );

      expect(state.isLoggedIn, isTrue);
      expect(state.currentStudent!.email, equals('student@uiu.ac.bd'));
      expect(state.currentStudent!.avatarLetter, equals('A'));

      final success = await state.syncWithGoogleDrive();
      expect(success, isTrue);
      expect(state.isSyncing, isFalse);
    });

    testWidgets('MainScreen renders University Login button when logged out and avatar when logged in', (tester) async {
      final state = CalendarState();
      state.logoutStudent();

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(state: state),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Login button
      expect(find.text('Login'), findsOneWidget);

      // Now log in student
      state.loginStudent(
        email: 'student@uiu.ac.bd',
        studentId: '011221001',
        fullName: 'Alex Chen',
      );
      await tester.pumpAndSettle();

      // Login button replaced by avatar letter 'A'
      expect(find.text('Login'), findsNothing);
      expect(find.text('A'), findsOneWidget);
    });
  });
}
