import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormatGuideDialog extends StatelessWidget {
  final bool isClassRoutine;

  const FormatGuideDialog({super.key, required this.isClassRoutine});

  static const String classIcsSample = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//EduCal//Class Timetable//EN
BEGIN:VEVENT
UID:CLS-201
SUMMARY:CSE-201: Data Structures
DESCRIPTION:Instructor: Dr. Sarah Connor, Room: Lab 402
LOCATION:Lab 402
DTSTART:20260302T090000
DTEND:20260302T103000
RRULE:FREQ=WEEKLY;BYDAY=MO
END:VEVENT
BEGIN:VEVENT
UID:CLS-205
SUMMARY:CSE-205: Database Systems
DESCRIPTION:Instructor: Prof. Alan Turing, Room: Room 301
LOCATION:Room 301
DTSTART:20260302T110000
DTEND:20260302T123000
RRULE:FREQ=WEEKLY;BYDAY=MO
END:VEVENT
END:VCALENDAR''';

  static const String classJsonSample = '''[
  {
    "id": "CS101-MON",
    "subject": "Data Structures & Algorithms",
    "courseCode": "CSE-201",
    "dayOfWeek": 1,
    "startTime": "09:00",
    "endTime": "10:30",
    "room": "Lab 402",
    "instructor": "Dr. Sarah Connor",
    "color": "#4A90E2"
  }
]''';

  static const String classCsvSample = '''id,subject,courseCode,dayOfWeek,startTime,endTime,room,instructor,color
CS101-MON,Data Structures & Algorithms,CSE-201,1,09:00,10:30,Lab 402,Dr. Sarah Connor,#4A90E2''';

  static const String academicIcsSample = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//EduCal//Academic Calendar//EN
BEGIN:VEVENT
UID:HOL-001
SUMMARY:Holiday: Independence Day
DESCRIPTION:Campus closed. All classes suspended.
DTSTART;VALUE=DATE:20260326
DTEND;VALUE=DATE:20260326
CATEGORIES:HOLIDAY
END:VEVENT
BEGIN:VEVENT
UID:FEE-001
SUMMARY:Last Date of 1st Installment
DESCRIPTION:Pay semester installment fee without surcharge.
DTSTART;VALUE=DATE:20260412
DTEND;VALUE=DATE:20260412
CATEGORIES:SEMESTERFEE
END:VEVENT
END:VCALENDAR''';

  static const String academicJsonSample = '''[
  {
    "id": "HOL-001",
    "title": "Holiday: Independence Day",
    "description": "Campus closed. Classes suspended.",
    "startDate": "2026-03-26",
    "endDate": "2026-03-26",
    "category": "holiday",
    "isHoliday": true,
    "priority": "high"
  }
]''';

  static const String academicCsvSample = '''id,title,description,startDate,endDate,category,isHoliday,priority
HOL-001,Holiday: Independence Day,Campus closed. Classes suspended.,2026-03-26,2026-03-26,holiday,true,high''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icsContent = isClassRoutine ? classIcsSample : academicIcsSample;
    final jsonContent = isClassRoutine ? classJsonSample : academicJsonSample;
    final csvContent = isClassRoutine ? classCsvSample : academicCsvSample;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isClassRoutine ? 'Class Routine Format Guide' : 'Academic Calendar Format Guide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'EduCal supports standard .ics (iCalendar), JSON, and CSV formats. Holidays automatically suppress classes.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // .ICS Format
              _buildCodeBlock(
                title: '📅 .ICS (iCalendar Standard)',
                code: icsContent,
                context: context,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // JSON format
              _buildCodeBlock(
                title: '📋 JSON Array Format',
                code: jsonContent,
                context: context,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // CSV format
              _buildCodeBlock(
                title: '📊 CSV Spreadsheet Format',
                code: csvContent,
                context: context,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBlock({
    required String title,
    required String code,
    required BuildContext context,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied template to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Copy', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
