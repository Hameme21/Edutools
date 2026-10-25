import 'package:flutter/material.dart';
import '../../models/academic_notice.dart';

class AddNoticeDialog extends StatefulWidget {
  final Function(AcademicNotice) onSave;

  const AddNoticeDialog({super.key, required this.onSave});

  @override
  State<AddNoticeDialog> createState() => _AddNoticeDialogState();
}

class _AddNoticeDialogState extends State<AddNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  NoticeCategory _category = NoticeCategory.semesterFee;
  NoticePriority _priority = NoticePriority.high;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isHoliday = false;
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day + 1);
    _endDate = DateTime(now.year, now.month, now.day + 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final notice = AcademicNotice(
        id: 'NOT-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        isHoliday: _isHoliday || _category == NoticeCategory.holiday,
        priority: _priority,
        reminderEnabled: _reminderEnabled,
      );
      widget.onSave(notice);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Academic Notice',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
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
                const SizedBox(height: 16),

                // Category selector
                DropdownButtonFormField<NoticeCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: NoticeCategory.values.map((cat) {
                    final n = AcademicNotice(
                      id: '',
                      title: '',
                      description: '',
                      startDate: DateTime.now(),
                      endDate: DateTime.now(),
                      category: cat,
                    );
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(n.categoryIcon, color: n.categoryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(n.categoryName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _category = val;
                        if (val == NoticeCategory.holiday) {
                          _isHoliday = true;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Notice Title',
                    hintText: 'e.g. Semester Fee Last Date or Midterm Exam',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Additional details or instructions',
                  ),
                ),
                const SizedBox(height: 12),

                // Dates selector
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                '${_endDate.month}/${_endDate.day}/${_endDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Priority
                DropdownButtonFormField<NoticePriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority Level'),
                  items: NoticePriority.values.map((prio) {
                    return DropdownMenuItem(
                      value: prio,
                      child: Text(prio.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
                const SizedBox(height: 12),

                // Is Holiday checkbox & Holiday note
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as Academic Holiday (No Classes)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Cancels classes and class notifications on these dates', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  value: _isHoliday || _category == NoticeCategory.holiday,
                  onChanged: _category == NoticeCategory.holiday
                      ? null
                      : (val) {
                          setState(() => _isHoliday = val ?? false);
                        },
                ),

                // Reminder switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Push alerts before deadline or event', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  value: _reminderEnabled,
                  onChanged: (val) => setState(() => _reminderEnabled = val),
                ),
                const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Notice'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
