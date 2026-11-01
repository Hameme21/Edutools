import 'package:flutter_test/flutter_test.dart';
import 'package:educal/services/android_notification_service.dart';
import 'package:educal/models/reminder_notification.dart';

void main() {
  test('Android reminders use separate channels and exclude past or holiday-muted classes', () {
    final now = DateTime(2026, 11, 1, 10);
    final reminders = NotificationType.values.map((type) => ReminderNotification(
      id: type.name, title: 'Reminder', body: 'Details',
      scheduledFor: now.add(const Duration(hours: 1)), type: type,
    )).toList();
    reminders.add(ReminderNotification(id:'muted', title:'Cancelled class', body:'Holiday', scheduledFor:now.add(const Duration(hours:1)), type:NotificationType.classReminder, isMutedDueToHoliday:true));
    reminders.add(ReminderNotification(id:'past', title:'Old class', body:'Past', scheduledFor:now.subtract(const Duration(hours:1)), type:NotificationType.classReminder));
    final payload = AndroidNotificationService.buildPayload(reminders, now: now);
    expect(payload, hasLength(5));
    expect(payload.map((n) => n['channel']).toSet(), {'classes','events','semester_fees','exams','holidays'});
    expect(payload.every((n) => (n['at'] as int) > now.millisecondsSinceEpoch), isTrue);
  });
}
