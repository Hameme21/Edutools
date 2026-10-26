import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/student_profile.dart';
import '../../services/api_service.dart';

class UniversityAuthDialog extends StatefulWidget {
  final StudentProfile? currentProfile;
  final Function(StudentProfile) onAuthenticated;
  final VoidCallback? onLogout;

  const UniversityAuthDialog({
    super.key,
    this.currentProfile,
    required this.onAuthenticated,
    this.onLogout,
  });

  @override
  State<UniversityAuthDialog> createState() => _UniversityAuthDialogState();
}

class _UniversityAuthDialogState extends State<UniversityAuthDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  int _secondsRemaining = 300;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.currentProfile != null &&
        widget.currentProfile!.email != 'student@uiu.ac.bd' &&
        widget.currentProfile!.email != 'student@university.edu') {
      _emailController.text = widget.currentProfile!.email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 300;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _handlePasswordLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (!ApiService.isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() { _errorMessage = null; _isLoading = true; });

    try {
      final res = await _apiService.loginWithPassword(email, password);
      final studentJson = res['student'] as Map<String, dynamic>;
      final profile = StudentProfile(
        email: email,
        studentId: studentJson['studentId'] ?? email.split('@').first.toUpperCase(),
        fullName: studentJson['fullName'] ?? StudentProfile.formatNameFromEmail(email),
        department: studentJson['department'] ?? 'Computer Science & Engineering',
        semester: studentJson['semester'] ?? 'Spring 2026',
        isSynced: true,
        lastSyncTime: DateTime.now(),
      );

      widget.onAuthenticated(profile);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${profile.fullName}!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleRequestOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    setState(() { _errorMessage = null; _isLoading = true; });

    try {
      await _apiService.requestOtp(email);
      setState(() { _isOtpSent = true; _isLoading = false; });
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('6-digit code sent to $email!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP.');
      return;
    }

    setState(() { _errorMessage = null; _isLoading = true; });

    try {
      final res = await _apiService.verifyOtp(email, otp);
      final studentJson = res['student'] as Map<String, dynamic>;
      final profile = StudentProfile(
        email: email,
        studentId: studentJson['studentId'] ?? email.split('@').first.toUpperCase(),
        fullName: studentJson['fullName'] ?? StudentProfile.formatNameFromEmail(email),
        department: studentJson['department'] ?? 'Computer Science & Engineering',
        semester: studentJson['semester'] ?? 'Spring 2026',
        isSynced: true,
        lastSyncTime: DateTime.now(),
      );

      widget.onAuthenticated(profile);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authenticated as ${profile.email}!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.school_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'University Email Login',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Sign in with password or OTP',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),

              if (!_isOtpSent) ...[
                const Text('Enter your student email:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'username@bscse.uiu.ac.bd',
                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Enter 6-digit code sent to ${_emailController.text}:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isOtpSent = false),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('Change', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8.0, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: '------',
                    counterText: '',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.timer_outlined, size: 14, color: _secondsRemaining > 30 ? primaryColor : const Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(
                        'Expires in: ${_formatTimer(_secondsRemaining)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _secondsRemaining > 30 ? primaryColor : const Color(0xFFEF4444)),
                      ),
                    ]),
                    if (_secondsRemaining == 0)
                      TextButton(onPressed: _handleRequestOtp, child: const Text('Resend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.mark_email_read_outlined, size: 16, color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check your inbox & spam folder for the code from hamimasir5@gmail.com.',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
                  ]),
                ),
              ],
              const SizedBox(height: 18),

              if (!_isOtpSent) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePasswordLogin,
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In with Password'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500])),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleRequestOtp,
                    child: const Text('Send OTP Email Instead'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyOtp,
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verify Code'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
