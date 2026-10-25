import 'dart:convert';
import '../models/class_schedule.dart';
import '../models/academic_notice.dart';
import 'calendar_service.dart';

class ParseResult<T> {
  final bool isSuccess;
  final List<T> items;
  final String? errorMessage;

  ParseResult.success(this.items)
      : isSuccess = true,
        errorMessage = null;

  ParseResult.failure(this.errorMessage)
      : isSuccess = false,
        items = const [];
}

class FileParserService {
  /// Parses class routine from JSON, CSV, or .ics iCalendar raw string
  static ParseResult<ClassSchedule> parseClassSchedule(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return ParseResult.failure('Content is empty.');
    }

    if (trimmed.toUpperCase().contains('BEGIN:VCALENDAR') || trimmed.toUpperCase().contains('BEGIN:VEVENT')) {
      return _parseClassIcs(trimmed);
    } else if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      return _parseClassJson(trimmed);
    } else {
      return _parseClassCsv(trimmed);
    }
  }

  /// Parses academic calendar notices from JSON, CSV, or .ics iCalendar raw string
  static ParseResult<AcademicNotice> parseAcademicCalendar(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return ParseResult.failure('Content is empty.');
    }

    if (trimmed.toUpperCase().contains('BEGIN:VCALENDAR') || trimmed.toUpperCase().contains('BEGIN:VEVENT')) {
      return _parseAcademicIcs(trimmed);
    } else if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      return _parseAcademicJson(trimmed);
    } else {
      return _parseAcademicCsv(trimmed);
    }
  }

  // ===================== ICS / iCALENDAR PARSING =====================

  static ParseResult<ClassSchedule> _parseClassIcs(String icsStr) {
    try {
      final events = _extractIcsEvents(icsStr);
      if (events.isEmpty) {
        return ParseResult.failure('No VEVENT blocks found in .ics file.');
      }

      final List<ClassSchedule> results = [];
      int counter = 1;

      for (var ev in events) {
        final summary = ev['SUMMARY'] ?? 'Untitled Class';
        final description = ev['DESCRIPTION'] ?? '';
        final location = ev['LOCATION'] ?? 'Room TBA';
        final dtStartStr = ev['DTSTART'] ?? '';
        final dtEndStr = ev['DTEND'] ?? '';
        final rrule = ev['RRULE'] ?? '';

        // Extract day of week (from RRULE or DTSTART)
        int dayOfWeek = 1;
        if (rrule.contains('BYDAY=')) {
          final byDay = rrule.split('BYDAY=')[1].split(';')[0].toUpperCase();
          dayOfWeek = _dayCodeToWeekday(byDay);
        } else if (dtStartStr.isNotEmpty) {
          final dt = _parseIcsDateTime(dtStartStr);
          if (dt != null) dayOfWeek = dt.weekday;
        }

        // Extract start/end times (HH:mm)
        String startTime = '09:00';
        String endTime = '10:30';

        if (dtStartStr.contains('T')) {
          final timePart = dtStartStr.split('T')[1].replaceAll('Z', '');
          if (timePart.length >= 4) {
            startTime = '${timePart.substring(0, 2)}:${timePart.substring(2, 4)}';
          }
        }
        if (dtEndStr.contains('T')) {
          final timePart = dtEndStr.split('T')[1].replaceAll('Z', '');
          if (timePart.length >= 4) {
            endTime = '${timePart.substring(0, 2)}:${timePart.substring(2, 4)}';
          }
        }

        // Extract Course Code from summary (e.g. "CSE-201: Data Structures" or "Algorithms [CSE201]")
        String courseCode = 'GEN-101';
        String subject = summary;

        if (summary.contains(':')) {
          final parts = summary.split(':');
          courseCode = parts[0].trim();
          subject = parts.sublist(1).join(':').trim();
        } else if (summary.contains(' - ')) {
          final parts = summary.split(' - ');
          courseCode = parts[0].trim();
          subject = parts.sublist(1).join(' - ').trim();
        }

        // Extract instructor from description if present
        String instructor = 'Instructor';
        if (description.toLowerCase().contains('instructor:')) {
          instructor = description.split(RegExp(r'instructor:', caseSensitive: false))[1].split(',')[0].trim();
        } else if (description.toLowerCase().contains('teacher:')) {
          instructor = description.split(RegExp(r'teacher:', caseSensitive: false))[1].split(',')[0].trim();
        }

        results.add(ClassSchedule(
          id: ev['UID'] ?? 'CLS-ICS-$counter',
          subject: subject.isNotEmpty ? subject : summary,
          courseCode: courseCode,
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          room: location,
          instructor: instructor,
          colorHex: '#2563EB',
        ));
        counter++;
      }

      return ParseResult.success(results);
    } catch (e) {
      return ParseResult.failure('Failed to parse .ics class schedule: ${e.toString()}');
    }
  }

  static ParseResult<AcademicNotice> _parseAcademicIcs(String icsStr) {
    try {
      final events = _extractIcsEvents(icsStr);
      if (events.isEmpty) {
        return ParseResult.failure('No VEVENT blocks found in .ics file.');
      }

      final List<AcademicNotice> results = [];
      int counter = 1;

      for (var ev in events) {
        final title = ev['SUMMARY'] ?? 'Untitled Notice';
        final description = ev['DESCRIPTION'] ?? '';
        final dtStartStr = ev['DTSTART'] ?? '';
        final dtEndStr = ev['DTEND'] ?? dtStartStr;
        final categories = (ev['CATEGORIES'] ?? '').toLowerCase();

        final startDate = _parseIcsDateTime(dtStartStr) ?? DateTime.now();
        final endDate = _parseIcsDateTime(dtEndStr) ?? startDate;

        final isHoliday = categories.contains('holiday') ||
            title.toLowerCase().contains('holiday') ||
            description.toLowerCase().contains('holiday');
        final isExam = categories.contains('exam') || title.toLowerCase().contains('exam');
        final isFee = title.toLowerCase().contains('installment') || title.toLowerCase().contains('fee');

        NoticeCategory category;
        if (isHoliday) {
          category = NoticeCategory.holiday;
        } else if (isExam) {
          category = NoticeCategory.exam;
        } else if (isFee) {
          category = NoticeCategory.semesterFee;
        } else if (title.toLowerCase().contains('registration') || title.toLowerCase().contains('drop') || title.toLowerCase().contains('grade')) {
          category = NoticeCategory.administrative;
        } else {
          category = NoticeCategory.event;
        }

        results.add(AcademicNotice(
          id: ev['UID'] ?? 'NOT-ICS-$counter',
          title: title,
          description: description,
          startDate: startDate,
          endDate: endDate,
          category: category,
          isHoliday: isHoliday,
          priority: isHoliday || isFee || isExam ? NoticePriority.urgent : NoticePriority.medium,
        ));
        counter++;
      }

      return ParseResult.success(results);
    } catch (e) {
      return ParseResult.failure('Failed to parse .ics academic calendar: ${e.toString()}');
    }
  }

  // ===================== ICS EXPORTER WITH HOLIDAY CONFLICT RULE =====================

  /// Exports the entire academic schedule and class timetables to standard .ics iCalendar format.
  /// Enforces Holiday rule: Classes occurring on any holiday date are excluded from the exported calendar!
  static String exportCalendarToIcs(
    CalendarService calendarService, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now().add(const Duration(days: 90));

    final StringBuffer sb = StringBuffer();
    sb.writeln('BEGIN:VCALENDAR');
    sb.writeln('VERSION:2.0');
    sb.writeln('PRODID:-//EduCal//Smart Academic Calendar & Conflict Resolver//EN');
    sb.writeln('CALSCALE:GREGORIAN');
    sb.writeln('METHOD:PUBLISH');
    sb.writeln('X-WR-CALNAME:EduCal Academic Schedule');

    // 1. Export Academic Notices (Holidays, Fee Deadlines, Exams)
    for (var notice in calendarService.notices) {
      sb.writeln('BEGIN:VEVENT');
      sb.writeln('UID:${notice.id}@educal.app');
      sb.writeln('DTSTAMP:${_formatIcsDate(DateTime.now())}T000000Z');
      sb.writeln('DTSTART;VALUE=DATE:${_formatIcsDate(notice.startDate)}');
      sb.writeln('DTEND;VALUE=DATE:${_formatIcsDate(notice.endDate.add(const Duration(days: 1)))}');
      sb.writeln('SUMMARY:${_escapeIcs(notice.title)}');
      sb.writeln('DESCRIPTION:${_escapeIcs(notice.description)}');
      sb.writeln('CATEGORIES:${notice.isHoliday ? 'HOLIDAY' : notice.category.name.toUpperCase()}');
      if (notice.isHoliday) {
        sb.writeln('X-EDUCAL-TYPE:HOLIDAY-NO-CLASSES');
      }
      sb.writeln('END:VEVENT');
    }

    // 2. Export Class Schedules (Iterate each day and exclude holidays)
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDay)) {
      final daySchedule = calendarService.getDaySchedule(current);

      // Crucial logic: Only export classes if the day is NOT a holiday
      if (!daySchedule.isHoliday) {
        for (var cls in daySchedule.activeClasses) {
          final dateStr = _formatIcsDate(current);
          final startParts = cls.startTime.split(':');
          final endParts = cls.endTime.split(':');
          final startH = (int.tryParse(startParts[0]) ?? 9).toString().padLeft(2, '0');
          final startM = (startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0).toString().padLeft(2, '0');
          final endH = (int.tryParse(endParts[0]) ?? 10).toString().padLeft(2, '0');
          final endM = (endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0).toString().padLeft(2, '0');

          sb.writeln('BEGIN:VEVENT');
          sb.writeln('UID:CLS-${cls.id}-$dateStr@educal.app');
          sb.writeln('DTSTAMP:${_formatIcsDate(DateTime.now())}T000000Z');
          sb.writeln('DTSTART:${dateStr}T$startH${startM}00');
          sb.writeln('DTEND:${dateStr}T$endH${endM}00');
          sb.writeln('SUMMARY:${_escapeIcs('${cls.courseCode}: ${cls.subject}')}');
          sb.writeln('DESCRIPTION:${_escapeIcs('Instructor: ${cls.instructor}, Room: ${cls.room}')}');
          sb.writeln('LOCATION:${_escapeIcs(cls.room)}');
          sb.writeln('CATEGORIES:CLASS');
          sb.writeln('END:VEVENT');
        }
      }

      current = current.add(const Duration(days: 1));
    }

    sb.writeln('END:VCALENDAR');
    return sb.toString();
  }

  // ===================== JSON PARSING =====================

  static ParseResult<ClassSchedule> _parseClassJson(String jsonStr) {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      final List<dynamic> list = decoded is List ? decoded : [decoded];
      final List<ClassSchedule> results = [];

      for (var item in list) {
        if (item is Map<String, dynamic>) {
          results.add(ClassSchedule.fromJson(item));
        } else if (item is Map) {
          results.add(ClassSchedule.fromJson(Map<String, dynamic>.from(item)));
        }
      }

      if (results.isEmpty) {
        return ParseResult.failure('No valid class schedules found in JSON.');
      }
      return ParseResult.success(results);
    } catch (e) {
      return ParseResult.failure('Invalid JSON syntax: ${e.toString()}');
    }
  }

  static ParseResult<AcademicNotice> _parseAcademicJson(String jsonStr) {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      final List<dynamic> list = decoded is List ? decoded : [decoded];
      final List<AcademicNotice> results = [];

      for (var item in list) {
        if (item is Map<String, dynamic>) {
          results.add(AcademicNotice.fromJson(item));
        } else if (item is Map) {
          results.add(AcademicNotice.fromJson(Map<String, dynamic>.from(item)));
        }
      }

      if (results.isEmpty) {
        return ParseResult.failure('No valid academic notices found in JSON.');
      }
      return ParseResult.success(results);
    } catch (e) {
      return ParseResult.failure('Invalid JSON syntax: ${e.toString()}');
    }
  }

  // ===================== CSV PARSING =====================

  static ParseResult<ClassSchedule> _parseClassCsv(String csvStr) {
    try {
      final lines = const LineSplitter().convert(csvStr).where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        return ParseResult.failure('CSV file is empty.');
      }

      final header = lines.first.toLowerCase().split(',').map((h) => h.trim()).toList();
      final idIdx = header.indexOf('id');
      final subjectIdx = header.indexOf('subject');
      final codeIdx = header.indexOf('coursecode');
      final dayIdx = header.indexOf('dayofweek');
      final startIdx = header.indexOf('starttime');
      final endIdx = header.indexOf('endtime');
      final roomIdx = header.indexOf('room');
      final instructorIdx = header.indexOf('instructor');
      final colorIdx = header.indexOf('color');

      final List<ClassSchedule> results = [];
      for (int i = 1; i < lines.length; i++) {
        final cols = _splitCsvLine(lines[i]);
        if (cols.length < 4) continue;

        String getCol(int idx, [String fallback = '']) {
          if (idx >= 0 && idx < cols.length) {
            return cols[idx].trim();
          }
          return fallback;
        }

        final subject = getCol(subjectIdx, cols.length > 1 ? cols[1] : 'Subject');
        final code = getCol(codeIdx, cols.length > 2 ? cols[2] : 'CODE');
        final dayStr = getCol(dayIdx, cols.length > 3 ? cols[3] : '1');
        final day = _parseDayOfWeek(dayStr);
        final start = getCol(startIdx, cols.length > 4 ? cols[4] : '09:00');
        final end = getCol(endIdx, cols.length > 5 ? cols[5] : '10:00');
        final room = getCol(roomIdx, cols.length > 6 ? cols[6] : 'TBA');
        final instructor = getCol(instructorIdx, cols.length > 7 ? cols[7] : 'Instructor');
        final color = getCol(colorIdx, '#2563EB');

        results.add(ClassSchedule(
          id: getCol(idIdx, 'CLS-$i'),
          subject: subject,
          courseCode: code,
          dayOfWeek: day,
          startTime: start,
          endTime: end,
          room: room,
          instructor: instructor,
          colorHex: color.isNotEmpty ? color : '#2563EB',
        ));
      }

      if (results.isEmpty) {
        return ParseResult.failure('No valid records parsed from CSV.');
      }
      return ParseResult.success(results);
    } catch (e) {
      return ParseResult.failure('Failed to parse CSV: ${e.toString()}');
    }
  }

  static ParseResult<AcademicNotice> _parseAcademicCsv(String csvStr) {
    try {
      final lines = const LineSplitter().convert(csvStr).where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        return ParseResult.failure('CSV file is empty.');
      }

      final header = lines.first.toLowerCase().split(',').map((h) => h.trim()).toList();
      final idIdx = header.indexOf('id');
      final titleIdx = header.indexOf('title');
      final descIdx = header.indexOf('description');
      final startIdx = header.indexOf('startdate');
      final endIdx = header.indexOf('enddate');
      final catIdx = header.indexOf('category');
      final holIdx = header.indexOf('isholiday');
      final prioIdx = header.indexOf('priority');

      final List<AcademicNotice> results = [];
      for (int i = 1; i < lines.length; i++) {
        final cols = _splitCsvLine(lines[i]);
        if (cols.length < 3) continue;

        String getCol(int idx, [String fallback = '']) {
          if (idx >= 0 && idx < cols.length) {
            return cols[idx].trim();
          }
          return fallback;
        }

        final title = getCol(titleIdx, cols.length > 1 ? cols[1] : 'Notice');
        final desc = getCol(descIdx, cols.length > 2 ? cols[2] : '');
        final start = DateTime.tryParse(getCol(startIdx, DateTime.now().toIso8601String())) ?? DateTime.now();
        final end = DateTime.tryParse(getCol(endIdx, getCol(startIdx))) ?? start;
        final catStr = getCol(catIdx, 'other').toLowerCase();
        final holStr = getCol(holIdx, 'false').toLowerCase();
        final isHol = holStr == 'true' || catStr.contains('holiday');

        NoticeCategory cat;
        if (catStr.contains('holiday') || isHol) {
          cat = NoticeCategory.holiday;
        } else if (catStr.contains('fee')) {
          cat = NoticeCategory.semesterFee;
        } else if (catStr.contains('exam')) {
          cat = NoticeCategory.exam;
        } else if (catStr.contains('admin')) {
          cat = NoticeCategory.administrative;
        } else if (catStr.contains('event')) {
          cat = NoticeCategory.event;
        } else {
          cat = NoticeCategory.other;
        }

        final prioStr = getCol(prioIdx, 'medium').toLowerCase();
        NoticePriority prio;
        if (prioStr.contains('urgent')) {
          prio = NoticePriority.urgent;
        } else if (prioStr.contains('high')) {
          prio = NoticePriority.high;
        } else if (prioStr.contains('low')) {
          prio = NoticePriority.low;
        } else {
          prio = NoticePriority.medium;
        }

        results.add(AcademicNotice(
          id: getCol(idIdx, 'NOT-$i'),
          title: title,
          description: desc,
          startDate: start,
          endDate: end,
          category: cat,
          isHoliday: isHol,
          priority: prio,
        ));
      }

      if (results.isEmpty) {
        return ParseResult.failure('No valid records parsed from CSV.');
      }
      return ParseResult.success(results);
    } catch (e) {
      return ParseResult.failure('Failed to parse CSV: ${e.toString()}');
    }
  }

  // ===================== HELPER METHODS =====================

  static List<Map<String, String>> _extractIcsEvents(String icsStr) {
    final List<Map<String, String>> events = [];
    final lines = const LineSplitter().convert(icsStr);
    Map<String, String>? currentEvent;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'BEGIN:VEVENT') {
        currentEvent = {};
      } else if (trimmed == 'END:VEVENT') {
        if (currentEvent != null) {
          events.add(currentEvent);
          currentEvent = null;
        }
      } else if (currentEvent != null && trimmed.contains(':')) {
        final colonIdx = trimmed.indexOf(':');
        final keyPart = trimmed.substring(0, colonIdx).split(';')[0].toUpperCase().trim();
        final valuePart = trimmed.substring(colonIdx + 1).trim();
        currentEvent[keyPart] = valuePart;
      }
    }

    return events;
  }

  static DateTime? _parseIcsDateTime(String str) {
    final clean = str.replaceAll('-', '').replaceAll(':', '').replaceAll('Z', '').trim();
    if (clean.length >= 8) {
      final year = int.tryParse(clean.substring(0, 4)) ?? 2026;
      final month = int.tryParse(clean.substring(4, 6)) ?? 1;
      final day = int.tryParse(clean.substring(6, 8)) ?? 1;
      return DateTime(year, month, day);
    }
    return null;
  }

  static int _dayCodeToWeekday(String code) {
    switch (code) {
      case 'MO':
        return 1;
      case 'TU':
        return 2;
      case 'WE':
        return 3;
      case 'TH':
        return 4;
      case 'FR':
        return 5;
      case 'SA':
        return 6;
      case 'SU':
        return 7;
      default:
        return 1;
    }
  }

  static String _formatIcsDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static String _escapeIcs(String text) {
    return text.replaceAll('\\', '\\\\').replaceAll('\n', '\\n').replaceAll(',', '\\,');
  }

  static List<String> _splitCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  static int _parseDayOfWeek(String input) {
    final clean = input.trim().toLowerCase();
    final asInt = int.tryParse(clean);
    if (asInt != null && asInt >= 1 && asInt <= 7) {
      return asInt;
    }
    if (clean.startsWith('mon')) return 1;
    if (clean.startsWith('tue')) return 2;
    if (clean.startsWith('wed')) return 3;
    if (clean.startsWith('thu')) return 4;
    if (clean.startsWith('fri')) return 5;
    if (clean.startsWith('sat')) return 6;
    if (clean.startsWith('sun')) return 7;
    return 1;
  }
}
