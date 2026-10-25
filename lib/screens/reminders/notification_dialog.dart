import 'package:flutter/material.dart';
import '../../models/reminder_notification.dart';

class NotificationDialog extends StatelessWidget {
  final List<ReminderNotification> notifications;
  final Function(String) onMarkRead;
  final VoidCallback onMarkAllRead;
  final VoidCallback onOpenSettings;

  const NotificationDialog({
    super.key,
    required this.notifications,
    required this.onMarkRead,
    required this.onMarkAllRead,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeNotifications = notifications.where((n) => !n.isMutedDueToHoliday).toList();
    final mutedNotifications = notifications.where((n) => n.isMutedDueToHoliday).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 8),
                    Text(
                      'Reminders & Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      onPressed: onOpenSettings,
                      tooltip: 'Customize Reminder Timings',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${activeNotifications.length} scheduled reminders',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.settings_outlined, size: 14),
                      label: const Text('Customize', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                    if (activeNotifications.any((n) => !n.isRead)) ...[
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: onMarkAllRead,
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        child: const Text('Mark read', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Divider(height: 16),

            // Notification List
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No reminders scheduled yet.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (activeNotifications.isNotEmpty) ...[
                          ...activeNotifications.map((n) => _buildNotificationTile(n, isDark)),
                        ],
                        if (mutedNotifications.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.volume_off_rounded, size: 14, color: Colors.grey),
                                SizedBox(width: 6),
                                Text(
                                  'Silenced by Holiday Rule (No Class)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...mutedNotifications.map((n) => _buildNotificationTile(n, isDark)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(ReminderNotification n, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.isMutedDueToHoliday
            ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.08))
            : (n.isRead
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : n.color.withValues(alpha: isDark ? 0.15 : 0.06)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: n.isMutedDueToHoliday
              ? Colors.transparent
              : (n.isRead ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)) : n.color.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: n.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(n.icon, color: n.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (n.isMutedDueToHoliday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('MUTED', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  n.body,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trigger: ${_formatDateTime(n.scheduledFor)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${months[dt.month - 1]} ${dt.day}, $timeStr';
  }
}
