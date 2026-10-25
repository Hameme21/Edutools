import 'package:flutter/material.dart';
import '../../models/academic_notice.dart';
import '../../models/reminder_settings.dart';

class NoticeReminderDialog extends StatefulWidget {
  final AcademicNotice notice;
  final ReminderSettings defaultSettings;
  final Function({
    required TimeOfDay reminderTime,
    required bool dayBefore,
    required bool applyToAll,
    required bool enabled,
  }) onSave;

  const NoticeReminderDialog({
    super.key,
    required this.notice,
    required this.defaultSettings,
    required this.onSave,
  });

  @override
  State<NoticeReminderDialog> createState() => _NoticeReminderDialogState();
}

class _NoticeReminderDialogState extends State<NoticeReminderDialog> {
  late TimeOfDay _reminderTime;
  late bool _dayBefore;
  late bool _enabled;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.notice.reminderEnabled;

    if (widget.notice.isHoliday) {
      _reminderTime = widget.notice.customReminderTime ?? widget.defaultSettings.holidayReminderTime;
      _dayBefore = false;
    } else {
      _reminderTime = widget.notice.customReminderTime ?? widget.defaultSettings.normalEventReminderTime;
      _dayBefore = widget.notice.customRemindDayBefore ?? widget.defaultSettings.normalEventRemindDayBefore;
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHoliday = widget.notice.isHoliday;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.notice.categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.notice.categoryIcon, color: widget.notice.categoryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isHoliday ? 'Holiday Reminder' : '${widget.notice.categoryName} Reminder',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
            const SizedBox(height: 12),

            // Event info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.notice.categoryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.notice.categoryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.notice.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.notice.categoryName} • ${widget.notice.countdownText}',
                    style: TextStyle(fontSize: 11, color: widget.notice.categoryColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Enable toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Enable Reminder for this ${isHoliday ? "Holiday" : "Event"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(
                isHoliday ? 'Morning alert when campus is closed & classes cancelled' : 'Alert before deadline or scheduled date',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _enabled,
              onChanged: (val) => setState(() => _enabled = val),
            ),

            if (_enabled) ...[
              const Divider(height: 16),

              if (!isHoliday) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Remind Day Before (Default: 10:00 PM)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _dayBefore,
                  onChanged: (val) => setState(() => _dayBefore = val ?? true),
                ),
                const SizedBox(height: 4),
              ],

              // Time Picker Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isHoliday
                        ? 'Holiday Morning Alert Time:'
                        : (_dayBefore ? 'Day-Before Alert Time:' : 'Same-Day Alert Time:'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 14),
                    label: Text(_formatTime(_reminderTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scope selection
              const Text('Apply this reminder setting to:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('This event only ("${widget.notice.title}")', style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                value: false,
                groupValue: _applyToAll,
                onChanged: (val) => setState(() => _applyToAll = val ?? false),
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(isHoliday ? 'All holidays in calendar' : 'All ${widget.notice.categoryName.toLowerCase()} events', style: const TextStyle(fontSize: 13)),
                value: true,
                groupValue: _applyToAll,
                onChanged: (val) => setState(() => _applyToAll = val ?? true),
              ),
            ],
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(
                    reminderTime: _reminderTime,
                    dayBefore: _dayBefore,
                    applyToAll: _applyToAll,
                    enabled: _enabled,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Save Reminder Preference'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
