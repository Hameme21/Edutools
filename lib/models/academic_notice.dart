import 'package:flutter/material.dart';

enum NoticeCategory {
  holiday,
  semesterFee,
  exam,
  administrative,
  event,
  other,
}

enum NoticePriority {
  low,
  medium,
  high,
  urgent,
}

class AcademicNotice {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final NoticeCategory category;
  final bool isHoliday;
  final NoticePriority priority;
  final bool reminderEnabled;
  final TimeOfDay? customReminderTime; // Custom time override for this notice
  final bool? customRemindDayBefore; // Custom day-before flag override

  AcademicNotice({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.category,
    this.isHoliday = false,
    this.priority = NoticePriority.medium,
    this.reminderEnabled = true,
    this.customReminderTime,
    this.customRemindDayBefore,
  });

  bool get isSingleDay =>
      startDate.year == endDate.year &&
      startDate.month == endDate.month &&
      startDate.day == endDate.day;

  bool coversDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return (target.isAtSameMomentAs(start) || target.isAfter(start)) &&
        (target.isAtSameMomentAs(end) || target.isBefore(end));
  }

  int daysRemaining([DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return start.difference(today).inDays;
  }

  bool isHappeningNow([DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return (today.isAtSameMomentAs(start) || today.isAfter(start)) &&
        (today.isAtSameMomentAs(end) || today.isBefore(end));
  }

  String get countdownText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (isHappeningNow()) {
      if (start.isAtSameMomentAs(end)) {
        return 'Happening today!';
      }
      final remainingDays = end.difference(today).inDays;
      if (remainingDays <= 0) return 'Last day today!';
      if (remainingDays == 1) return '1 day left';
      return '$remainingDays days left';
    }

    final days = daysRemaining();
    if (days < 0) {
      final pastDays = -days;
      return pastDays == 1 ? '1 day ago' : '$pastDays days ago';
    } else if (days == 0) {
      return 'Today!';
    } else if (days == 1) {
      return '1 day left';
    } else {
      return '$days days left';
    }
  }

  String get categoryName {
    switch (category) {
      case NoticeCategory.holiday:
        return 'Holiday';
      case NoticeCategory.semesterFee:
        return 'Semester Fee';
      case NoticeCategory.exam:
        return 'Examination';
      case NoticeCategory.administrative:
        return 'Administrative';
      case NoticeCategory.event:
        return 'Event';
      case NoticeCategory.other:
        return 'General Notice';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case NoticeCategory.holiday:
        return Icons.beach_access_rounded;
      case NoticeCategory.semesterFee:
        return Icons.account_balance_wallet_rounded;
      case NoticeCategory.exam:
        return Icons.assignment_rounded;
      case NoticeCategory.administrative:
        return Icons.admin_panel_settings_rounded;
      case NoticeCategory.event:
        return Icons.celebration_rounded;
      case NoticeCategory.other:
        return Icons.info_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case NoticeCategory.holiday:
        return const Color(0xFFE53935);
      case NoticeCategory.semesterFee:
        return const Color(0xFFFF9800);
      case NoticeCategory.exam:
        return const Color(0xFF8E24AA);
      case NoticeCategory.administrative:
        return const Color(0xFF3949AB);
      case NoticeCategory.event:
        return const Color(0xFF00897B);
      case NoticeCategory.other:
        return const Color(0xFF546E7A);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String().split('T').first,
      'endDate': endDate.toIso8601String().split('T').first,
      'category': category.name,
      'isHoliday': isHoliday,
      'priority': priority.name,
      'reminderEnabled': reminderEnabled,
      'customReminderHour': customReminderTime?.hour,
      'customReminderMinute': customReminderTime?.minute,
      'customRemindDayBefore': customRemindDayBefore,
    };
  }

  factory AcademicNotice.fromJson(Map<String, dynamic> json) {
    final catStr = json['category']?.toString().toLowerCase() ?? '';
    NoticeCategory parsedCat;
    if (catStr.contains('holiday')) {
      parsedCat = NoticeCategory.holiday;
    } else if (catStr.contains('fee')) {
      parsedCat = NoticeCategory.semesterFee;
    } else if (catStr.contains('exam')) {
      parsedCat = NoticeCategory.exam;
    } else if (catStr.contains('admin')) {
      parsedCat = NoticeCategory.administrative;
    } else if (catStr.contains('event')) {
      parsedCat = NoticeCategory.event;
    } else {
      parsedCat = NoticeCategory.other;
    }

    final prioStr = json['priority']?.toString().toLowerCase() ?? '';
    NoticePriority parsedPrio;
    if (prioStr.contains('urgent')) {
      parsedPrio = NoticePriority.urgent;
    } else if (prioStr.contains('high')) {
      parsedPrio = NoticePriority.high;
    } else if (prioStr.contains('low')) {
      parsedPrio = NoticePriority.low;
    } else {
      parsedPrio = NoticePriority.medium;
    }

    final startParsed = DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now();
    final endParsed = DateTime.tryParse(json['endDate']?.toString() ?? '') ?? startParsed;
    final isHol = json['isHoliday'] == true || parsedCat == NoticeCategory.holiday || json['isHoliday']?.toString().toLowerCase() == 'true';

    TimeOfDay? customTime;
    if (json['customReminderHour'] != null && json['customReminderMinute'] != null) {
      customTime = TimeOfDay(
        hour: int.tryParse(json['customReminderHour'].toString()) ?? 8,
        minute: int.tryParse(json['customReminderMinute'].toString()) ?? 0,
      );
    }

    return AcademicNotice(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['title']?.toString() ?? 'Untitled Notice',
      description: json['description']?.toString() ?? '',
      startDate: startParsed,
      endDate: endParsed,
      category: parsedCat,
      isHoliday: isHol,
      priority: parsedPrio,
      reminderEnabled: json['reminderEnabled'] != false,
      customReminderTime: customTime,
      customRemindDayBefore: json['customRemindDayBefore'] as bool?,
    );
  }

  AcademicNotice copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    NoticeCategory? category,
    bool? isHoliday,
    NoticePriority? priority,
    bool? reminderEnabled,
    TimeOfDay? customReminderTime,
    bool? customRemindDayBefore,
    bool clearCustomReminder = false,
  }) {
    return AcademicNotice(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      isHoliday: isHoliday ?? this.isHoliday,
      priority: priority ?? this.priority,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      customReminderTime: clearCustomReminder ? null : (customReminderTime ?? this.customReminderTime),
      customRemindDayBefore: clearCustomReminder ? null : (customRemindDayBefore ?? this.customRemindDayBefore),
    );
  }
}
