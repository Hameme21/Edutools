import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'api_service.dart';

/// Account-specific routine storage shared by the mobile and web clients.
class StudentSyncService {
  final String? baseUrl;
  StudentSyncService({this.baseUrl});

  Future<Map<String, dynamic>> read(String email) => _request(
    'GET', '/api/student/sync?email=${Uri.encodeComponent(email.trim().toLowerCase())}',
  );

  Future<Map<String, dynamic>> write(Map<String, dynamic> snapshot) =>
      _request('POST', '/api/student/sync', snapshot);

  Future<Map<String, dynamic>> _request(String method, String path,
      [Map<String, dynamic>? body]) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      return await (() async {
        final request = await client.openUrl(method, Uri.parse('${baseUrl ?? ApiService.defaultBaseUrl}$path'));
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close();
        final data = jsonDecode(await utf8.decodeStream(response)) as Map<String, dynamic>;
        if (response.statusCode != 200 || data['success'] != true) {
          throw HttpException('Routine sync failed (HTTP ${response.statusCode}).');
        }
        return data;
      })().timeout(const Duration(seconds: 20));
    } finally {
      client.close(force: true);
    }
  }
}
