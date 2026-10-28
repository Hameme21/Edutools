import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TuitionCalculatorSheet extends StatefulWidget {
  const TuitionCalculatorSheet({super.key});

  @override
  State<TuitionCalculatorSheet> createState() => _TuitionCalculatorSheetState();
}

class _TuitionCalculatorSheetState extends State<TuitionCalculatorSheet> {
  final _regularCreditsCtrl = TextEditingController(text: '12');
  final _retakeCreditsCtrl = TextEditingController(text: '0');
  final _costPerCreditCtrl = TextEditingController(text: '6500');
  final _trimesterFeeCtrl = TextEditingController(text: '6500');

  double _waiverPct = 0;
  double _scholarshipPct = 0;

  Map<String, dynamic>? _result;

  bool _showPlanner = false;
  int _plannerTrimesters = 1;

  @override
  void dispose() {
    _regularCreditsCtrl.dispose();
    _retakeCreditsCtrl.dispose();
    _costPerCreditCtrl.dispose();
    _trimesterFeeCtrl.dispose();
    super.dispose();
  }

  String _formatTaka(int amount) =>
      '৳ ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)(?!\d))'), (m) => '${m[1]},')}';

  Map<String, dynamic> _computeTuition() {
    final regularCredits = int.tryParse(_regularCreditsCtrl.text) ?? 0;
    final retakeCredits = int.tryParse(_retakeCreditsCtrl.text) ?? 0;
    final costPerCredit = int.tryParse(_costPerCreditCtrl.text) ?? 6500;
    final trimesterFee = int.tryParse(_trimesterFeeCtrl.text) ?? 6500;

    final regularTuition = regularCredits * costPerCredit;
    final retakeFee = (retakeCredits * costPerCredit * 0.50).round();

    // Determine which discount is higher — apply it first
    final higherPct =
        _waiverPct >= _scholarshipPct ? _waiverPct : _scholarshipPct;
    final lowerPct =
        _waiverPct >= _scholarshipPct ? _scholarshipPct : _waiverPct;
    final higherIsWaiver = _waiverPct >= _scholarshipPct;

    final firstDiscount = (regularTuition * higherPct / 100).round();
    final afterFirst = regularTuition - firstDiscount;
    final secondDiscount = (afterFirst * lowerPct / 100).round();
    final regularAfterDiscounts = afterFirst - secondDiscount;

    final waiverDiscount = higherIsWaiver ? firstDiscount : secondDiscount;
    final scholarshipDiscount = higherIsWaiver ? secondDiscount : firstDiscount;

    final total = regularAfterDiscounts + retakeFee + trimesterFee;

    final inst1 = (total * 0.40).ceil();
    final inst2 = (total * 0.30).ceil();
    final inst3 = total - inst1 - inst2;

    return {
      'regularCredits': regularCredits,
      'retakeCredits': retakeCredits,
      'costPerCredit': costPerCredit,
      'regularTuition': regularTuition,
      'retakeFee': retakeFee,
      'waiverPct': _waiverPct,
      'scholarshipPct': _scholarshipPct,
      'waiverDiscount': waiverDiscount,
      'scholarshipDiscount': scholarshipDiscount,
      'trimesterFee': trimesterFee,
      'total': total,
      'inst1': inst1,
      'inst2': inst2,
      'inst3': inst3,
    };
  }

  void _calculate() {
    setState(() {
      _result = _computeTuition();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0x1AEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: AppTheme.holidayColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tuition Fee Calculator',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'UIU trimester fee structure with retake support',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

          // Form + Results
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
              shrinkWrap: true,
              children: [
                // Credits row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Regular Credits', isDark),
                          const SizedBox(height: 4),
                          _buildInput(_regularCreditsCtrl, '12', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Retake Credits', isDark),
                          const SizedBox(height: 4),
                          _buildInput(_retakeCreditsCtrl, '0', isDark),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cost per credit + Trimester fee
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Cost / Credit (৳)', isDark),
                          const SizedBox(height: 4),
                          _buildInput(_costPerCreditCtrl, '6500', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Trimester Fee (৳)', isDark),
                          const SizedBox(height: 4),
                          _buildInput(_trimesterFeeCtrl, '6500', isDark),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Waiver + Scholarship
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('General Waiver', isDark),
                          const SizedBox(height: 4),
                          _buildDropdown<double>(
                            value: _waiverPct,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('None')),
                              DropdownMenuItem(value: 25, child: Text('25%')),
                              DropdownMenuItem(value: 50, child: Text('50%')),
                            ],
                            onChanged: (v) =>
                                setState(() { _waiverPct = v!; _result = null; }),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Scholarship', isDark),
                          const SizedBox(height: 4),
                          _buildDropdown<double>(
                            value: _scholarshipPct,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('None')),
                              DropdownMenuItem(value: 25, child: Text('25%')),
                              DropdownMenuItem(value: 50, child: Text('50%')),
                              DropdownMenuItem(value: 100, child: Text('100%')),
                            ],
                            onChanged: (v) =>
                                setState(() { _scholarshipPct = v!; _result = null; }),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Retake info chip
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 15, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Retake credits are charged at 50% rate and are not affected by waiver or scholarship.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Calculate
                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_rounded, size: 16),
                  label: const Text('Calculate Tuition',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                // Results
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _buildBreakdownCard(isDark),
                  const SizedBox(height: 10),
                  _buildInstallmentCard(isDark),
                  const SizedBox(height: 14),
                  _buildMultiTrimesterPlanner(isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Breakdown card ----------

  Widget _buildBreakdownCard(bool isDark) {
    final r = _result!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _breakdownRow(
            'Regular Tuition (${r['regularCredits']} cr × ${_formatTaka(r['costPerCredit'])})',
            _formatTaka(r['regularTuition']),
            isDark,
          ),
          if ((r['waiverDiscount'] as int) > 0)
            _breakdownRow(
              'General Waiver (${(r['waiverPct'] as double).toStringAsFixed(0)}%)',
              '- ${_formatTaka(r['waiverDiscount'])}',
              isDark,
              valueColor: AppTheme.accentColor,
            ),
          if ((r['scholarshipDiscount'] as int) > 0)
            _breakdownRow(
              'Scholarship (${(r['scholarshipPct'] as double).toStringAsFixed(0)}%)',
              '- ${_formatTaka(r['scholarshipDiscount'])}',
              isDark,
              valueColor: AppTheme.accentColor,
            ),
          if ((r['retakeFee'] as int) > 0)
            _breakdownRow(
              'Retake Fee (${r['retakeCredits']} cr × 50%)',
              _formatTaka(r['retakeFee']),
              isDark,
              valueColor: const Color(0xFFF59E0B),
            ),
          _breakdownRow(
            'Trimester Fee',
            _formatTaka(r['trimesterFee']),
            isDark,
          ),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0x1A3B82F6),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Due',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                Text(_formatTaka(r['total']),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Installment card ----------

  Widget _buildInstallmentCard(bool isDark) {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSTALLMENT PLAN (40 / 30 / 30)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          _installmentRow('1st Installment (40%)', r['inst1'] as int, isDark),
          const SizedBox(height: 6),
          _installmentRow('2nd Installment (30%)', r['inst2'] as int, isDark),
          const SizedBox(height: 6),
          _installmentRow('3rd Installment (30%)', r['inst3'] as int, isDark),
        ],
      ),
    );
  }

  Widget _installmentRow(String label, int amount, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155)),
        ),
        Text(
          _formatTaka(amount),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryLight),
        ),
      ],
    );
  }

  // ---------- Multi-trimester planner ----------

  Widget _buildMultiTrimesterPlanner(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showPlanner = !_showPlanner),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded,
                      size: 18, color: AppTheme.examColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Multi-Trimester Planner',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(
                    _showPlanner
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (_showPlanner) ...[
            Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Number of Trimesters', isDark),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(8, (i) {
                      final n = i + 1;
                      final selected = n == _plannerTrimesters;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _plannerTrimesters = n),
                          child: Container(
                            margin: EdgeInsets.only(right: i < 7 ? 4 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.examColor
                                  : (isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.examColor
                                    : (isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$n',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white54
                                          : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  _buildPlannerResults(isDark),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlannerResults(bool isDark) {
    final perTrimester = _result!['total'] as int;
    final totalProjected = perTrimester * _plannerTrimesters;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.examColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.examColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Per Trimester',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              Text(_formatTaka(perTrimester),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($_plannerTrimesters trimester${_plannerTrimesters > 1 ? 's' : ''})',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              Text(
                _formatTaka(totalProjected),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.examColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Installments',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              Text(
                '${_plannerTrimesters * 3} payments',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Shared helpers ----------

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        color: isDark ? Colors.white54 : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller, String hint, bool isDark) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF0F172A)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value, bool isDark,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF334155)))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }
}
