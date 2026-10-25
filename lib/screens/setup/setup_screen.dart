import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../state/calendar_state.dart';
import '../../models/class_schedule.dart';
import '../../services/sample_data_service.dart';
import '../../services/file_parser_service.dart';
import 'file_import_card.dart';
import 'manual_class_dialog.dart';
import 'routine_date_config_dialog.dart';
import '../reminders/class_reminder_dialog.dart';

class SetupScreen extends StatefulWidget {
  final CalendarState state;

  const SetupScreen({super.key, required this.state});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  void _openAddClassDialog([ClassSchedule? initialClass]) {
    showDialog(
      context: context,
      builder: (ctx) => ManualClassDialog(
        initialClass: initialClass,
        onSave: (cls) {
          if (initialClass == null) {
            widget.state.addClass(cls);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Class "${cls.subject}" added!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            widget.state.updateClass(cls);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Class "${cls.subject}" updated!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _openRoutineDateConfigDialog({bool isAfterUpload = false}) {
    showDialog(
      context: context,
      builder: (ctx) => RoutineDateConfigDialog(
        state: widget.state,
        isAfterUpload: isAfterUpload,
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classes = widget.state.classes;
    final notices = widget.state.notices;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Holiday rule intelligence banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A).withValues(alpha: 0.4), const Color(0xFF0F172A)]
                    : [const Color(0xFFDBEAFE), const Color(0xFFEFF6FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Holiday Conflict Auto-Resolver Active',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EduCal automatically cross-references your Class Routine with the official 2026 Academic Calendar. On official holidays (e.g. Independence Day, Eid, Bangla New Year), classes are automatically cancelled and reminders silenced.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Official Academic Calendar Status Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final content = [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Official 2026 Academic Calendar',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${notices.length} milestones loaded (Holidays, Fee deadlines, Exams)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isNarrow) const SizedBox(height: 8),
                  Align(
                    alignment: isNarrow ? Alignment.centerRight : Alignment.center,
                    child: TextButton.icon(
                      onPressed: () {
                        widget.state.calendarService.setNotices(SampleDataService.getOfficialAcademicCalendar());
                        widget.state.reminderService.refreshReminders(referenceDate: widget.state.selectedDate);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Academic Calendar synced to official 2026 schedule!')),
                        );
                      },
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Sync', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: content,
                  );
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Official 2026 Academic Calendar',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${notices.length} milestones loaded (Holidays, Fee deadlines, Exams)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        widget.state.calendarService.setNotices(SampleDataService.getOfficialAcademicCalendar());
                        widget.state.reminderService.refreshReminders(referenceDate: widget.state.selectedDate);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Academic Calendar synced to official 2026 schedule!')),
                        );
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: const Text('Sync', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Quick preset action bar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  widget.state.loadSampleData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loaded sample routine and official calendar!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text('Load Demo Routine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _exportIcsDialog();
                },
                icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF3B82F6)),
                label: const Text('Export .ICS', style: TextStyle(color: Color(0xFF3B82F6))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _confirmClearClasses();
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFEF4444)),
                label: const Text('Clear', style: TextStyle(color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Class Routine File Import Card
          FileImportCard(
            title: 'Class Calendar / Routine File',
            description: 'Upload or paste your weekly timetable (Monday-Sunday recurring schedule). Supports JSON array and CSV format.',
            icon: Icons.schedule_rounded,
            themeColor: const Color(0xFF3B82F6),
            isClassRoutine: true,
            loadedCount: classes.length,
            onImport: (content) {
              final res = widget.state.importClassSchedule(content);
              if (!res.isSuccess) {
                throw Exception(res.errorMessage ?? 'Failed to parse class schedule.');
              }
              // Prompt user with detected auto-figured dates vs manual edit choice
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _openRoutineDateConfigDialog(isAfterUpload: true);
              });
            },
            onLoadSample: () {
              widget.state.loadSampleData();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loaded UIU CSE 2026 routine & academic calendar!'), behavior: SnackBarBehavior.floating),
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _openRoutineDateConfigDialog(isAfterUpload: true);
              });
            },
            onClear: () {
              widget.state.calendarService.setClasses([]);
              widget.state.clearRoutineDateRange();
              setState(() {});
            },
          ),
          const SizedBox(height: 8),

          // Active Routine Schedule Window Card
          _buildRoutineWindowCard(context, isDark),
          const SizedBox(height: 12),

          // Manage Class Routine List Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configured Class Routine',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${classes.length} recurring slots registered',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openAddClassDialog(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Class'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (classes.isEmpty)
            _buildEmptyClassesBox(isDark)
          else
            ..._buildClassesByDay(classes, isDark),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildClassesByDay(List<ClassSchedule> classes, bool isDark) {
    final Map<int, List<ClassSchedule>> grouped = {};
    for (var c in classes) {
      grouped.putIfAbsent(c.dayOfWeek, () => []).add(c);
    }

    final sortedDays = grouped.keys.toList()..sort();
    return sortedDays.map((day) {
      final dayClasses = grouped[day]!..sort((a, b) => a.startTime.compareTo(b.startTime));
      final dayName = dayClasses.first.dayName;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${dayClasses.length} ${dayClasses.length == 1 ? 'class' : 'classes'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...dayClasses.map((cls) => _buildClassRow(cls, isDark)),
          ],
        ),
      );
    }).toList();
  }

