import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../bin/server.dart';

void main() {
  group('Full-Stack Backend API Tests', () {
    HttpServer? server;
    const testPort = 3097;
    final client = HttpClient();

    setUpAll(() async {
      // Start in-process server
      server = await startServer(port: testPort);
    });

    Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$testPort$path'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
      final res = await req.close();
      final respBody = await utf8.decodeStream(res);
      return jsonDecode(respBody) as Map<String, dynamic>;
    }

    Future<Map<String, dynamic>> get(String path) async {
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort$path'));
      final res = await req.close();
      final respBody = await utf8.decodeStream(res);
      return jsonDecode(respBody) as Map<String, dynamic>;
    }

    test('Health Check API returns healthy status', () async {
      final res = await get('/api/health');
      expect(res['status'], equals('healthy'));
      expect(res['features']['universityEmailOtp'], equals('active'));
      expect(res['features']['fileUploadLimits'], equals('10MB enforced'));
    });

    test('University Email Validation rejects non-educational emails', () async {
      final res = await post('/api/auth/request-otp', {'email': 'user@gmail.com'});
      expect(res['success'], isFalse);
      expect(res['error'], contains('restricted to institutional university email'));
    });

    test('University Email Validation accepts .edu and .ac.bd emails with 6-digit OTP', () async {
      final res = await post('/api/auth/request-otp', {'email': 'student@stanford.edu'});
      expect(res['success'], isTrue);
      expect(res['expiresInSeconds'], equals(300));
      expect(res['devOtp'], isNotNull);
      expect(res['devOtp'].toString().length, equals(6));
    });

    test('OTP Verification issues session token and enforces single-use', () async {
      const email = 'alex.chen@mit.edu';
      final reqRes = await post('/api/auth/request-otp', {'email': email});
      final otp = reqRes['devOtp'] as String;

      // Verify correct OTP
      final verifyRes = await post('/api/auth/verify-otp', {'email': email, 'otp': otp});
      expect(verifyRes['success'], isTrue);
      expect(verifyRes['token'], isNotNull);
      expect(verifyRes['student']['email'], equals(email));

      // Attempt single-use reuse -> must fail
      final reuseRes = await post('/api/auth/verify-otp', {'email': email, 'otp': otp});
      expect(reuseRes['success'], isFalse);
    });

    test('Calendar Sync Status Engine checks events and detects status', () async {
      const email = 'alex.chen@mit.edu';
      final syncRes = await post('/api/calendar/sync', {
        'email': email,
        'events': [
          {
            'courseCode': 'CSE-201',
            'subject': 'Data Structures',
            'dayOfWeek': 1,
            'startTime': '09:00',
            'endTime': '10:30',
            'room': 'Lab 402',
          }
        ]
      });
      expect(syncRes['success'], isTrue);
      expect(syncRes['syncStatus']['syncHealth'], equals('PERFECT'));
      expect(syncRes['syncStatus']['matchRatePercent'], equals(100.0));

      final statusRes = await get('/api/calendar/sync-status?email=$email');
      expect(statusRes['totalSynced'], equals(1));
      expect(statusRes['matchRatePercent'], equals(100.0));
    });

    tearDownAll(() async {
      client.close();
      if (server != null) await server!.close(force: true);
    });
  });
}
