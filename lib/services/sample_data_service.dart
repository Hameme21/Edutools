import '../models/class_schedule.dart';
import '../models/academic_notice.dart';

class SampleDataService {
  static List<ClassSchedule> getSampleClasses() {
    return [
      ClassSchedule(
        id: 'CS101-SAT',
        subject: 'Data Structures & Algorithms',
        courseCode: 'CSE-201',
        dayOfWeek: 6, // Saturday
        startTime: '09:00',
        endTime: '10:30',
        room: 'Lab 402',
        instructor: 'Dr. Sarah Connor',
        colorHex: '#2563EB',
      ),
      ClassSchedule(
        id: 'CS102-SAT',
        subject: 'Database Management Systems',
        courseCode: 'CSE-205',
        dayOfWeek: 6, // Saturday
        startTime: '11:00',
        endTime: '12:30',
        room: 'Room 301',
        instructor: 'Prof. Alan Turing',
        colorHex: '#059669',
      ),
      ClassSchedule(
        id: 'CS103-SUN',
        subject: 'Operating Systems',
        courseCode: 'CSE-301',
        dayOfWeek: 7, // Sunday
        startTime: '10:00',
        endTime: '11:30',
        room: 'Room 204',
        instructor: 'Dr. Linus Torvalds',
        colorHex: '#7C3AED',
      ),
      ClassSchedule(
        id: 'CS104-SUN',
        subject: 'Computer Networks',
        courseCode: 'CSE-305',
        dayOfWeek: 7, // Sunday
        startTime: '13:30',
        endTime: '15:00',
        room: 'Lab 102',
        instructor: 'Dr. Vint Cerf',
        colorHex: '#D97706',
      ),
      ClassSchedule(
        id: 'CS105-TUE',
        subject: 'Software Engineering & Architecture',
        courseCode: 'CSE-309',
        dayOfWeek: 2, // Tuesday
        startTime: '09:00',
        endTime: '10:30',
        room: 'Room 305',
        instructor: 'Prof. Margaret Hamilton',
        colorHex: '#DB2777',
      ),
      ClassSchedule(
        id: 'CS106-TUE',
        subject: 'Artificial Intelligence',
        courseCode: 'CSE-401',
        dayOfWeek: 2, // Tuesday
        startTime: '11:00',
        endTime: '12:30',
        room: 'Auditorium B',
        instructor: 'Dr. Geoffrey Hinton',
        colorHex: '#0891B2',
      ),
      ClassSchedule(
        id: 'CS107-WED',
        subject: 'Data Structures Lab',
        courseCode: 'CSE-202',
        dayOfWeek: 3, // Wednesday
        startTime: '09:00',
        endTime: '11:30',
        room: 'Lab 402',
        instructor: 'Dr. Sarah Connor',
        colorHex: '#2563EB',
      ),
      ClassSchedule(
        id: 'CS108-WED',
        subject: 'Web Application Development',
        courseCode: 'CSE-315',
        dayOfWeek: 3, // Wednesday
        startTime: '13:00',
        endTime: '15:00',
        room: 'Web Lab 202',
        instructor: 'Prof. Tim Berners-Lee',
        colorHex: '#16A34A',
      ),
    ];
  }

