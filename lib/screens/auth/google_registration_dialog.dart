import 'package:flutter/material.dart';
import '../../models/departments.dart';
import '../../services/api_service.dart';

class GoogleRegistrationDialog extends StatefulWidget {
  final String idToken;
  final String email;
  final String displayName;
  final ApiService? apiService;
  const GoogleRegistrationDialog(
      {super.key,
      required this.idToken,
      required this.email,
      required this.displayName,
      this.apiService});
  @override
  State<GoogleRegistrationDialog> createState() =>
      _GoogleRegistrationDialogState();
}

class _GoogleRegistrationDialogState extends State<GoogleRegistrationDialog> {
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _department;
  String? _error;
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await (widget.apiService ?? ApiService())
          .googleSession(widget.idToken, profile: {
        'fullName': _name.text.trim(),
        'studentId': _studentId.text.trim(),
        'department': _department,
      });
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Text('Complete registration'),
        content: SizedBox(
            width: 400,
            child: Form(
                key: _formKey,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Add your student details to get started.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.verified_user_outlined, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(widget.email,
                                  style:
                                      Theme.of(context).textTheme.bodySmall)),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                          controller: _name,
                          enabled: !_saving,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter your full name.'
                                  : null,
                          decoration: const InputDecoration(
                              labelText: 'Full name',
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _studentId,
                          enabled: !_saving,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter your student ID.'
                                  : null,
                          decoration: const InputDecoration(
                              labelText: 'Student ID',
                              hintText: 'e.g. 011251234',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                          initialValue: _department,
                          isExpanded: true,
                          hint: const Text('Select department'),
                          validator: (value) =>
                              value == null ? 'Select your department.' : null,
                          decoration: const InputDecoration(
                              labelText: 'Department',
                              prefixIcon: Icon(Icons.school_outlined),
                              border: OutlineInputBorder()),
                          items: departments
                              .map((d) =>
                                  DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _department = value)),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                    ]))),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
              child: Text(_saving ? 'Saving…' : 'Create account'))
        ],
      );
}
