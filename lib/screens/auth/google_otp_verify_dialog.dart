import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../state/calendar_state.dart';
import 'edit_profile_dialog.dart';

/// Dialog shown after Google Sign-In to verify email ownership via a link.
/// Replaces the old OTP-based verification dialog.
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
  final _apiService = ApiService();
  bool _sending = true;
  bool _verified = false;
  String? _error;
  Timer? _pollTimer;
  int _secondsLeft = 900; // 15 minutes
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _sendVerificationLink();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsLeft = 900;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final result = await _apiService.checkEmailVerification(widget.email);
        if (result['verified'] == true) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();

          // Store the auth token
          if (result['token'] != null) {
            _apiService.authToken = result['token'] as String;
          }

          if (!mounted) return;

          setState(() => _verified = true);

          // Login with the verified student data
          final studentJson = result['student'] as Map<String, dynamic>?;
          widget.state.loginStudent(
            email: widget.email,
            studentId: studentJson?['studentId'] ?? widget.email.split('@').first.toUpperCase(),
            fullName: studentJson?['fullName'] ?? widget.displayName,
          );

          // Small delay to show success state, then continue
          await Future.delayed(const Duration(milliseconds: 800));
          if (!mounted) return;

          Navigator.of(context).pop(true);

          showDialog(
            context: context,
            builder: (ctx) => EditProfileDialog(state: widget.state),
          );
        }
      } catch (_) {
        // Polling errors are silently ignored
      }
    });
  }

  Future<void> _sendVerificationLink() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _apiService.requestEmailVerification(
        widget.email,
        displayName: widget.displayName,
      );
      _startCountdown();
      _startPolling();
    } catch (e) {
      setState(() => _error = 'Failed to send verification email. Tap Resend.');
    } finally {
      if (mounted) setState(() => _sending = false);
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
                      Icon(
                        _verified ? Icons.check_circle_rounded : Icons.mark_email_read_rounded,
                        size: 20,
                        color: _verified ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _verified ? 'Email Verified!' : 'Verify Email',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  if (!_verified)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(false),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_verified) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF10B981)),
                      SizedBox(height: 10),
                      Text(
                        'Your email has been verified successfully!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (_sending) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2.5),
                        SizedBox(height: 12),
                        Text(
                          'Sending verification email...',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'We sent a verification link to:',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Click the link in your email to verify.\nThis page will update automatically.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Waiting indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Waiting for verification...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _secondsLeft > 0 ? 'Expires in: $timerText' : 'Link expired',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                      ),
                      TextButton(
                        onPressed: _sending ? null : _sendVerificationLink,
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _sending ? Colors.grey : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
