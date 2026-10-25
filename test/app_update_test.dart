import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/services/app_update_service.dart';
import 'package:educal/screens/update/update_dialog.dart';

void main() {
  group('AppUpdateService Unit Tests', () {
    test('Version comparison correctly identifies newer versions', () {
      expect(AppUpdateService.isNewerVersion('v1.0.1', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('v1.1.0', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('v2.0.0', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('v1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('v0.9.9', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('ReleaseInfo parses GitHub Releases JSON response with APK asset', () {
      final json = {
        'tag_name': 'v1.0.1',
        'name': 'EduCal v1.0.1 - Trimester Calendar Update',
        'body': '- Added 26 official academic milestones\n- Direct .ics export to Downloads',
        'html_url': 'https://github.com/Hameme21/Edutools/releases/tag/v1.0.1',
        'published_at': '2026-10-25T12:00:00Z',
        'assets': [
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://github.com/Hameme21/Edutools/releases/download/v1.0.1/app-release.apk',
          }
        ]
      };

      final release = ReleaseInfo.fromJson(json);
      expect(release.tagName, equals('v1.0.1'));
      expect(release.name, equals('EduCal v1.0.1 - Trimester Calendar Update'));
      expect(release.body, contains('26 official academic milestones'));
      expect(release.htmlUrl, equals('https://github.com/Hameme21/Edutools/releases/tag/v1.0.1'));
      expect(release.apkDownloadUrl, equals('https://github.com/Hameme21/Edutools/releases/download/v1.0.1/app-release.apk'));
    });

    testWidgets('UpdateDialog renders version tag and action buttons', (tester) async {
      final release = ReleaseInfo(
        tagName: 'v1.0.1',
        name: 'EduCal v1.0.1',
        body: 'New update with trimester schedules and UIU degree domain filtering.',
        htmlUrl: 'https://github.com/Hameme21/Edutools/releases/tag/v1.0.1',
        apkDownloadUrl: 'https://github.com/Hameme21/Edutools/releases/download/v1.0.1/app-release.apk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(release: release),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update Available! 🚀'), findsOneWidget);
      expect(find.text('Version v1.0.1'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.textContaining('New update with trimester schedules'), findsOneWidget);
    });
  });
}
