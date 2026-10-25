import 'package:flutter/material.dart';
import '../../models/reminder_settings.dart';

class ReminderSettingsDialog extends StatefulWidget {
  final ReminderSettings currentSettings;
  final Function(ReminderSettings) onSave;

  const ReminderSettingsDialog({
    super.key,
    required this.currentSettings,
    required this.onSave,
  });

  @override
  State<ReminderSettingsDialog> createState() => _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState extends State<ReminderSettingsDialog> {
  late TimeOfDay _holidayTime;
  late int _classMinutes;
  late TimeOfDay _normalEventTime;
  late bool _dayBefore;
  late bool _enableHoliday;
  late bool _enableClass;
  late bool _enableNormalEvent;

  final List<int> _classMinuteOptions = [5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _holidayTime = widget.currentSettings.holidayReminderTime;
    _classMinutes = widget.currentSettings.classReminderMinutesBefore;
    _normalEventTime = widget.currentSettings.normalEventReminderTime;
    _dayBefore = widget.currentSettings.normalEventRemindDayBefore;
    _enableHoliday = widget.currentSettings.enableHolidayReminders;
    _enableClass = widget.currentSettings.enableClassReminders;
    _enableNormalEvent = widget.currentSettings.enableNormalEventReminders;
  }

  Future<void> _pickHolidayTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _holidayTime,
    );
    if (picked != null) {
      setState(() => _holidayTime = picked);
    }
  }

  Future<void> _pickNormalEventTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _normalEventTime,
    );
    if (picked != null) {
      setState(() => _normalEventTime = picked);
    }
  }

  void _save() {
    final updated = widget.currentSettings.copyWith(
      holidayReminderTime: _holidayTime,
      classReminderMinutesBefore: _classMinutes,
      normalEventReminderTime: _normalEventTime,
      normalEventRemindDayBefore: _dayBefore,
      enableHolidayReminders: _enableHoliday,
      enableClassReminders: _enableClass,
      enableNormalEventReminders: _enableNormalEvent,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Customize Reminders',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
            const SizedBox(height: 4),
            const Text(
              'Set custom trigger timings for your academic calendar notifications.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 20),

            // Scrollable Settings
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Holiday Reminder
                    _buildSectionHeader('🎉 Holiday Notifications', const Color(0xFFEF4444)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable Holiday Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Alerts on holiday morning (all classes cancelled)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            value: _enableHoliday,
                            onChanged: (val) => setState(() => _enableHoliday = val),
                          ),
                          if (_enableHoliday) ...[
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Holiday Alert Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text('Default: 8:00 AM', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: _pickHolidayTime,
                                  icon: const Icon(Icons.access_time_rounded, size: 14),
                                  label: Text(_formatTime(_holidayTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Class Reminders
                    _buildSectionHeader('📚 Class Reminders', const Color(0xFF3B82F6)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable Class Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Muted automatically when a holiday occurs', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            value: _enableClass,
                            onChanged: (val) => setState(() => _enableClass = val),
                          ),
                          if (_enableClass) ...[
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Reminder Lead Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text('Default: 10 mins before', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                DropdownButton<int>(
                                  value: _classMinutes,
                                  underline: const SizedBox.shrink(),
                                  items: _classMinuteOptions.map((min) {
                                    return DropdownMenuItem(
                                      value: min,
                                      child: Text('$min mins before', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _classMinutes = val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Normal Events & Fee Deadlines
                    _buildSectionHeader('⏰ Normal Events & Deadlines', const Color(0xFFF59E0B)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable Event & Fee Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Alerts before fee dues, exams, & administrative dates', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            value: _enableNormalEvent,
                            onChanged: (val) => setState(() => _enableNormalEvent = val),
                          ),
                          if (_enableNormalEvent) ...[
                            const Divider(height: 12),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Remind Day Before', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Default: 10:00 PM the night prior', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              value: _dayBefore,
                              onChanged: (val) => setState(() => _dayBefore = val ?? true),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dayBefore ? 'Day-Before Alert Time:' : 'Same-Day Alert Time:',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _pickNormalEventTime,
                                  icon: const Icon(Icons.access_time_rounded, size: 14),
                                  label: Text(_formatTime(_normalEventTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Apply Reminder Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