  void _openClassReminderDialog(ClassSchedule cls) {
    showDialog(
      context: context,
      builder: (ctx) => ClassReminderDialog(
        classSchedule: cls,
        defaultMinutes: widget.state.reminderSettings.classReminderMinutesBefore,
        onSave: ({
          required minutesBefore,
          required applyToAll,
          required enabled,
        }) {
          widget.state.customizeClassReminder(
            classSchedule: cls,
            minutesBefore: minutesBefore,
            applyToAll: applyToAll,
            enabled: enabled,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                applyToAll
                    ? 'Updated reminder for all course classes!'
                    : 'Updated reminder for ${cls.courseCode} (${cls.subject})!',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassRow(ClassSchedule cls, bool isDark) {
    final minutes = cls.customReminderMinutes ?? widget.state.reminderSettings.classReminderMinutesBefore;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: cls.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cls.courseCode}: ${cls.subject}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${cls.timeRangeFormatted} • ${cls.room} • ${cls.instructor}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              cls.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
              size: 16,
              color: cls.reminderEnabled ? const Color(0xFF3B82F6) : Colors.grey,
            ),
            tooltip: cls.reminderEnabled ? 'Reminder: ${minutes}m before' : 'Reminder off',
            onPressed: () => _openClassReminderDialog(cls),
            splashRadius: 16,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
            onPressed: () => _openAddClassDialog(cls),
            splashRadius: 16,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
            onPressed: () => widget.state.deleteClass(cls.id),
            splashRadius: 16,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClassesBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.calendar_today_outlined, size: 36, color: Colors.grey),
            SizedBox(height: 8),
            Text('No classes loaded in routine yet.', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Use the File Import above or click "Add Class" to build your schedule.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _exportIcsDialog() {
    final icsText = FileParserService.exportCalendarToIcs(widget.state.calendarService);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calendar_today_rounded, color: Color(0xFF3B82F6), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Exported .ICS Calendar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Holiday conflict logic applied: Classes on all holidays are excluded from this .ics schedule.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: SelectableText(
                    icsText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.35),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: icsText));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied .ICS calendar data to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy .ICS to Clipboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineWindowCard(BuildContext context, bool isDark) {
    final range = widget.state.routineRange;
    final isConfigured = range != null;
    final isAuto = widget.state.isRoutineAutoFigured;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAuto
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : const Color(0xFF3B82F6).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isAuto ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAuto ? Icons.auto_mode_rounded : Icons.edit_calendar_rounded,
                  color: isAuto ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Routine Active Dates',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isAuto ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isAuto ? '⚡ Auto' : '✏️ Custom',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isAuto ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isConfigured) ...[
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEMESTER BEGINS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      range.formattedStartDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLASSES CONCLUDE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      range.formattedEndDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              range.sourceDescription,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.grey[600],
                height: 1.3,
              ),
            ),
          ] else ...[
            Text(
              'No active date boundaries set. Classes will repeat indefinitely unless constrained to semester dates.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openRoutineDateConfigDialog(),
                icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                label: const Text('Edit Routine Dates'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  widget.state.autoApplyRoutineDates();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Auto-applied routine dates from Academic Calendar: ${widget.state.routineRange?.dateRangeFormatted ?? ""}'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF10B981)),
                label: const Text('Auto-Figure by App', style: TextStyle(color: Color(0xFF10B981))),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmClearClasses() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Class Routine?'),
        content: const Text('This will clear all loaded class timetable routines.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.state.calendarService.setClasses([]);
              widget.state.reminderService.refreshReminders(referenceDate: widget.state.selectedDate);
              Navigator.of(ctx).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class routines cleared.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
