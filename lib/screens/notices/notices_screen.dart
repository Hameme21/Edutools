import 'package:flutter/material.dart';
import '../../state/calendar_state.dart';
import '../../models/academic_notice.dart';
import 'notice_card_widget.dart';
import 'add_notice_dialog.dart';

import '../reminders/notice_reminder_dialog.dart';

class NoticesScreen extends StatefulWidget {
  final CalendarState state;

  const NoticesScreen({super.key, required this.state});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _openNoticeReminderDialog(AcademicNotice notice) {
    showDialog(
      context: context,
      builder: (ctx) => NoticeReminderDialog(
        notice: notice,
        defaultSettings: widget.state.reminderSettings,
        onSave: ({
          required reminderTime,
          required dayBefore,
          required applyToAll,
          required enabled,
        }) {
          widget.state.customizeNoticeReminder(
            notice: notice,
            reminderTime: reminderTime,
            dayBefore: dayBefore,
            applyToAll: applyToAll,
            enabled: enabled,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                applyToAll
                    ? (notice.isHoliday ? 'Updated reminder for all holidays!' : 'Updated reminder for all ${notice.categoryName.toLowerCase()} events!')
                    : 'Updated reminder for "${notice.title}"!',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddNoticeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddNoticeDialog(
        onSave: (notice) {
          widget.state.addNotice(notice);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notice "${notice.title}" added successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notices = widget.state.upcomingNotices;
    final activeFilter = widget.state.selectedNoticeFilter;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => widget.state.setNoticeSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search holidays, fees, exams...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              widget.state.setNoticeSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Notices',
                        isSelected: activeFilter == null,
                        onSelected: () => widget.state.setNoticeFilter(null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '🎉 Holidays',
                        isSelected: activeFilter == NoticeCategory.holiday,
                        onSelected: () => widget.state.setNoticeFilter(NoticeCategory.holiday),
                        accentColor: const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '💳 Semester Fees',
                        isSelected: activeFilter == NoticeCategory.semesterFee,
                        onSelected: () => widget.state.setNoticeFilter(NoticeCategory.semesterFee),
                        accentColor: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '📝 Exams',
                        isSelected: activeFilter == NoticeCategory.exam,
                        onSelected: () => widget.state.setNoticeFilter(NoticeCategory.exam),
                        accentColor: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '📋 Administrative',
                        isSelected: activeFilter == NoticeCategory.administrative,
                        onSelected: () => widget.state.setNoticeFilter(NoticeCategory.administrative),
                        accentColor: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '🎪 Events',
                        isSelected: activeFilter == NoticeCategory.event,
                        onSelected: () => widget.state.setNoticeFilter(NoticeCategory.event),
                        accentColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List of Notices
          Expanded(
            child: notices.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notices.length,
                    itemBuilder: (ctx, index) {
                      final notice = notices[index];
                      return NoticeCardWidget(
                        notice: notice,
                        onToggleReminder: () => _openNoticeReminderDialog(notice),
                        onDelete: () => _confirmDeleteNotice(notice),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddNoticeDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Notice'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? accentColor,
  }) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : (accentColor ?? Colors.grey[700]),
      ),
      backgroundColor: Colors.transparent,
      selectedColor: color,
      side: BorderSide(
        color: isSelected ? color : (accentColor?.withValues(alpha: 0.4) ?? Colors.grey.withValues(alpha: 0.3)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Notices Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your filter query, load sample data, or add a new academic notice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openAddNoticeDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add First Notice'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteNotice(AcademicNotice notice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notice?'),
        content: Text('Are you sure you want to delete "${notice.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.state.deleteNotice(notice.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notice deleted.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
