import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TuitionCalculatorSheet extends StatefulWidget {
  const TuitionCalculatorSheet({super.key});

  @override
  State<TuitionCalculatorSheet> createState() => _TuitionCalculatorSheetState();
}

class _TuitionCalculatorSheetState extends State<TuitionCalculatorSheet> {
  String _department = 'cse';
  final TextEditingController _creditsController = TextEditingController(text: '12');
  final TextEditingController _waiverController = TextEditingController(text: '0');
  int _installments = 3;
  Map<String, dynamic>? _result;

  static const _rates = {
    'cse': {'perCredit': 7750, 'labFee': 3000, 'devFee': 5000, 'regFee': 1500, 'label': 'CSE / EEE / CE'},
    'bba': {'perCredit': 6250, 'labFee': 0, 'devFee': 5000, 'regFee': 1500, 'label': 'BBA / Economics'},
    'pharmacy': {'perCredit': 7000, 'labFee': 4000, 'devFee': 5000, 'regFee': 1500, 'label': 'Pharmacy'},
  };

  @override
  void dispose() {
    _creditsController.dispose();
    _waiverController.dispose();
    super.dispose();
  }

  String _formatTaka(int amount) => '৳ ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)(?!\d))'), (m) => '${m[1]},')}';

  void _calculate() {
    final rates = _rates[_department]!;
    final credits = int.tryParse(_creditsController.text) ?? 0;
    final waiver = double.tryParse(_waiverController.text) ?? 0;
    final perCredit = rates['perCredit'] as int;
    final labFee = rates['labFee'] as int;
    final devFee = rates['devFee'] as int;
    final regFee = rates['regFee'] as int;

    final tuitionBase = credits * perCredit;
    final waiverAmount = (tuitionBase * waiver / 100).round();
    final tuitionAfterWaiver = tuitionBase - waiverAmount;
    final totalFees = tuitionAfterWaiver + labFee + devFee + regFee;
    final perInstallment = (totalFees / _installments).ceil();

    setState(() {
      _result = {
        'credits': credits,
        'perCredit': perCredit,
        'tuitionBase': tuitionBase,
        'waiver': waiver,
        'waiverAmount': waiverAmount,
        'labFee': labFee,
        'devFee': devFee,
        'regFee': regFee,
        'total': totalFees,
        'installments': _installments,
        'perInstallment': perInstallment,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.holidayColor, size: 20),
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
                        'UIU rate structure',
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

          // Form
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
              shrinkWrap: true,
              children: [
                // Department
                _buildLabel('Department', isDark),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _department,
                      isExpanded: true,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: _rates.entries.map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value['label'] as String),
                      )).toList(),
                      onChanged: (v) => setState(() { _department = v!; _result = null; }),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Credits + Waiver
                Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Credits This Semester', isDark),
                        const SizedBox(height: 4),
                        _buildInput(_creditsController, 'e.g. 12', isDark),
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tuition Waiver (%)', isDark),
                        const SizedBox(height: 4),
                        _buildInput(_waiverController, '0', isDark),
                      ],
                    )),
                  ],
                ),

                const SizedBox(height: 12),

                // Installments
                _buildLabel('Installments', isDark),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _installments,
                      isExpanded: true,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3 Installments')),
                        DropdownMenuItem(value: 2, child: Text('2 Installments')),
                        DropdownMenuItem(value: 1, child: Text('Full Payment')),
                      ],
                      onChanged: (v) => setState(() { _installments = v!; _result = null; }),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Calculate button
                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_rounded, size: 16),
                  label: const Text('Calculate Tuition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                // Result breakdown
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _breakdownRow(
                          'Tuition (${_result!['credits']} cr × ${_formatTaka(_result!['perCredit'])})',
                          _formatTaka(_result!['tuitionBase']),
                          isDark,
                        ),
                        if ((_result!['waiver'] as double) > 0)
                          _breakdownRow(
                            'Waiver (${(_result!['waiver'] as double).toStringAsFixed(0)}%)',
                            '- ${_formatTaka(_result!['waiverAmount'])}',
                            isDark,
                            valueColor: AppTheme.accentColor,
                          ),
                        if ((_result!['labFee'] as int) > 0)
                          _breakdownRow('Lab Fee', _formatTaka(_result!['labFee']), isDark),
                        _breakdownRow('Development Fee', _formatTaka(_result!['devFee']), isDark),
                        _breakdownRow('Registration Fee', _formatTaka(_result!['regFee']), isDark),
                        // Total row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x1A3B82F6),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Due', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              Text(_formatTaka(_result!['total']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_installments > 1) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Per Installment ($_installments×)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                          Text(
                            _formatTaka(_result!['perInstallment']),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildInput(TextEditingController controller, String hint, bool isDark) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}
