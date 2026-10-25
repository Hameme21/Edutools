import 'package:flutter/material.dart';
import 'state/calendar_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EduCalApp());
}

class EduCalApp extends StatefulWidget {
  const EduCalApp({super.key});

  @override
  State<EduCalApp> createState() => _EduCalAppState();
}

class _EduCalAppState extends State<EduCalApp> {
  late final CalendarState _calendarState;

  @override
  void initState() {
    super.initState();
    _calendarState = CalendarState();
    _calendarState.addListener(_onStateChange);
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTools - Academic Calendar & Reminders',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _calendarState.themeMode,
      home: MainScreen(state: _calendarState),
    );
  }
}
