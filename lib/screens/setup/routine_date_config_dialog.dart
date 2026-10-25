import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/routine_date_range.dart';
import '../../state/calendar_state.dart';

class RoutineDateConfigDialog extends StatefulWidget {
  final CalendarState state;
  final RoutineDateRange? initialDetectedRange;
  final bool isAfterUpload;

  const RoutineDateConfigDialog({
    super.key,
    required this.state,
    this.initialDetectedRange,
    this.isAfterUpload = false,
  });

  @override
  State<RoutineDateConfigDialog> createState() => _RoutineDateConfigDialogState();
}

class _RoutineDateConfigDialogState extends State<RoutineDateConfigDialog> {
  late RoutineDateRange _detectedRange;
  late DateTime _customStartDate;
  late DateTime _customEndDate;
  bool _isEditingCustom = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detectedRange = widget.initialDetectedRange ??
        widget.state.autoFigureRoutineDates();

    final currentActive = widget.state.routineRange;
    if (currentActive != null && !currentActive.isAutoFigured) {
      _customStartDate = currentActive.startDate;
      _customEndDate = currentActive.endDate;
      _isEditingCustom = true;
    } else {
      _customStartDate = _detectedRange.startDate;
      _customEndDate = _detectedRange.endDate;
      _isEditingCustom = false;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _customStartDate : _customEndDate;
    final first = DateTime(2025, 1, 1);
    final last = DateTime(2030, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isStart ? 'Select Class Begin Date' : 'Select Routine Ending Date',
    );

    if (picked != null) {
      setState(() {
        _errorMessage = null;
        if (isStart) {
          _customStartDate = picked;
          if (_customEndDate.isBefore(_customStartDate)) {
            _customEndDate = _customStartDate.add(const Duration(days: 90));
          }
        } else {
          _customEndDate = picked;
        }
      });
    }
  }

  void _applyAutoFigured() {
    widget.state.setRoutineDateRange(
      startDate: _detectedRange.startDate,
      endDate: _detectedRange.endDate,
      isAutoFigured: true,
      title: _detectedRange.title,
      sourceDescription: _detectedRange.sourceDescription,
      classesSuspendedDate: _detectedRange.classesSuspendedDate,
      finalExamDate: _detectedRange.finalExamDate,
      nextSemesterBeginDate: _detectedRange.nextSemesterBeginDate,
    );

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied auto-figured routine window: ${_detectedRange.dateRangeFormatted}',
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyCustomDates() {
    setState(() => _errorMessage = null);
    if (_customEndDate.isBefore(_customStartDate)) {
      setState(() => _errorMessage = 'Routine ending date cannot be before class begin date.');
      return;
    }

    widget.state.setRoutineDateRange(
      startDate: _customStartDate,
      endDate: _customEndDate,
      isAutoFigured: false,
      title: 'Custom Routine Window',
      sourceDescription:
          'Customized by user (${DateFormat('MMM d').format(_customStartDate)} - ${DateFormat('MMM d, yyyy').format(_customEndDate)})',
      classesSuspendedDate: _detectedRange.classesSuspendedDate,
      finalExamDate: _detectedRange.finalExamDate,
      nextSemesterBeginDate: _detectedRange.nextSemesterBeginDate,
    );

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied custom routine window: ${DateFormat('MMM d, yyyy').format(_customStartDate)} - ${DateFormat('MMM d, yyyy').format(_customEndDate)}',
        ),
        backgroundColor: const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.date_range_rounded, color: Color(0xFF3B82F6), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isAfterUpload
                              ? 'Routine Schedule Window'
                              : 'Configure Routine Dates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Set class begin date & routine end date',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detected notice context badge
              if (_detectedRange.isCurrentDatePastSuspension)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Current date is after classes were suspended for this trimester. EduCal auto-figured the full routine active dates from semester begin until classes were suspended.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Auto-Figured Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: !_isEditingCustom
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    width: !_isEditingCustom ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: const Color(0xFF10B981), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Auto-Figured Window',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        if (!_isEditingCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CLASSES BEGIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _detectedRange.formattedStartDate,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[400]),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ROUTINE ENDS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _detectedRange.formattedEndDate,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _detectedRange.sourceDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _applyAutoFigured,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('Use Auto-Figured Dates'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Manual Edit Section Toggle / Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isEditingCustom
                        ? const Color(0xFF3B82F6)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: _isEditingCustom ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_calendar_rounded, color: const Color(0xFF3B82F6), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Edit Dates Manually',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isEditingCustom,
                          activeColor: const Color(0xFF3B82F6),
                          onChanged: (val) {
                            setState(() => _isEditingCustom = val);
                          },
                        ),
                      ],
                    ),
                    if (_isEditingCustom) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Customize your class start and conclusion dates directly:',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickDate(isStart: true),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CLASS BEGINS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(_customStartDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickDate(isStart: false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ROUTINE ENDS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(_customEndDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _applyCustomDates,
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Save Custom Dates'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Close / Dismiss
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
