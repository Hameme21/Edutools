import 'package:flutter/material.dart';
import '../../models/class_schedule.dart';

class ClassReminderDialog extends StatefulWidget {
  final ClassSchedule classSchedule;
  final int defaultMinutes;
  final Function({
    required int minutesBefore,
    required bool applyToAll,
    required bool enabled,
  }) onSave;

  const ClassReminderDialog({
    super.key,
    required this.classSchedule,
    required this.defaultMinutes,
    required this.onSave,
  });

  @override
  State<ClassReminderDialog> createState() => _ClassReminderDialogState();
}

class _ClassReminderDialogState extends State<ClassReminderDialog> {
  late int _minutesBefore;
  late bool _enabled;
  bool _applyToAll = false;

  final List<int> _minuteOptions = [5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _minutesBefore = widget.classSchedule.customReminderMinutes ?? widget.defaultMinutes;
    _enabled = widget.classSchedule.reminderEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.alarm_rounded, color: Color(0xFF3B82F6), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Class Reminder',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Class info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.classSchedule.color.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.classSchedule.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.classSchedule.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.classSchedule.courseCode}: ${widget.classSchedule.subject}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${widget.classSchedule.dayName} • ${widget.classSchedule.timeRangeFormatted} (${widget.classSchedule.room})',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Enable toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Reminder for this Class', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Silenced automatically if a holiday falls on this date', style: TextStyle(fontSize: 11, color: Colors.grey)),
              value: _enabled,
              onChanged: (val) => setState(() => _enabled = val),
            ),

            if (_enabled) ...[
              const Divider(height: 16),
              // Lead time selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remind me before class:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  DropdownButton<int>(
                    value: _minutesBefore,
                    underline: const SizedBox.shrink(),
                    items: _minuteOptions.map((min) {
                      return DropdownMenuItem(
                        value: min,
                        child: Text(
                          '$min mins before',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _minutesBefore = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scope selection (This course only vs All courses)
              const Text('Apply this reminder setting to:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('This course only (${widget.classSchedule.courseCode})', style: const TextStyle(fontSize: 13)),
                value: false,
                groupValue: _applyToAll,
                onChanged: (val) => setState(() => _applyToAll = val ?? false),
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('All courses & classes', style: TextStyle(fontSize: 13)),
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
                    minutesBefore: _minutesBefore,
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
    );
  }
}
