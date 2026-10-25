import 'package:flutter_test/flutter_test.dart';
import 'package:educal/services/sample_data_service.dart';
import 'package:educal/services/file_parser_service.dart';
import 'package:educal/models/academic_notice.dart';

void main() {
  group('Notice Categorization and .ICS Separation Tests', () {
    test('Academic Calendar has Fall 2026 and Spring 2027 notices with correct categories', () {
      final notices = SampleDataService.getOfficialAcademicCalendar();
      expect(notices.length, greaterThanOrEqualTo(45));

      // Test specific items
      final advising = notices.firstWhere((n) => n.title.contains('Course Advising and Registration'));
      expect(advising.category, equals(NoticeCategory.administrative));

      final advisingFine = notices.firstWhere((n) => n.title.contains('Registration with a Fine'));
      expect(advisingFine.category, equals(NoticeCategory.administrative));

      final orientation = notices.firstWhere((n) => n.title.contains('Open Day Orientation'));
      expect(orientation.category, equals(NoticeCategory.event));

      final classesBegin = notices.firstWhere((n) => n.title.contains('Classes Begin'));
      expect(classesBegin.category, equals(NoticeCategory.event));

      final holiday = notices.firstWhere((n) => n.title.contains('Holiday: Victory Day'));
      expect(holiday.category, equals(NoticeCategory.holiday));

      final fee1 = notices.firstWhere((n) => n.title.contains('1st Installment'));
      expect(fee1.category, equals(NoticeCategory.semesterFee));

      final fee2 = notices.firstWhere((n) => n.title.contains('2nd Installment'));
      expect(fee2.category, equals(NoticeCategory.semesterFee));

      final fee3 = notices.firstWhere((n) => n.title.contains('3rd Installment'));
      expect(fee3.category, equals(NoticeCategory.semesterFee));

      final withdrawal = notices.firstWhere((n) => n.title.contains('Course Withdrawal'));
      expect(withdrawal.category, equals(NoticeCategory.administrative));
    });

    test('ICS file containing class schedule only parses to classes, not notices', () {
      const classIcs = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Edutools//Routine//EN
BEGIN:VEVENT
UID:CLS-CSE201-1
SUMMARY:CSE-201: Data Structures
DESCRIPTION:Instructor: Dr. Sarah Connor
LOCATION:Lab 402
DTSTART:20261027T090000
DTEND:20261027T103000
RRULE:FREQ=WEEKLY;BYDAY=TU
END:VEVENT
END:VCALENDAR''';

      final classResult = FileParserService.parseClassSchedule(classIcs);
      expect(classResult.isSuccess, isTrue);
      expect(classResult.items.length, equals(1));
      expect(classResult.items.first.courseCode, equals('CSE-201'));

      final noticeResult = FileParserService.parseAcademicCalendar(classIcs);
      // The class must NOT be parsed as an Academic Notice / Event!
      expect(noticeResult.isSuccess, isFalse);
      expect(noticeResult.items, isEmpty);
    });

    test('ICS file containing academic milestones only parses to notices, not classes', () {
      const noticeIcs = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Edutools//Calendar//EN
BEGIN:VEVENT
UID:NOT-HOL-1
SUMMARY:Holiday: Victory Day
DESCRIPTION:Official university holiday.
DTSTART;VALUE=DATE:20261216
DTEND;VALUE=DATE:20261216
CATEGORIES:HOLIDAY
END:VEVENT
BEGIN:VEVENT
UID:NOT-FEE-1
SUMMARY:Last date of 2nd Installment
DESCRIPTION:Pay semester tuition.
DTSTART;VALUE=DATE:20261215
DTEND;VALUE=DATE:20261215
CATEGORIES:SEMESTERFEE
END:VEVENT
END:VCALENDAR''';

      final noticeResult = FileParserService.parseAcademicCalendar(noticeIcs);
      expect(noticeResult.isSuccess, isTrue);
      expect(noticeResult.items.length, equals(2));
      expect(noticeResult.items[0].category, equals(NoticeCategory.holiday));
      expect(noticeResult.items[1].category, equals(NoticeCategory.semesterFee));

      final classResult = FileParserService.parseClassSchedule(noticeIcs);
      // Milestones must NOT be parsed as class routines!
      expect(classResult.isSuccess, isFalse);
      expect(classResult.items, isEmpty);
    });
  });
}
