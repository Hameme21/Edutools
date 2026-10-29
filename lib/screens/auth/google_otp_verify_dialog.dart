import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../state/calendar_state.dart';
import 'edit_profile_dialog.dart';

class GoogleOtpVerifyDialog extends StatefulWidget {
  final String email;
  final String displayName;
  final CalendarState state;

  const GoogleOtpVerifyDialog({
    super.key,
    required this.email,
    required this.displayName,
    required this.state,
  });

  @override
  State<GoogleOtpVerifyDialog> createState() => _GoogleOtpVerifyDialogState();
}

class _GoogleOtpVerifyDialogState extends State<GoogleOtpVerifyDialog> {
  final _otpCtrl = TextEditingController();
  final _apiService = ApiService();
  bool _sending = true;
  bool _verifying = false;
  String? _error;
  int _secondsLeft = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() { _sending = true; _error = null; });
    try {
      await _apiService.requestOtp(widget.email);
      _startTimer();
    } catch (e) {
      setState(() => _error = 'Failed to send code. Tap Resend.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }

    setState(() { _verifying = true; _error = null; });

    try {
      await _apiService.verifyOtp(widget.email, otp);
      _timer?.cancel();

      if (!mounted) return;

      widget.state.loginStudent(
        email: widget.email,
        studentId: widget.email.split('@').first.toUpperCase(),
        fullName: widget.displayName,
      );

      Navigator.of(context).pop(true);

      showDialog(
        context: context,
        builder: (ctx) => EditProfileDialog(state: widget.state),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    final timerText = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mark_email_read_rounded, size: 20, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        'Verify Email',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a 6-digit code to:',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check your Inbox and Spam/Junk folder.\nSent from hamimasir5@gmail.com',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _otpCtrl,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _secondsLeft > 0 ? 'Expires in: $timerText' : 'Code expired',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  ),
                  if (_secondsLeft <= 0 || !_sending)
                    TextButton(
                      onPressed: _sending ? null : _sendOtp,
                      child: Text(
                        'Resend',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sending ? Colors.grey : const Color(0xFF2563EB)),
                      ),
                    ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _verifying ? null : _verify,
                  icon: _verifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(_verifying ? 'Verifying...' : 'Verify & Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
