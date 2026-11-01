import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:educal/services/google_drive_sync_service.dart';
import 'package:educal/services/student_sync_service.dart';
import 'package:educal/state/calendar_state.dart';
import 'package:educal/models/class_schedule.dart';

class FakeDrive extends GoogleDriveSyncService {
  String? fileId = 'existing';
  bool deny = false;
  Map<String, dynamic>? remote = {'classes': [], 'routineRange': null};
  int uploads = 0;
  bool? createOnly;
  @override
  Future<void> ensureAccess({String? email}) async {}
  @override
  Future<String?> findSyncFileId() async {
    if (deny) throw StateError('Drive denied');
    return fileId;
  }
  @override
  Future<Map<String, dynamic>?> downloadFromDrive({String? fileId}) async => remote;
  @override
  Future<bool> uploadToDrive(Map<String, dynamic> payload, {bool createOnly = false}) async {
    uploads++; this.createOnly = createOnly; return true;
  }
}
class FakeAccount extends StudentSyncService {
  final writes = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> write(Map<String, dynamic> snapshot) async { writes.add(snapshot); return {'success': true}; }
}
void main() {
  late FakeDrive drive;
  late FakeAccount account;
  late CalendarState state;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'edutools_session_data': jsonEncode({
      'student': {'email': 'student@example.com', 'studentId': '1', 'fullName': 'Student'}, 'classes': [],
    })});
    drive = FakeDrive(); account = FakeAccount();
    state = CalendarState(studentSyncService: account, driveSyncService: drive);
    for (var i = 0; i < 10; i++) { await Future<void>.delayed(Duration.zero); }
    state.calendarService.setClasses([ClassSchedule(id:'LOCAL',subject:'Algorithms',courseCode:'CSE',dayOfWeek:1,startTime:'09:00',endTime:'10:00',room:'101',instructor:'Teacher')]);
  });
  tearDown(() => state.dispose());
  test('existing Drive JSON replaces local routine without an upload', () async {
    expect(await state.syncWithGoogleDrive(), isTrue);
    expect(drive.uploads, 0);
    expect(state.classes, isEmpty);
    expect(account.writes.single['classes'], isEmpty);
  });
  test('missing Drive JSON uploads once using create-only semantics', () async {
    drive.fileId = null;
    expect(await state.syncWithGoogleDrive(), isTrue);
    expect(drive.uploads, 1);
    expect(drive.createOnly, isTrue);
    expect(state.classes.single.id, 'LOCAL');
    expect(account.writes.single['classes'], hasLength(1));
  });
  test('failed lookup or malformed JSON preserves the local routine and does not upload', () async {
    drive.deny = true;
    expect(await state.syncWithGoogleDrive(), isFalse);
    expect(drive.uploads, 0);
    expect(state.classes.single.id, 'LOCAL');
    drive.deny = false; drive.remote = {'classes': 'invalid'};
    expect(await state.syncWithGoogleDrive(), isFalse);
    expect(state.classes.single.id, 'LOCAL');
  });
}
