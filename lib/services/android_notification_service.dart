import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/reminder_notification.dart';

class AndroidNotificationService {
  static const _channel = MethodChannel('edutools/notifications');
  static Timer? _pending;
  static bool get supported => !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST') && defaultTargetPlatform == TargetPlatform.android;
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }
  static void schedule(List<ReminderNotification> reminders) {
    if (!supported) return;
    _pending?.cancel();
    final payload = buildPayload(reminders);
    _pending = Timer(const Duration(milliseconds: 250), () async {
      try { await _channel.invokeMethod('schedule', payload); }
      catch (error) { debugPrint('Android notification scheduling failed: $error'); }
    });
  }
  static List<Map<String, Object>> buildPayload(List<ReminderNotification> reminders, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return reminders.where((n) => !n.isMutedDueToHoliday && n.scheduledFor.isAfter(reference)).map((n) => <String, Object>{
      'id': n.id, 'title': n.title, 'body': n.body,
      'at': n.scheduledFor.millisecondsSinceEpoch,
      'channel': switch (n.type) {
        NotificationType.classReminder => 'classes',
        NotificationType.feeReminder => 'semester_fees',
        NotificationType.examReminder => 'exams',
        NotificationType.holidayAlert => 'holidays',
        NotificationType.generalNotice => 'events',
      },
    }).toList();
  }
}