  /// Official Full University Academic Calendar 2026
  static List<AcademicNotice> getOfficialAcademicCalendar() {
    final rawData = [
      { "start": "2026-02-23", "end": "2026-02-25", "title": "Registration without Fine", "type": "regular" },
      { "start": "2026-02-28", "end": "2026-02-28", "title": "Spring 2026 classes Begin", "type": "regular" },
      { "start": "2026-03-02", "end": "2026-03-02", "title": "Drop course (100% refund)", "type": "regular" },
      { "start": "2026-03-07", "end": "2026-03-07", "title": "Apply Grade Change (Fall '25)", "type": "regular" },
      { "start": "2026-03-09", "end": "2026-03-09", "title": "Drop course (50% refund)", "type": "regular" },
      { "start": "2026-03-10", "end": "2026-03-10", "title": "Grade Submission for incomplete Grades", "type": "regular" },
      { "start": "2026-03-15", "end": "2026-03-15", "title": "Registration (500Tk Fine)", "type": "regular" },
      { "start": "2026-03-26", "end": "2026-03-26", "title": "Independence Day", "type": "holiday" },
      { "start": "2026-04-12", "end": "2026-04-12", "title": "Last Date of 1st Installment", "type": "regular" },
      { "start": "2026-04-13", "end": "2026-04-13", "title": "Make-up class (Tue Classes)", "type": "regular" },
      { "start": "2026-04-14", "end": "2026-04-14", "title": "Holiday: Bangla New Year", "type": "holiday" },
      { "start": "2026-04-18", "end": "2026-04-24", "title": "Mid-Term Exams", "type": "exam" },
      { "start": "2026-04-25", "end": "2026-04-25", "title": "Regular class (Tue Classes)", "type": "regular" },
      { "start": "2026-04-26", "end": "2026-04-26", "title": "Regular class (Wed Classes)", "type": "regular" },
      { "start": "2026-05-04", "end": "2026-05-04", "title": "Last day of Course Withdrawal", "type": "regular" },
      { "start": "2026-05-12", "end": "2026-05-12", "title": "2nd Installment Deadline", "type": "regular" },
      { "start": "2026-05-26", "end": "2026-06-05", "title": "Holiday: Eid-ul-Adha", "type": "holiday" },
      { "start": "2026-06-14", "end": "2026-06-14", "title": "3rd Installment Deadline", "type": "regular" },
      { "start": "2026-06-18", "end": "2026-06-20", "title": "Exam Prep (No Classes)", "type": "regular" },
      { "start": "2026-06-21", "end": "2026-06-25", "title": "Final Exams", "type": "exam" },
      { "start": "2026-06-26", "end": "2026-06-26", "title": "Ashura", "type": "holiday" },
      { "start": "2026-06-27", "end": "2026-06-28", "title": "Final Exams", "type": "exam" },
      { "start": "2026-07-07", "end": "2026-07-07", "title": "Summer 2026 Begins", "type": "regular" },
      { "start": "2026-07-04", "end": "2026-07-06", "title": "Course Advising & Registration", "type": "regular" },
      { "start": "2026-07-06", "end": "2026-07-06", "title": "Last day of Course Advising & Registration without Fine", "type": "regular" },
      { "start": "2026-07-06", "end": "2026-07-06", "title": "Open Day Orientation", "type": "regular" },
      { "start": "2026-07-07", "end": "2026-07-07", "title": "Classes Begin", "type": "regular" },
      { "start": "2026-07-11", "end": "2026-07-11", "title": "Last day to drop course(s) with 100% adjustable refund", "type": "regular" },
      { "start": "2026-07-15", "end": "2026-07-15", "title": "Last day to apply for Grade Change (Spring 2026)", "type": "regular" },
      { "start": "2026-07-19", "end": "2026-07-19", "title": "Last day of Grade Submission for Project/Thesis/Internship", "type": "regular" },
      { "start": "2026-07-20", "end": "2026-07-20", "title": "Last day to drop course(s) with 50% adjustable refund", "type": "regular" },
      { "start": "2026-07-20", "end": "2026-07-20", "title": "Last day of Course Advising & Registration with Fine (Tk. 500)", "type": "regular" },
      { "start": "2026-07-20", "end": "2026-07-20", "title": "Last day of Grade Submission of Incomplete Grades (Spring 2026)", "type": "regular" },
      { "start": "2026-08-05", "end": "2026-08-05", "title": "Holiday: July Mass Uprising Day", "type": "holiday" },
      { "start": "2026-08-11", "end": "2026-08-11", "title": "Last date of 1st Installment", "type": "regular" },
      { "start": "2026-08-18", "end": "2026-08-18", "title": "Regular Saturday Classes", "type": "regular" },
      { "start": "2026-08-22", "end": "2026-08-25", "title": "Mid-Term Exam", "type": "exam" },
      { "start": "2026-08-26", "end": "2026-08-26", "title": "Holiday: Eid-e-Miladunnabi", "type": "holiday" },
      { "start": "2026-08-27", "end": "2026-08-29", "title": "Mid-Term Exam", "type": "exam" },
      { "start": "2026-09-04", "end": "2026-09-04", "title": "Holiday: Janmashtami", "type": "holiday" },
      { "start": "2026-09-09", "end": "2026-09-09", "title": "Last Day of Course Withdrawal", "type": "regular" },
      { "start": "2026-09-14", "end": "2026-09-14", "title": "Last date of 2nd Installment", "type": "regular" },
      { "start": "2026-09-24", "end": "2026-09-24", "title": "Regular Wednesday Classes", "type": "regular" },
      { "start": "2026-10-06", "end": "2026-10-06", "title": "Last date of 3rd Installment", "type": "regular" },
      { "start": "2026-10-07", "end": "2026-10-09", "title": "Classes will remain suspended", "type": "regular" },
      { "start": "2026-10-10", "end": "2026-10-17", "title": "Final Exam", "type": "exam" },
      { "start": "2026-10-20", "end": "2026-10-21", "title": "Holiday: Durga Puja", "type": "holiday" },
      { "start": "2026-10-22", "end": "2026-10-22", "title": "Last day of Grade Submission (Including Self-Study courses)", "type": "regular" },
      { "start": "2026-10-27", "end": "2026-10-27", "title": "Fall 2026 Trimester Begins", "type": "regular" },
      { "start": "2026-10-24", "end": "2026-10-26", "title": "Course Advising and Registration", "type": "regular" },
      { "start": "2026-10-26", "end": "2026-10-26", "title": "Last day of Course Advising and Registration without Fine", "type": "regular" },
      { "start": "2026-10-26", "end": "2026-10-26", "title": "Open Day Orientation", "type": "regular" },
      { "start": "2026-10-27", "end": "2026-10-27", "title": "Classes Begin", "type": "regular" },
      { "start": "2026-10-31", "end": "2026-10-31", "title": "Last day to drop course(s) with 100% adjustable refund", "type": "regular" },
      { "start": "2026-11-04", "end": "2026-11-04", "title": "Last day to apply for Grade Change (Summer 2026)", "type": "regular" },
      { "start": "2026-11-05", "end": "2026-11-05", "title": "Regular Saturday Class (online)", "type": "regular" },
      { "start": "2026-11-07", "end": "2026-11-07", "title": "Holiday: National Revolution and Solidarity Day", "type": "holiday" },
      { "start": "2026-11-08", "end": "2026-11-08", "title": "Last day of Grade Submission for Project/Thesis/Internship", "type": "regular" },
      { "start": "2026-11-09", "end": "2026-11-09", "title": "Last day to drop course(s) with 50% adjustable refund only", "type": "regular" },
      { "start": "2026-11-09", "end": "2026-11-09", "title": "Last day of Course Advising and Registration with a Fine of Tk. 500/-", "type": "regular" },
      { "start": "2026-11-09", "end": "2026-11-09", "title": "Last day of Grade Submission of Incomplete Grades of Summer 2026", "type": "regular" },
      { "start": "2026-11-12", "end": "2026-11-12", "title": "Regular Saturday Class (online)", "type": "regular" },
      { "start": "2026-11-22", "end": "2026-11-22", "title": "Last date of 1st Installment", "type": "regular" },
      { "start": "2026-11-26", "end": "2026-11-26", "title": "Regular Sunday Class (online)", "type": "regular" },
      { "start": "2026-12-05", "end": "2026-12-12", "title": "Mid-Term Exam", "type": "exam" },
      { "start": "2026-12-15", "end": "2026-12-15", "title": "Last date of 2nd Installment", "type": "regular" },
      { "start": "2026-12-16", "end": "2026-12-16", "title": "Holiday: Victory Day", "type": "holiday" },
      { "start": "2026-12-17", "end": "2026-12-17", "title": "Regular Wednesday Class (online)", "type": "regular" },
      { "start": "2026-12-23", "end": "2026-12-23", "title": "Last Day of Course Withdrawal", "type": "regular" },
      { "start": "2026-12-25", "end": "2026-12-25", "title": "Holiday: Christmas Day", "type": "holiday" },
      { "start": "2026-12-31", "end": "2026-12-31", "title": "Regular Saturday Class (online)", "type": "regular" },
      { "start": "2027-01-13", "end": "2027-01-13", "title": "Last date of 3rd Installment", "type": "regular" },
      { "start": "2027-01-21", "end": "2027-01-24", "title": "Classes will remain suspended", "type": "regular" },
      { "start": "2027-01-24", "end": "2027-01-24", "title": "Holiday: Shab-e-Barat", "type": "holiday" },
      { "start": "2027-01-25", "end": "2027-02-01", "title": "Final Exam", "type": "exam" },
      { "start": "2027-02-04", "end": "2027-02-04", "title": "Last day of Grade Submission (including Self-Study courses)", "type": "regular" },

    ];

    final List<AcademicNotice> notices = [];

    for (int i = 0; i < rawData.length; i++) {
      final item = rawData[i];
      final title = item['title'] as String;
      final type = item['type'] as String;
      final start = DateTime.parse(item['start'] as String);
      final end = DateTime.parse(item['end'] as String);

      final lowerTitle = title.toLowerCase();
      final isHoliday = type == 'holiday' || lowerTitle.contains('holiday');
      final isExam = type == 'exam' || lowerTitle.contains('exam');
      final isAdmin = lowerTitle.contains('registration') ||
          lowerTitle.contains('advising') ||
          lowerTitle.contains('withdrawal') ||
          lowerTitle.contains('evaluation') ||
          lowerTitle.contains('drop') ||
          lowerTitle.contains('grade');
      final isFee = lowerTitle.contains('installment') ||
          lowerTitle.contains('semester fee') ||
          (lowerTitle.contains('fee') && !lowerTitle.contains('drop'));

      NoticeCategory category;
      if (isHoliday) {
        category = NoticeCategory.holiday;
      } else if (isExam) {
        category = NoticeCategory.exam;
      } else if (isAdmin) {
        category = NoticeCategory.administrative;
      } else if (isFee) {
        category = NoticeCategory.semesterFee;
      } else {
        category = NoticeCategory.event;
      }

      NoticePriority priority;
      if (isHoliday || isFee || isExam) {
        priority = NoticePriority.urgent;
      } else if (isAdmin) {
        priority = NoticePriority.high;
      } else {
        priority = NoticePriority.medium;
      }

      notices.add(AcademicNotice(
        id: 'ACAD-2026-${(i + 1).toString().padLeft(3, '0')}',
        title: title,
        description: _generateDescription(title, type),
        startDate: start,
        endDate: end,
        category: category,
        isHoliday: isHoliday,
        priority: priority,
        reminderEnabled: true,
      ));
    }

    return notices;
  }

  static String _generateDescription(String title, String type) {
    if (type == 'holiday') {
      return 'Official university holiday. Campus closed and all classes are suspended.';
    } else if (type == 'exam') {
      return 'Official examination session. Check student portal for detailed seat plan.';
    } else if (title.toLowerCase().contains('installment')) {
      return 'Pay semester installment fees before due date to avoid penalty surcharges.';
    } else if (title.toLowerCase().contains('registration')) {
      return 'Complete course advising & registration through university portal.';
    } else if (title.toLowerCase().contains('drop')) {
      return 'Deadline for course adjustments and fee refund eligibility.';
    } else if (title.toLowerCase().contains('suspended')) {
      return 'Classes suspended for exam preparation.';
    }
    return 'Official university academic calendar notice.';
  }

  static List<AcademicNotice> getSampleNotices() {
    return getOfficialAcademicCalendar();
  }
}
