import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:educal/services/file_parser_service.dart';
import 'package:educal/models/student_profile.dart';
import 'package:educal/models/class_schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Precise .ICS Parsing & Course Timing Tests', () {
    test('Correctly converts UTC timestamp to BST (UTC+6) without scheduling in middle of night', () {
      const icsData = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//UIU//UCAM Routine//EN
BEGIN:VEVENT
UID:class-cse-201-001
SUMMARY:CSE 201: Data Structures
DESCRIPTION:Instructor: Dr. Rahman, Room: 412
LOCATION:Room 412
DTSTART:20261027T030000Z
DTEND:20261027T043000Z
RRULE:FREQ=WEEKLY;BYDAY=SU
END:VEVENT
END:VCALENDAR
''';

      final result = FileParserService.parseClassSchedule(icsData);
      expect(result.isSuccess, isTrue);
      expect(result.items.length, equals(1));

      final cls = result.items.first;
      expect(cls.courseCode, equals('CSE 201'));
      expect(cls.subject, equals('Data Structures'));
      expect(cls.dayOfWeek, equals(7)); // Sunday
      // UTC 03:00 -> 09:00 BST
      expect(cls.startTime, equals('09:00'));
      // UTC 04:30 -> 10:30 BST
      expect(cls.endTime, equals('10:30'));
      expect(cls.room, equals('Room 412'));
      expect(cls.instructor, equals('Dr. Rahman'));
    });

    test('Splits multi-day BYDAY=SU,TU into separate class entries for each weekday', () {
      const icsMultiDay = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:multi-day-algo
SUMMARY:CSE 221 - Algorithms
LOCATION:Room 514
DTSTART:20261027T043000Z
DURATION:PT1H30M
RRULE:FREQ=WEEKLY;BYDAY=SU,TU
END:VEVENT
END:VCALENDAR
''';

      final result = FileParserService.parseClassSchedule(icsMultiDay);
      expect(result.isSuccess, isTrue);
      expect(result.items.length, equals(2));

      final days = result.items.map((c) => c.dayOfWeek).toList();
      expect(days, containsAll([7, 2])); // Sunday (7) and Tuesday (2)

      // 04:30 UTC + 6 hrs = 10:30 BST, + 1.5 hr duration = 12:00
      for (final cls in result.items) {
        expect(cls.startTime, equals('10:30'));
        expect(cls.endTime, equals('12:00'));
        expect(cls.courseCode, equals('CSE 221'));
        expect(cls.subject, equals('Algorithms'));
      }
    });

    test('Unfolds folded lines per RFC 5545 seamlessly', () {
      const icsFolded = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:folded-event
SUMMARY:CSE 411: Software Engineering and Compl
 ex Application Architecture
LOCATION:Room 301
DTSTART:20261027T083000
DTEND:20261027T100000
RRULE:FREQ=WEEKLY;BYDAY=WE
END:VEVENT
END:VCALENDAR
''';

      final result = FileParserService.parseClassSchedule(icsFolded);
      expect(result.isSuccess, isTrue);
      expect(result.items.first.subject, equals('Software Engineering and Complex Application Architecture'));
      expect(result.items.first.dayOfWeek, equals(3)); // Wednesday
      expect(result.items.first.startTime, equals('08:30'));
      expect(result.items.first.endTime, equals('10:00'));
    });
  });

  group('Session Persistence across App Updates with SharedPreferences', () {
    test('Writes and restores student session from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final student = StudentProfile(
        email: 'ahamim2510370@bscse.uiu.ac.bd',
        studentId: '0112510370',
        fullName: 'Asir Hamim',
        department: 'Computer Science & Engineering',
        isSynced: true,
        lastSyncTime: DateTime(2026, 10, 25),
      );

      final classItem = ClassSchedule(
        id: 'CLS-1',
        subject: 'Data Structures',
        courseCode: 'CSE 201',
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '10:30',
        room: '412',
        instructor: 'Dr. Rahman',
      );

      final sessionPayload = jsonEncode({
        'student': student.toJson(),
        'classes': [classItem.toJson()],
        'savedAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString('edutools_session_data', sessionPayload);

      // Verify that after simulated update, reading back from SharedPreferences preserves the session
      final restoredRaw = prefs.getString('edutools_session_data');
      expect(restoredRaw, isNotNull);

      final restoredMap = jsonDecode(restoredRaw!) as Map<String, dynamic>;
      final restoredStudent = StudentProfile.fromJson(restoredMap['student']);
      expect(restoredStudent.email, equals('ahamim2510370@bscse.uiu.ac.bd'));
      expect(restoredStudent.fullName, equals('Asir Hamim'));
      expect(restoredStudent.studentId, equals('0112510370'));

      final classesList = (restoredMap['classes'] as List)
          .map((c) => ClassSchedule.fromJson(Map<String, dynamic>.from(c)))
          .toList();
      expect(classesList.length, equals(1));
      expect(classesList.first.courseCode, equals('CSE 201'));
    });
  });
}
