import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:educal/state/calendar_state.dart';
import 'package:educal/models/class_schedule.dart';
import 'package:educal/services/student_sync_service.dart';

class FakeSync extends StudentSyncService {
  Map<String, dynamic> remote = {'success': true, 'hasSchedule': false, 'classes': []};
  final List<Map<String, dynamic>> writes = [];
  bool fail = false;
  Completer<Map<String, dynamic>>? pendingRead;
  @override
  Future<Map<String, dynamic>> read(String email) async => pendingRead != null ? await pendingRead!.future : remote;
  @override
  Future<Map<String, dynamic>> write(Map<String, dynamic> snapshot) async {
    if (fail) throw StateError('Network unavailable');
    writes.add(snapshot);
    remote = {'success': true, 'hasSchedule': true, ...snapshot};
    return {'success': true};
  }
}

ClassSchedule lesson({String room = '101', String endTime = '10:00'}) => ClassSchedule(
  id: 'C1', subject: 'Algorithms', courseCode: 'CSE1', dayOfWeek: 1,
  startTime: '09:00', endTime: endTime, room: room, instructor: 'Teacher',
);

void main() {
  late FakeSync sync;
  late CalendarState state;
  Future<void> settle() async {
    for (var i = 0; i < 15; i++) { await Future<void>.delayed(Duration.zero); }
  }
  setUp(() async {
    SharedPreferences.setMockInitialValues({'edutools_session_data': jsonEncode({
      'student': {'email': 'sync@example.com', 'studentId': '1', 'fullName': 'Student'}, 'classes': [],
    })});
    sync = FakeSync();
    state = CalendarState(studentSyncService: sync);
    await settle();
  });
  tearDown(() => state.dispose());

  test('login loads the saved routine before uploading any local routine', () async {
    sync.remote = {'success': true, 'hasSchedule': true, 'classes': [lesson().toJson()]};
    state.loginStudent(email: 'sync@example.com', studentId: '1');
    await settle();
    expect(sync.writes, isEmpty);
    expect(state.classes.single.courseCode, 'CSE1');
  });

  test('room and end-time edits and an empty remote routine are applied', () async {
    sync.remote = {'success': true, 'hasSchedule': true, 'classes': [lesson().toJson()]};
    await state.syncWithWebsite();
    sync.remote = {'success': true, 'hasSchedule': true, 'classes': [lesson(room: '202', endTime: '11:00').toJson()]};
    await state.syncWithWebsite();
    expect(state.classes.single.room, '202');
    expect(state.classes.single.endTime, '11:00');
    sync.remote = {'success': true, 'hasSchedule': true, 'syncVersion': 1, 'classes': [], 'routineRange': null};
    await state.syncWithWebsite();
    expect(state.classes, isEmpty);
    expect(state.routineRange, isNull);
  });

  test('mobile local edits use the account endpoint without requiring Drive', () async {
    state.addClass(lesson());
    await settle();
    expect(sync.writes.single['email'], 'sync@example.com');
    expect((sync.writes.single['classes'] as List).length, 1);
    state.deleteClass('C1');
    await settle();
    expect(sync.writes.last['classes'], isEmpty);
  });

  test('legacy empty snapshots cannot erase the only existing local routine', () async {
    state.calendarService.setClasses([lesson()]);
    sync.remote = {'success': true, 'hasSchedule': true, 'syncVersion': 0, 'classes': []};
    await state.syncWithWebsite();
    await settle();
    expect(state.classes, hasLength(1));
    expect(sync.writes.last['syncVersion'], 1);
  });

  test('failed writes remain unsynced and retry on the next sync', () async {
    sync.fail = true;
    state.addClass(lesson());
    await settle();
    expect(state.currentStudent!.isSynced, isFalse);
    sync.fail = false;
    expect(await state.syncWithWebsite(), isTrue);
    expect(sync.writes.single['classes'], hasLength(1));
  });

  test('an in-flight pull cannot overwrite a newer local import/edit', () async {
    sync.pendingRead = Completer<Map<String, dynamic>>();
    final pull = state.syncWithWebsite();
    state.addClass(lesson(room: 'Local edit'));
    sync.pendingRead!.complete({'success': true, 'hasSchedule': true, 'classes': [lesson(room: 'Old remote').toJson()]});
    await pull;
    await settle();
    expect(state.classes.single.room, 'Local edit');
    expect((sync.writes.last['classes'] as List).single['room'], 'Local edit');
  });
}
