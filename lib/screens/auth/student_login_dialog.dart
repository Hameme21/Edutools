import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/student_profile.dart';
import '../../state/calendar_state.dart';
import '../../widgets/educal_logo.dart';
import '../../services/api_service.dart';

class StudentLoginDialog extends StatefulWidget {
  final CalendarState state;

  const StudentLoginDialog({super.key, required this.state});

  @override
  State<StudentLoginDialog> createState() => _StudentLoginDialogState();
}

class _StudentLoginDialogState extends State<StudentLoginDialog> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();

  final _apiService = ApiService();

  bool _isRegisterMode = false;
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  int _secondsRemaining = 300;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.state.isLoggedIn && widget.state.currentStudent != null) {
      final s = widget.state.currentStudent!;
      _emailController.text = s.email;
      _fullNameController.text = s.fullName;
      _studentIdController.text = s.studentId;
      _departmentController.text = s.department;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _fullNameController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
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

  Future<void> _handleRequestOtp() async {
    final email = _emailController.text.trim().toLowerCase();

    if (!ApiService.isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    if (_isRegisterMode) {
      if (!ApiService.isUiuEmail(email)) {
        setState(() => _errorMessage = 'Registered email must end with uiu.ac.bd (e.g. student@bscse.uiu.ac.bd).');
        return;
      }
      if (_fullNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter your Full Name.');
        return;
      }
      if (_studentIdController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter your Student ID.');
        return;
      }
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _apiService.requestOtp(
        email,
        isRegistration: _isRegisterMode,
        fullName: _fullNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        department: _departmentController.text.trim(),
        semester: 'Spring 2026',
      );
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
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
      setState(() => _errorMessage = 'Please enter the complete 6-digit numeric OTP.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final res = await _apiService.verifyOtp(
        email,
        otp,
        fullName: _isRegisterMode ? _fullNameController.text.trim() : null,
        studentId: _isRegisterMode ? _studentIdController.text.trim() : null,
        department: _isRegisterMode ? _departmentController.text.trim() : null,
      );
      final studentJson = res['student'] as Map<String, dynamic>;

      final resolvedName = studentJson['fullName'] ??
          (_isRegisterMode && _fullNameController.text.trim().isNotEmpty
              ? _fullNameController.text.trim()
              : StudentProfile.formatNameFromEmail(email));
      final resolvedId = studentJson['studentId'] ??
          (_isRegisterMode && _studentIdController.text.trim().isNotEmpty
              ? _studentIdController.text.trim()
              : email.split('@').first.toUpperCase());
      final resolvedDept = studentJson['department'] ??
          (_isRegisterMode && _departmentController.text.trim().isNotEmpty
              ? _departmentController.text.trim()
              : 'Computer Science & Engineering');

      widget.state.loginStudent(
        email: email,
        studentId: resolvedId,
        fullName: resolvedName,
        department: resolvedDept,
      );
      await widget.state.syncWithGoogleDrive();

      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegisterMode
                ? 'Registered and logged in as $email • Synced with UIU Cloud!'
                : 'Logged in as $email • Synced with UIU Cloud & Web!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isLoading = true);
    await widget.state.syncWithGoogleDrive();
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UIU Schedule & notices successfully synchronized with Google Drive!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final student = widget.state.currentStudent;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with EduCal Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EduCalLogo(size: 32, isDark: isDark),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (student != null) ...[
                // Logged in Student Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEA580C),
                            child: Text(
                              student.avatarLetter,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student.email,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700]),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${student.studentId} • ${student.department}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEA580C)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 16),
                              SizedBox(width: 6),
                              Text('UIU Cloud & Web Synced', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(
                            _formatTime(student.lastSyncTime),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action buttons when logged in
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSync,
                        icon: _isLoading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Sync Now'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        widget.state.logoutStudent();
                        setState(() {
                          _isOtpSent = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out of UIU student portal.')),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
                      label: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Auth & Registration Tabs
                if (!_isOtpSent)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() {
                              _isRegisterMode = false;
                              _errorMessage = null;
                            }),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isRegisterMode
                                    ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isRegisterMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'UIU Sign In',
                                  style: TextStyle(
                                    fontWeight: !_isRegisterMode ? FontWeight.bold : FontWeight.w500,
                                    color: !_isRegisterMode ? const Color(0xFFEA580C) : (isDark ? Colors.white70 : Colors.grey[700]),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() {
                              _isRegisterMode = true;
                              _errorMessage = null;
                            }),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRegisterMode
                                    ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isRegisterMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'UIU Register',
                                  style: TextStyle(
                                    fontWeight: _isRegisterMode ? FontWeight.bold : FontWeight.w500,
                                    color: _isRegisterMode ? const Color(0xFFEA580C) : (isDark ? Colors.white70 : Colors.grey[700]),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOtpSent
                          ? 'Verification Code'
                          : (_isRegisterMode ? 'UIU Student Registration' : 'UIU Student Portal Sign In'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isOtpSent
                          ? 'Enter the 6-digit OTP code sent from hamimasir5@gmail.com.'
                          : (_isRegisterMode
                              ? 'Registration is strictly for UIU student emails ending with uiu.ac.bd.'
                              : 'Sign in to access synchronized UIU classes, notices, and Google Drive.'),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    if (!_isOtpSent) ...[
                      if (_isRegisterMode) ...[
                        TextField(
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                            hintText: 'Enter your full name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _studentIdController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Student ID *',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            hintText: 'e.g. 0112510370',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _departmentController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Department / Major',
                            prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                            hintText: 'e.g. Computer Science & Engineering',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'UIU Student Email (*.uiu.ac.bd) *',
                          prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                          hintText: 'username@bscse.uiu.ac.bd',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_outlined, size: 14, color: Color(0xFFEA580C)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _isRegisterMode
                                  ? 'Registered email must end with uiu.ac.bd. OTP sent from hamimasir5@gmail.com.'
                                  : 'Supports UIU student emails (*.uiu.ac.bd). OTP sent from hamimasir5@gmail.com.',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Code sent to ${_emailController.text}:',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isOtpSent = false),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            child: const Text('Edit Email', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10.0,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          hintText: '••••••',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: _secondsRemaining > 30 ? primaryColor : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Expires in: ${_formatTimer(_secondsRemaining)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _secondsRemaining > 30 ? primaryColor : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          if (_secondsRemaining == 0)
                            TextButton(
                              onPressed: _handleRequestOtp,
                              child: const Text('Resend Code', style: TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.mark_email_read_outlined, size: 18, color: Color(0xFFEA580C)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A 6-digit verification code has been dispatched from hamimasir5@gmail.com to ${_emailController.text}. Please check your inbox or spam folder.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: isDark ? Colors.white70 : const Color(0xFF9A3412),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : (_isOtpSent ? _handleVerifyOtp : _handleRequestOtp),
                        icon: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_isOtpSent
                                ? Icons.verified_user_rounded
                                : (_isRegisterMode ? Icons.person_add_rounded : Icons.login_rounded)),
                        label: Text(_isOtpSent
                            ? (_isRegisterMode ? 'Verify & Complete UIU Registration' : 'Verify & Sign In')
                            : (_isRegisterMode ? 'Register & Send 6-Digit OTP' : 'Send 6-Digit OTP')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }
}
