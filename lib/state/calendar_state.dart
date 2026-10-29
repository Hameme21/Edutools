import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_schedule.dart';
import '../models/academic_notice.dart';
import '../models/calendar_day_schedule.dart';
import '../models/reminder_notification.dart';
import '../models/reminder_settings.dart';
import '../models/student_profile.dart';
import '../models/routine_date_range.dart';
import '../services/calendar_service.dart';
import '../services/reminder_service.dart';
import '../services/file_parser_service.dart';
import '../services/sample_data_service.dart';
import '../services/google_drive_sync_service.dart';
import '../services/api_service.dart';

class CalendarState extends ChangeNotifier {
  final CalendarService _calendarService = CalendarService();
  final GoogleDriveSyncService _driveSyncService = GoogleDriveSyncService();
  late final ReminderService _reminderService;

  DateTime _selectedDate = DateTime.now();
  ThemeMode _themeMode = ThemeMode.system;
  int _currentTabIndex = 0;

  NoticeCategory? _selectedNoticeFilter;
  String _noticeSearchQuery = '';

  StudentProfile? _currentStudent;
  bool _isSyncing = false;
  Timer? _autoSyncTimer;

  static String get _serverBaseUrl => ApiService.defaultBaseUrl;

  CalendarState() {
    _reminderService = ReminderService(_calendarService);
    // User requested: Keep the official academic notices, but don't add sample classes.
    _calendarService.setNotices(SampleDataService.getOfficialAcademicCalendar());
    _reminderService.refreshReminders(referenceDate: _selectedDate);

    // Restore persistent student session from disk
    _restoreSavedSession();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  void refresh() {
    notifyListeners();
  }

  CalendarService get calendarService => _calendarService;
  GoogleDriveSyncService get driveSyncService => _driveSyncService;
  ReminderService get reminderService => _reminderService;
  ReminderSettings get reminderSettings => _reminderService.settings;
  DateTime get selectedDate => _selectedDate;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  int get currentTabIndex => _currentTabIndex;

  NoticeCategory? get selectedNoticeFilter => _selectedNoticeFilter;
  String get noticeSearchQuery => _noticeSearchQuery;

  StudentProfile? get currentStudent => _currentStudent;
  bool get isLoggedIn => _currentStudent != null;
  bool get isSyncing => _isSyncing;

  List<ClassSchedule> get classes => _calendarService.classes;
  List<AcademicNotice> get notices => _calendarService.notices;
  List<ReminderNotification> get notifications => _reminderService.notifications;
  int get unreadNotificationCount => _reminderService.unreadCount;

  CalendarDaySchedule get selectedDaySchedule => _calendarService.getDaySchedule(_selectedDate);

  List<AcademicNotice> get upcomingNotices => _calendarService.getUpcomingNotices(
        category: _selectedNoticeFilter,
        query: _noticeSearchQuery,
        includePast: false,
      );

  Map<String, int> get dashboardStats => _calendarService.getDashboardStats(_selectedDate);

  // Student Authentication & Persistence
  void loginStudent({
    required String email,
    required String studentId,
    String? fullName,
    String? department,
  }) {
    final name = (fullName != null && fullName.isNotEmpty && fullName != 'Verified Student')
        ? fullName
        : StudentProfile.formatNameFromEmail(email);

    _currentStudent = StudentProfile(
      email: email.trim(),
      studentId: studentId.trim(),
      fullName: name,
      department: department ?? 'Computer Science & Engineering',
      isSynced: true,
      lastSyncTime: DateTime.now(),
    );

    _saveSessionToDisk();
    _startAutoSync();
    syncWithWebsite();
    notifyListeners();
  }

  void updateProfile({String? fullName, String? studentId, String? department, String? semester}) {
    if (_currentStudent == null) return;
    _currentStudent = _currentStudent!.copyWith(
      fullName: fullName,
      studentId: studentId,
      department: department,
      semester: semester,
    );
    _saveSessionToDisk();
    syncWithWebsite();
    notifyListeners();
  }

  void logoutStudent() {
    _currentStudent = null;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _deleteSessionFromDisk();
    notifyListeners();
  }

  static List<File> _getCandidateSessionFiles() {
    final List<File> files = [];
    try {
      if (Platform.isAndroid) {
        files.add(File('/data/user/0/com.example.educal/files/session_storage.json'));
        files.add(File('/data/data/com.example.educal/files/session_storage.json'));
        files.add(File('/data/user/0/com.example.educal/session_storage.json'));
        files.add(File('/data/data/com.example.educal/session_storage.json'));
      } else if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null && appData.isNotEmpty) {
          files.add(File('$appData/EduTools/session_storage.json'));
        }
      }
    } catch (_) {}
    files.add(File('session_storage.json'));
    return files;
  }

  Future<void> _restoreSavedSession() async {
    // 1. Primary update-proof persistence: SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefData = prefs.getString('edutools_session_data');
      if (prefData != null && prefData.isNotEmpty) {
        final data = jsonDecode(prefData) as Map<String, dynamic>;
        if (data['student'] != null) {
          final profile = StudentProfile.fromJson(Map<String, dynamic>.from(data['student']));
          if (profile.email != 'student@uiu.ac.bd' &&
              profile.email != 'student@university.edu' &&
              profile.fullName != 'Alex Chen') {
            _currentStudent = profile;
            _startAutoSync();
          }
          if (data['classes'] != null && data['classes'] is List) {
            final List<ClassSchedule> loaded = [];
            for (var c in data['classes']) {
              loaded.add(ClassSchedule.fromJson(Map<String, dynamic>.from(c)));
            }
            if (loaded.isNotEmpty) {
              _calendarService.setClasses(loaded);
              _reminderService.refreshReminders(referenceDate: _selectedDate);
            }
          }
          notifyListeners();
          return;
        }
      }
    } catch (_) {}

    // 2. Secondary fallback: Candidate disk files
    for (final file in _getCandidateSessionFiles()) {
      try {
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          if (content.isNotEmpty) {
            final data = jsonDecode(content) as Map<String, dynamic>;
            if (data['student'] != null) {
              final profile = StudentProfile.fromJson(Map<String, dynamic>.from(data['student']));
              // Discard legacy dummy placeholder accounts
              if (profile.email != 'student@uiu.ac.bd' &&
                  profile.email != 'student@university.edu' &&
                  profile.fullName != 'Alex Chen') {
                _currentStudent = profile;
                _startAutoSync();
              }
              if (data['classes'] != null && data['classes'] is List) {
                final List<ClassSchedule> loaded = [];
                for (var c in data['classes']) {
                  loaded.add(ClassSchedule.fromJson(Map<String, dynamic>.from(c)));
                }
                if (loaded.isNotEmpty) {
                  _calendarService.setClasses(loaded);
                  _reminderService.refreshReminders(referenceDate: _selectedDate);
                }
              }
              notifyListeners();
              return;
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _saveSessionToDisk() async {
    final data = {
      'student': _currentStudent?.toJson(),
      'classes': _calendarService.classes.map((c) => c.toJson()).toList(),
      'savedAt': DateTime.now().toIso8601String(),
    };
    final jsonStr = jsonEncode(data);

    // 1. SharedPreferences (survives app updates & APK reinstallation)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('edutools_session_data', jsonStr);
    } catch (_) {}

    // 2. Candidate disk files
    for (final file in _getCandidateSessionFiles()) {
      try {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(jsonStr, flush: true);
      } catch (_) {}
    }
  }

  Future<void> _deleteSessionFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('edutools_session_data');
    } catch (_) {}

    for (final file in _getCandidateSessionFiles()) {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
  }

  int _lastKnownGlobalVersion = 0;

  void _startAutoSync() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isSyncing) {
        _pullServerUpdatesSilently();
      }
    });
  }

  Future<void> _pullServerUpdatesSilently() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);

      // 1. Pull Global Network Broadcast (updates from any PC or admin)
      final globalUri = Uri.parse('$_serverBaseUrl/api/calendar/global-sync');
      final gReq = await client.getUrl(globalUri);
      final gRes = await gReq.close();
      if (gRes.statusCode == 200) {
        final bodyStr = await gRes.transform(utf8.decoder).join();
        final gData = jsonDecode(bodyStr) as Map<String, dynamic>;
        final int serverVersion = gData['version'] ?? 0;

        if (serverVersion > _lastKnownGlobalVersion) {
          _lastKnownGlobalVersion = serverVersion;
          bool hasChanges = false;

          if (gData['classes'] != null && gData['classes'] is List) {
            final List<ClassSchedule> parsed = [];
            for (var item in gData['classes']) {
              if (item is Map) parsed.add(ClassSchedule.fromJson(Map<String, dynamic>.from(item)));
            }
            if (parsed.isNotEmpty && _hasScheduleChanged(parsed, _calendarService.classes)) {
              _calendarService.setClasses(parsed);
              hasChanges = true;
            }
          }

          if (gData['notices'] != null && gData['notices'] is List) {
            final List<AcademicNotice> parsedNotices = [];
            for (var item in gData['notices']) {
              if (item is Map) parsedNotices.add(AcademicNotice.fromJson(Map<String, dynamic>.from(item)));
            }
            if (parsedNotices.isNotEmpty && parsedNotices.length != _calendarService.notices.length) {
              _calendarService.setNotices(parsedNotices);
              hasChanges = true;
            }
          }

          if (hasChanges) {
            _reminderService.refreshReminders(referenceDate: _selectedDate);
            _saveSessionToDisk();
            notifyListeners();
          }
        }
      }

      // 2. Pull Student-specific sync if logged in
      if (_currentStudent != null) {
        final userUri = Uri.parse('$_serverBaseUrl/api/student/sync?email=${Uri.encodeComponent(_currentStudent!.email)}');
        final uReq = await client.getUrl(userUri);
        final uRes = await uReq.close();
        if (uRes.statusCode == 200) {
          final bodyStr = await uRes.transform(utf8.decoder).join();
          final uData = jsonDecode(bodyStr) as Map<String, dynamic>;
          if (uData['classes'] != null && uData['classes'] is List) {
            final List<ClassSchedule> parsed = [];
            for (var item in uData['classes']) {
              if (item is Map) parsed.add(ClassSchedule.fromJson(Map<String, dynamic>.from(item)));
            }
            if (parsed.isNotEmpty && _hasScheduleChanged(parsed, _calendarService.classes)) {
              _calendarService.setClasses(parsed);
              _reminderService.refreshReminders(referenceDate: _selectedDate);
              _saveSessionToDisk();
              notifyListeners();
            }
          }
        }
      }

      client.close();
    } catch (_) {}
  }

  bool _hasScheduleChanged(List<ClassSchedule> a, List<ClassSchedule> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i].courseCode != b[i].courseCode ||
          a[i].dayOfWeek != b[i].dayOfWeek ||
          a[i].startTime != b[i].startTime) {
        return true;
      }
    }
    return false;
  }

  Future<bool> syncWithWebsite() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      // Broadcast globally to all users
      final globalUri = Uri.parse('$_serverBaseUrl/api/calendar/global-update');
      final gReq = await client.postUrl(globalUri);
      gReq.headers.set('content-type', 'application/json');
      final noticesList = _calendarService.notices.map((n) => n.toJson()).toList();
      final gPayload = <String, dynamic>{
        'source': _currentStudent?.email ?? 'PC Client',
        'classes': _calendarService.classes.map((c) => c.toJson()).toList(),
      };
      if (noticesList.isNotEmpty) gPayload['notices'] = noticesList;
      gReq.add(utf8.encode(jsonEncode(gPayload)));
      await gReq.close();

      // Push to student profile if logged in
      if (_currentStudent != null) {
        final uri = Uri.parse('$_serverBaseUrl/api/student/sync');
        final req = await client.postUrl(uri);
        req.headers.set('content-type', 'application/json');
        final payload = {
          'email': _currentStudent!.email,
          'student': _currentStudent!.toJson(),
          'classes': _calendarService.classes.map((c) => c.toJson()).toList(),
        };
        req.add(utf8.encode(jsonEncode(payload)));
        await req.close();
      }

      client.close();
    } catch (_) {}

    if (_currentStudent != null) {
      _currentStudent = StudentProfile(
        email: _currentStudent!.email,
        studentId: _currentStudent!.studentId,
        fullName: _currentStudent!.fullName,
        department: _currentStudent!.department,
        semester: _currentStudent!.semester,
        isSynced: true,
        lastSyncTime: DateTime.now(),
      );
    }

    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _saveSessionToDisk();
    _isSyncing = false;
    notifyListeners();
    return true;
  }

  Future<bool> syncWithGoogleDrive() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final payload = GoogleDriveSyncService.buildSyncPayload(
        student: _currentStudent,
        classes: _calendarService.classes,
        notices: _calendarService.notices,
        routineRange: routineRange,
        settings: reminderSettings,
      );

      // 1. Upload snapshot to Google Drive
      await _driveSyncService.uploadToDrive(payload);

      // 2. Pull remote Google Drive updates
      final remote = await _driveSyncService.downloadFromDrive();
      if (remote != null) {
        _applySyncPayload(remote);
      }
    } catch (_) {}

    // Broadcast update to web server as well
    await syncWithWebsite();

    if (_currentStudent != null) {
      _currentStudent = _currentStudent!.copyWith(
        isSynced: true,
        lastSyncTime: DateTime.now(),
      );
    }

    _saveSessionToDisk();
    _isSyncing = false;
    notifyListeners();
    return true;
  }

  void _applySyncPayload(Map<String, dynamic> data) {
    bool hasChanges = false;
    if (data['classes'] != null && data['classes'] is List) {
      final List<ClassSchedule> remoteClasses = [];
      for (var c in data['classes']) {
        if (c is Map) remoteClasses.add(ClassSchedule.fromJson(Map<String, dynamic>.from(c)));
      }
      if (remoteClasses.isNotEmpty && _hasScheduleChanged(remoteClasses, _calendarService.classes)) {
        _calendarService.setClasses(remoteClasses);
        hasChanges = true;
      }
    }

    if (data['routineRange'] != null && data['routineRange'] is Map) {
      try {
        final rr = RoutineDateRange.fromJson(Map<String, dynamic>.from(data['routineRange']));
        _calendarService.setRoutineDateRange(
          startDate: rr.startDate,
          endDate: rr.endDate,
          isAutoFigured: rr.isAutoFigured,
          title: rr.title,
          sourceDescription: rr.sourceDescription,
          classesSuspendedDate: rr.classesSuspendedDate,
          finalExamDate: rr.finalExamDate,
          nextSemesterBeginDate: rr.nextSemesterBeginDate,
        );
        hasChanges = true;
      } catch (_) {}
    }

    if (hasChanges) {
      _reminderService.refreshReminders(referenceDate: _selectedDate);
    }
  }

  void _pushChangesToServer() {
    _saveSessionToDisk();
    syncWithGoogleDrive();
  }

  // Actions
  void selectDate(DateTime date) {
    final newDate = DateTime(date.year, date.month, date.day);
    if (_selectedDate == newDate) return;
    _selectedDate = newDate;
    notifyListeners();
  }

  void setTabIndex(int index) {
    if (_currentTabIndex == index) return;
    _currentTabIndex = index;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    cycleThemeMode();
  }

  void cycleThemeMode() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  void setNoticeFilter(NoticeCategory? category) {
    _selectedNoticeFilter = category;
    notifyListeners();
  }

  void setNoticeSearchQuery(String query) {
    _noticeSearchQuery = query;
    notifyListeners();
  }

  void loadOfficialAcademicCalendar({bool notify = true}) {
    _calendarService.setNotices(SampleDataService.getOfficialAcademicCalendar());
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    if (notify) notifyListeners();
  }

  // Routine Active Schedule Window & Lifecycle
  RoutineDateRange? get routineRange => _calendarService.activeRoutineRange;
  DateTime? get routineStartDate => _calendarService.routineStartDate;
  DateTime? get routineEndDate => _calendarService.routineEndDate;
  bool get isRoutineAutoFigured => _calendarService.isRoutineAutoFigured;

  RoutineDateRange autoFigureRoutineDates({DateTime? referenceDate}) {
    return _calendarService.autoFigureRoutineDates(
      referenceDate: referenceDate ?? _selectedDate,
    );
  }

  void setRoutineDateRange({
    required DateTime startDate,
    required DateTime endDate,
    bool isAutoFigured = false,
    String? title,
    String? sourceDescription,
    DateTime? classesSuspendedDate,
    DateTime? finalExamDate,
    DateTime? nextSemesterBeginDate,
  }) {
    _calendarService.setRoutineDateRange(
      startDate: startDate,
      endDate: endDate,
      isAutoFigured: isAutoFigured,
      title: title,
      sourceDescription: sourceDescription,
      classesSuspendedDate: classesSuspendedDate,
      finalExamDate: finalExamDate,
      nextSemesterBeginDate: nextSemesterBeginDate,
    );
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _pushChangesToServer();
    notifyListeners();
  }

  void autoApplyRoutineDates({DateTime? referenceDate}) {
    final range = autoFigureRoutineDates(referenceDate: referenceDate);
    _calendarService.setRoutineDateRange(
      startDate: range.startDate,
      endDate: range.endDate,
      isAutoFigured: true,
      title: range.title,
      sourceDescription: range.sourceDescription,
      classesSuspendedDate: range.classesSuspendedDate,
      finalExamDate: range.finalExamDate,
      nextSemesterBeginDate: range.nextSemesterBeginDate,
    );
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _pushChangesToServer();
    notifyListeners();
  }

  void clearRoutineDateRange() {
    _calendarService.clearRoutineDateRange();
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _pushChangesToServer();
    notifyListeners();
  }

  void loadSampleData({bool notify = true}) {
    _calendarService.setClasses(SampleDataService.getSampleClasses());
    _calendarService.setNotices(SampleDataService.getOfficialAcademicCalendar());
    autoApplyRoutineDates(referenceDate: _selectedDate);
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _pushChangesToServer();
    if (notify) notifyListeners();
  }

  void clearAllData() {
    _calendarService.setClasses([]);
    _calendarService.setNotices([]);
    _calendarService.clearRoutineDateRange();
    _reminderService.clearAll();
    _pushChangesToServer();
    notifyListeners();
  }

  ParseResult<ClassSchedule> importClassSchedule(String content, {bool autoApplyDates = true}) {
    final result = FileParserService.parseClassSchedule(content);
    if (result.isSuccess) {
      _calendarService.setClasses(result.items);
      if (autoApplyDates) {
        final detected = autoFigureRoutineDates(referenceDate: _selectedDate);
        _calendarService.setRoutineDateRange(
          startDate: detected.startDate,
          endDate: detected.endDate,
          isAutoFigured: true,
          title: detected.title,
          sourceDescription: detected.sourceDescription,
          classesSuspendedDate: detected.classesSuspendedDate,
          finalExamDate: detected.finalExamDate,
          nextSemesterBeginDate: detected.nextSemesterBeginDate,
        );
      }
      _reminderService.refreshReminders(referenceDate: _selectedDate);
      _pushChangesToServer();
      notifyListeners();
    }
    return result;
  }

  ParseResult<AcademicNotice> importAcademicCalendar(String content) {
    final result = FileParserService.parseAcademicCalendar(content);
    if (result.isSuccess) {
      _calendarService.setNotices(result.items);
      _reminderService.refreshReminders(referenceDate: _selectedDate);
      notifyListeners();
    }
    return result;
  }

  void addClass(ClassSchedule classSchedule) {
    _calendarService.addClass(classSchedule);
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _pushChangesToServer();
    notifyListeners();
  }

  void updateClass(ClassSchedule classSchedule) {
    _calendarService.updateClass(classSchedule);
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _pushChangesToServer();
    notifyListeners();
  }

  void deleteClass(String id) {
    _calendarService.removeClass(id);
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _pushChangesToServer();
    notifyListeners();
  }

  void addNotice(AcademicNotice notice) {
    _calendarService.addNotice(notice);
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    notifyListeners();
  }

  void updateNotice(AcademicNotice notice) {
    _calendarService.updateNotice(notice);
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    notifyListeners();
  }

  void deleteNotice(String id) {
    _calendarService.removeNotice(id);
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    notifyListeners();
  }

  void customizeClassReminder({
    required ClassSchedule classSchedule,
    required int? minutesBefore,
    required bool applyToAll,
    required bool enabled,
  }) {
    if (applyToAll) {
      _reminderService.updateSettings(
        _reminderService.settings.copyWith(
          classReminderMinutesBefore: minutesBefore ?? _reminderService.settings.classReminderMinutesBefore,
          enableClassReminders: enabled,
        ),
      );
      final updatedList = _calendarService.classes.map((c) {
        return c.copyWith(
          customReminderMinutes: null,
          reminderEnabled: enabled,
        );
      }).toList();
      _calendarService.setClasses(updatedList);
    } else {
      final updated = classSchedule.copyWith(
        customReminderMinutes: minutesBefore,
        reminderEnabled: enabled,
      );
      _calendarService.updateClass(updated);
    }
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    _pushChangesToServer();
    notifyListeners();
  }

  void customizeNoticeReminder({
    required AcademicNotice notice,
    required TimeOfDay? reminderTime,
    required bool? dayBefore,
    required bool applyToAll,
    required bool enabled,
  }) {
    if (applyToAll) {
      if (notice.isHoliday) {
        _reminderService.updateSettings(
          _reminderService.settings.copyWith(
            holidayReminderTime: reminderTime ?? _reminderService.settings.holidayReminderTime,
            enableHolidayReminders: enabled,
          ),
        );
        final updatedList = _calendarService.notices.map((n) {
          if (n.isHoliday) {
            return n.copyWith(
              customReminderTime: null,
              reminderEnabled: enabled,
            );
          }
          return n;
        }).toList();
        _calendarService.setNotices(updatedList);
      } else {
        _reminderService.updateSettings(
          _reminderService.settings.copyWith(
            normalEventReminderTime: reminderTime ?? _reminderService.settings.normalEventReminderTime,
            normalEventRemindDayBefore: dayBefore ?? _reminderService.settings.normalEventRemindDayBefore,
            enableNormalEventReminders: enabled,
          ),
        );
        final updatedList = _calendarService.notices.map((n) {
          if (!n.isHoliday && n.category == notice.category) {
            return n.copyWith(
              customReminderTime: null,
              customRemindDayBefore: null,
              reminderEnabled: enabled,
            );
          }
          return n;
        }).toList();
        _calendarService.setNotices(updatedList);
      }
    } else {
      final updated = notice.copyWith(
        customReminderTime: reminderTime,
        customRemindDayBefore: dayBefore,
        reminderEnabled: enabled,
      );
      _calendarService.updateNotice(updated);
    }
    _reminderService.refreshReminders(referenceDate: _selectedDate);
    notifyListeners();
  }

  void updateReminderSettings(ReminderSettings settings) {
    _reminderService.updateSettings(settings);
    notifyListeners();
  }

  void markNotificationRead(String id) {
    _reminderService.markAsRead(id);
    notifyListeners();
  }

  void markAllNotificationsRead() {
    _reminderService.markAllAsRead();
    notifyListeners();
  }
}
