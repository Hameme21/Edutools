import 'package:flutter/material.dart';
import '../../models/departments.dart';
import '../../services/api_service.dart';

class GoogleRegistrationDialog extends StatefulWidget {
  final String idToken;
  final String email;
  final String displayName;
  const GoogleRegistrationDialog({super.key, required this.idToken, required this.email, required this.displayName});
  @override
  State<GoogleRegistrationDialog> createState() => _GoogleRegistrationDialogState();
}

class _GoogleRegistrationDialogState extends State<GoogleRegistrationDialog> {
  late final _name = TextEditingController(text: widget.displayName);
  final _studentId = TextEditingController();
  String? _department;
  String? _error;
  bool _saving = false;
  @override
  void dispose() { _name.dispose(); _studentId.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _studentId.text.trim().isEmpty || _department == null) {
      setState(() => _error = 'Enter your name, student ID and department.'); return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final result = await ApiService().googleSession(widget.idToken, profile: {
        'fullName': _name.text.trim(), 'studentId': _studentId.text.trim(), 'department': _department,
      });
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Complete registration'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Google verified ${widget.email}. Complete your student details to continue.'),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
      TextField(controller: _studentId, decoration: const InputDecoration(labelText: 'Student ID')),
      DropdownButtonFormField<String>(initialValue: _department, decoration: const InputDecoration(labelText: 'Department'),
        items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
        onChanged: _saving ? null : (value) => setState(() => _department = value)),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
    ])),
    actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Register'))],
  );
}
