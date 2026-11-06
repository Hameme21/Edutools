import 'dart:async';
import 'dart:io';

import 'package:educal/screens/update/update_dialog.dart';
import 'package:educal/services/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ReleaseInfo release(String tag) => ReleaseInfo(
      tagName: tag,
      name: 'Edutools $tag',
      body: 'Update fixes',
      htmlUrl: AppUpdateService.releasesUrl,
    );

void main() {
  test('installed version follows the Flutter build name', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version: ([^+\s]+)', multiLine: true)
        .firstMatch(pubspec)!
        .group(1);
    expect(AppUpdateService.currentVersion, version);
  });

  test('build metadata and invalid release tags cannot create false updates',
      () {
    for (final tag in [
      'v1.2.1',
      'v1.2.1+999',
      'v1.2.0',
      'v1.2.1-beta.1',
      '',
      'release-1.2.2'
    ]) {
      expect(AppUpdateService.isNewerVersion(tag, '1.2.1+121'), isFalse,
          reason: tag);
    }
    expect(AppUpdateService.isNewerVersion('v1.2.2+1', '1.2.1+121'), isTrue);
    expect(AppUpdateService.isNewerVersion('v1.2.2', ''), isFalse);
    expect(AppUpdateService.isNewerVersion('v1.10.0', '1.9.9'), isTrue);
  });

  for (final tag in ['v1.2.1', 'v1.2.1+999', 'v1.2.0', 'invalid', null]) {
    testWidgets('automatic check stays silent for $tag', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
        context = ctx;
        return const Scaffold(body: Text('Dashboard'));
      })));
      await AppUpdateService.checkForUpdates(context,
          installedVersion: '1.2.1',
          releaseLoader: () async => tag == null ? null : release(tag));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  testWidgets(
      'only a newer release opens a dialog and concurrent checks cannot duplicate it',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
      context = ctx;
      return const Scaffold(body: Text('Dashboard'));
    })));
    final response = Completer<ReleaseInfo?>();
    final pending = AppUpdateService.checkForUpdates(context,
        installedVersion: '1.2.1', releaseLoader: () => response.future);
    var duplicateRequests = 0;
    await AppUpdateService.checkForUpdates(context, releaseLoader: () async {
      duplicateRequests++;
      return release('v1.2.2');
    });
    response.complete(release('v1.2.2'));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateDialog), findsOneWidget);
    expect(duplicateRequests, 0);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    await pending;
  });
}
