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
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();

  final _apiService = ApiService();

  bool _isRegisterMode = false;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  int _secondsRemaining = 300;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.state.isLoggedIn && widget.state.currentStudent != null) {
      final s = widget.state.currentStudent!;
      if (s.email != 'student@uiu.ac.bd' && s.email != 'student@university.edu') {
        _emailController.text = s.email;
        _fullNameController.text = s.fullName;
        _studentIdController.text = s.studentId;
        _departmentController.text = s.department;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final res = await _apiService.loginWithPassword(email, password);
      final studentJson = res['student'] as Map<String, dynamic>;

      widget.state.loginStudent(
        email: email,
        studentId: studentJson['studentId'] ?? email.split('@').first.toUpperCase(),
        fullName: studentJson['fullName'] ?? StudentProfile.formatNameFromEmail(email),
        department: studentJson['department'] ?? 'Computer Science & Engineering',
      );
      await widget.state.syncWithGoogleDrive();

      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${studentJson['fullName'] ?? email}!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
        if (msg.toLowerCase().contains('no account found') || msg.toLowerCase().contains('not registered')) {
          _isRegisterMode = true;
        }
      });
    }
  }

  Future<void> _handleRegisterOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (!ApiService.isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (!ApiService.isUiuEmail(email)) {
      setState(() => _errorMessage = 'Registration requires a UIU email (e.g. student@bscse.uiu.ac.bd).');
      return;
    }
    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (_studentIdController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your student ID.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _apiService.requestOtpWithPassword(
        email,
        password: password,
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
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
        if (msg.toLowerCase().contains('already registered')) {
          _isRegisterMode = false;
          _isOtpSent = false;
        }
      });
    }
  }

  Future<void> _handleSignInOtp() async {
    final email = _emailController.text.trim().toLowerCase();

    if (!ApiService.isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _apiService.requestOtp(email);
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
        if (msg.toLowerCase().contains('no account found') || msg.toLowerCase().contains('not registered')) {
          _isRegisterMode = true;
        }
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
                ? 'Registered and logged in as $email!'
                : 'Logged in as $email!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
        if (msg.toLowerCase().contains('already registered')) {
          _isRegisterMode = false;
          _isOtpSent = false;
        }
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
          content: Text('Schedule & notices synced successfully!'),
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
                _buildLoggedInView(isDark, student, primaryColor),
              ] else ...[
                _buildAuthView(isDark, primaryColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(bool isDark, StudentProfile student, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
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
                        Text(student.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(student.email, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700])),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${student.studentId} • ${student.department}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEA580C)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
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
                  const Row(children: [
                    Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 6),
                    Text('Cloud Synced', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ]),
                  Text(_formatTime(student.lastSyncTime), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
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
                  _emailController.clear();
                  _passwordController.clear();
                  _otpController.clear();
                  _fullNameController.clear();
                  _studentIdController.clear();
                  _departmentController.clear();
                  _errorMessage = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out.')),
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
      ],
    );
  }

  Widget _buildAuthView(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab switcher
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
                _buildTab('Sign In', !_isRegisterMode, isDark, () {
                  setState(() { _isRegisterMode = false; _errorMessage = null; });
                }),
                _buildTab('Register', _isRegisterMode, isDark, () {
                  setState(() { _isRegisterMode = true; _errorMessage = null; });
                }),
              ],
            ),
          ),

        Text(
          _isOtpSent ? 'Verify Email' : (_isRegisterMode ? 'Create Account' : 'Welcome Back'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          _isOtpSent
              ? 'Enter the 6-digit code sent to your email.'
              : (_isRegisterMode
                  ? 'Register with your UIU student email.'
                  : 'Sign in with your password or OTP.'),
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        if (!_isOtpSent) ...[
          if (_isRegisterMode) ..._buildRegisterFields(isDark),
          if (!_isRegisterMode) ..._buildSignInFields(isDark),
        ] else ...[
          _buildOtpFields(isDark, primaryColor),
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
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        if (!_isOtpSent) ...[
          if (_isRegisterMode) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleRegisterOtp,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add_rounded),
                label: const Text('Register & Verify Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handlePasswordLogin,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.login_rounded),
                label: const Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500], fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleSignInOtp,
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Sign In with OTP Email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: const Color(0xFFEA580C).withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleVerifyOtp,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_user_rounded),
              label: Text(_isRegisterMode ? 'Verify & Complete Registration' : 'Verify & Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildSignInFields(bool isDark) {
    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'University Email *',
          prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
          hintText: 'username@bscse.uiu.ac.bd',
        ),
      ),
      const SizedBox(height: 6),
      _buildDomainChips(isDark),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Password *',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          hintText: 'Enter your password',
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRegisterFields(bool isDark) {
    return [
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
          labelText: 'Department',
          prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
          hintText: 'e.g. Computer Science & Engineering',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'UIU Student Email *',
          prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
          hintText: 'username@bscse.uiu.ac.bd',
        ),
      ),
      const SizedBox(height: 6),
      _buildDomainChips(isDark),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Create Password * (min 6 chars)',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          hintText: 'Choose a password',
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 13, color: isDark ? Colors.white54 : Colors.grey[500]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Password lets you sign in without waiting for OTP email.',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500]),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildOtpFields(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: const Text('Change', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 10.0, fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: '------', counterText: ''),
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _secondsRemaining > 30 ? primaryColor : const Color(0xFFEF4444)),
              ),
            ]),
            if (_secondsRemaining == 0)
              TextButton(
                onPressed: _isRegisterMode ? _handleRegisterOtp : _handleSignInOtp,
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
                  'Check your inbox and spam/junk folder for the code from hamimasir5@gmail.com.',
                  style: TextStyle(fontSize: 11, height: 1.35, color: isDark ? Colors.white70 : const Color(0xFF9A3412), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDomainChips(bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: ['@bscse.uiu.ac.bd', '@bseee.uiu.ac.bd', '@bsce.uiu.ac.bd', '@bba.uiu.ac.bd'].map((domain) {
        return ActionChip(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          label: Text(domain, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFEA580C))),
          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
          side: BorderSide(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
          onPressed: () {
            final current = _emailController.text.trim();
            final prefix = current.contains('@') ? current.split('@').first : current;
            _emailController.text = (prefix.isNotEmpty ? prefix : 'username') + domain;
          },
        );
      }).toList(),
    );
  }

  Widget _buildTab(String label, bool isActive, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFFEA580C) : (isDark ? Colors.white70 : Colors.grey[700]),
                fontSize: 13,
              ),
            ),
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
