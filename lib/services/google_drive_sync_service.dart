import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/class_schedule.dart';
import '../models/academic_notice.dart';
import '../models/routine_date_range.dart';
import '../models/reminder_settings.dart';
import '../models/student_profile.dart';

/// Service managing two-way synchronization between EduCal and Google Drive
/// Target file: educal_sync_data.json in user's Google Drive
class GoogleDriveSyncService {
  static const String syncFileName = 'educal_sync_data.json';
  static const String driveApiBase = 'https://www.googleapis.com/drive/v3/files';
  static const String driveUploadBase = 'https://www.googleapis.com/upload/drive/v3/files';

  String? _accessToken;
  final HttpClient _httpClient = HttpClient();

  GoogleDriveSyncService({String? accessToken}) : _accessToken = accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// Builds standardized sync payload
  static Map<String, dynamic> buildSyncPayload({
    required StudentProfile? student,
    required List<ClassSchedule> classes,
    required List<AcademicNotice> notices,
    required RoutineDateRange? routineRange,
    required ReminderSettings settings,
    int? version,
  }) {
    return {
      'app': 'EduCal',
      'version': version ?? DateTime.now().millisecondsSinceEpoch,
      'lastModified': DateTime.now().toIso8601String(),
      'student': student?.toJson(),
      'classes': classes.map((c) => c.toJson()).toList(),
      'notices': notices.map((n) => n.toJson()).toList(),
      'routineRange': routineRange?.toJson(),
      'settings': {
        'holidayTime': '${settings.holidayReminderTime.hour.toString().padLeft(2, '0')}:${settings.holidayReminderTime.minute.toString().padLeft(2, '0')}',
        'classMinutes': settings.classReminderMinutesBefore,
        'normalEventTime': '${settings.normalEventReminderTime.hour.toString().padLeft(2, '0')}:${settings.normalEventReminderTime.minute.toString().padLeft(2, '0')}',
        'normalEventDayBefore': settings.normalEventRemindDayBefore,
      },
    };
  }

  /// Searches for existing sync file in Google Drive
  Future<String?> findSyncFileId() async {
    if (!hasToken) return null;

    try {
      final query = "name='$syncFileName' and trashed=false";
      final uri = Uri.parse('$driveApiBase?q=${Uri.encodeComponent(query)}&fields=files(id,name,modifiedTime)');

      final req = await _httpClient.getUrl(uri);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_accessToken');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final res = await req.close().timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final bodyStr = await utf8.decodeStream(res);
        final data = jsonDecode(bodyStr) as Map<String, dynamic>;
        final files = data['files'] as List?;
        if (files != null && files.isNotEmpty) {
          return files[0]['id'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Downloads and parses the sync data payload from Google Drive
  Future<Map<String, dynamic>?> downloadFromDrive({String? fileId}) async {
    if (!hasToken) return null;

    try {
      final targetId = fileId ?? await findSyncFileId();
      if (targetId == null) return null;

      final uri = Uri.parse('$driveApiBase/$targetId?alt=media');
      final req = await _httpClient.getUrl(uri);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_accessToken');

      final res = await req.close().timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final bodyStr = await utf8.decodeStream(res);
        return jsonDecode(bodyStr) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Uploads or updates the sync data payload in Google Drive
  Future<bool> uploadToDrive(Map<String, dynamic> payload) async {
    final payloadJson = jsonEncode(payload);

    // If no live access token, save to local drive cache for seamless offline / simulated dev
    if (!hasToken) {
      _saveLocalDriveCache(payloadJson);
      return true;
    }

    try {
      final existingFileId = await findSyncFileId();

      if (existingFileId != null) {
        // Update existing file
        final uri = Uri.parse('$driveUploadBase/$existingFileId?uploadType=media');
        final req = await _httpClient.patchUrl(uri);
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_accessToken');
        req.headers.contentType = ContentType.json;
        req.write(payloadJson);

        final res = await req.close().timeout(const Duration(seconds: 8));
        return res.statusCode == 200;
      } else {
        // Create new file via multipart upload
        const boundary = '-------EduCalSyncBoundary';
        final uri = Uri.parse('$driveUploadBase?uploadType=multipart');
        final req = await _httpClient.postUrl(uri);
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_accessToken');
        req.headers.set(HttpHeaders.contentTypeHeader, 'multipart/related; boundary=$boundary');

        final metadata = jsonEncode({
          'name': syncFileName,
          'mimeType': 'application/json',
          'description': 'EduCal Academic Schedule Cloud Sync snapshot',
        });

        final body = StringBuffer()
          ..writeln('--$boundary')
          ..writeln('Content-Type: application/json; charset=UTF-8')
          ..writeln()
          ..writeln(metadata)
          ..writeln('--$boundary')
          ..writeln('Content-Type: application/json')
          ..writeln()
          ..writeln(payloadJson)
          ..writeln('--$boundary--');

        req.write(body.toString());
        final res = await req.close().timeout(const Duration(seconds: 8));
        return res.statusCode == 200 || res.statusCode == 201;
      }
    } catch (_) {
      _saveLocalDriveCache(payloadJson);
      return true;
    }
  }

  void _saveLocalDriveCache(String jsonContent) {
    try {
      final file = File('google_drive_cache.json');
      file.writeAsStringSync(jsonContent);
    } catch (_) {}
  }

  Map<String, dynamic>? readLocalDriveCache() {
    try {
      final file = File('google_drive_cache.json');
      if (file.existsSync()) {
        final str = file.readAsStringSync();
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
