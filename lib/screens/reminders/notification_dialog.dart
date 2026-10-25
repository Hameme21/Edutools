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
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: screenHeight * 0.82,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reminders & Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  onPressed: onOpenSettings,
                  tooltip: 'Settings',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Sub-header summary and actions
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${activeNotifications.length} scheduled reminders',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.settings_outlined, size: 13),
                      label: const Text('Customize', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                    ),
                    if (activeNotifications.any((n) => !n.isRead)) ...[
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: onMarkAllRead,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        ),
                        child: const Text('Mark all read', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Divider(height: 14),

            // Notification List
            Flexible(
              child: notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.notifications_off_outlined, size: 44, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No reminders scheduled yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (activeNotifications.isNotEmpty) ...[
                          ...activeNotifications.map((n) => _buildNotificationTile(n, isDark)),
                        ],
                        if (mutedNotifications.isNotEmpty) ...[
                          const SizedBox(height: 10),
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
                                Expanded(
                                  child: Text(
                                    'Silenced by Holiday Conflict Rule (No Class)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (n.isMutedDueToHoliday)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
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
