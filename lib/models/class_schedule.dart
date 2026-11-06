import 'package:flutter/material.dart';
import 'course_catalog.dart';

class ClassSchedule {
  final String id;
  final String subject;
  final String courseCode;
  final String section;
  final int dayOfWeek; // 1 = Monday, ..., 7 = Sunday
  final String startTime; // "09:00" (24h)
  final String endTime; // "10:30" (24h)
  final String room;
  final String instructor;
  final String colorHex;
  final int? customReminderMinutes; // If null, uses global default (e.g. 10m)
  final bool reminderEnabled;

  ClassSchedule({
    required this.id,
    required this.subject,
    required this.courseCode,
    this.section = '',
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.instructor,
    this.colorHex = '#4A90E2',
    this.customReminderMinutes,
    this.reminderEnabled = true,
  });

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  String get dayShortName {
    switch (dayOfWeek) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '---';
    }
  }

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF4A90E2);
  }

  TimeOfDay get parsedStartTime {
    final parts = startTime.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  TimeOfDay get parsedEndTime {
    final parts = endTime.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 10,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  String get timeRangeFormatted {
    return '$startTime - $endTime';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'courseCode': courseCode,
      'section': section,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'instructor': instructor,
      'color': colorHex,
      'customReminderMinutes': customReminderMinutes,
      'reminderEnabled': reminderEnabled,
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      subject: json['subject']?.toString() ?? 'Untitled Class',
      section: json['section']?.toString() ??
          RegExp(r'\b(?:section|sec)[\s:-]+([A-Za-z]{1,3})\b',
                  caseSensitive: false)
              .firstMatch(json['subject']?.toString() ?? '')
              ?.group(1) ??
          '',
      courseCode: (json['courseCode']?.toString().trim().isNotEmpty ?? false) &&
              json['courseCode'] != 'GEN-101'
          ? json['courseCode'].toString()
          : courseCodeForTitle(json['subject']?.toString() ?? '') ??
              json['courseCode']?.toString() ??
              '',
      dayOfWeek: int.tryParse(json['dayOfWeek']?.toString() ?? '1') ?? 1,
      startTime: json['startTime']?.toString() ?? '09:00',
      endTime: json['endTime']?.toString() ?? '10:00',
      room: json['room']?.toString() ?? 'TBA',
      instructor: json['instructor']?.toString() ?? '',
      colorHex: json['color']?.toString() ??
          json['colorHex']?.toString() ??
          '#4A90E2',
      customReminderMinutes: json['customReminderMinutes'] != null
          ? int.tryParse(json['customReminderMinutes'].toString())
          : null,
      reminderEnabled: json['reminderEnabled'] != false,
    );
  }

  ClassSchedule copyWith({
    String? id,
    String? subject,
    String? courseCode,
    String? section,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    String? instructor,
    String? colorHex,
    int? customReminderMinutes,
    bool? reminderEnabled,
    bool clearCustomReminder = false,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      courseCode: courseCode ?? this.courseCode,
      section: section ?? this.section,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      colorHex: colorHex ?? this.colorHex,
      customReminderMinutes: clearCustomReminder
          ? null
          : (customReminderMinutes ?? this.customReminderMinutes),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}
