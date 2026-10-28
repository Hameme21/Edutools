import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'state/calendar_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/reminders/notification_permission_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EduCalApp());
}

class EduCalApp extends StatefulWidget {
  const EduCalApp({super.key});

  @override
  State<EduCalApp> createState() => _EduCalAppState();
}

class _EduCalAppState extends State<EduCalApp> {
  late final CalendarState _calendarState;
  bool _showNotificationPrompt = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _calendarState = CalendarState();
    _calendarState.addListener(_onStateChange);
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final shouldShow = await NotificationPermissionScreen.shouldShow();
    if (mounted) {
      setState(() {
        _showNotificationPrompt = shouldShow;
        _checkingPermission = false;
      });
    }
  }

  @override
  void dispose() {
    _calendarState.removeListener(_onStateChange);
    _calendarState.dispose();
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
  }

  void _onNotificationComplete() {
    setState(() {
      _showNotificationPrompt = false;
    });
  }

  void _onLoginComplete() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTools - Academic Calendar & Reminders',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _calendarState.themeMode,
      home: _checkingPermission
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : !_calendarState.isLoggedIn
              ? LoginScreen(state: _calendarState, onLoginComplete: _onLoginComplete)
              : _showNotificationPrompt
                  ? NotificationPermissionScreen(onComplete: _onNotificationComplete)
                  : MainScreen(state: _calendarState),
    );
  }
}
