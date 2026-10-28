import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/update/update_dialog.dart';

class ReleaseInfo {
  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final String? apkDownloadUrl;
  final DateTime? publishedAt;

  ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    this.apkDownloadUrl,
    this.publishedAt,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    String? apkUrl;
    if (json['assets'] is List) {
      for (final asset in json['assets']) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
    }
    return ReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? (json['tag_name'] as String? ?? 'New Release'),
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? 'https://github.com/Hameme21/Edutools/releases',
      apkDownloadUrl: apkUrl,
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
    );
  }
}

class AppUpdateService {
  static const String currentVersion = '1.1.0.0';
  static const String repoOwner = 'Hameme21';
  static const String repoName = 'Edutools';
  static const String releasesUrl = 'https://github.com/Hameme21/Edutools/releases';

  /// Compare semantic version numbers. Returns true if remote is newer than current.
  static bool isNewerVersion(String remoteTag, String current) {
    final cleanRemote = remoteTag.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');
    final remoteParts = cleanRemote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final length = remoteParts.length > currentParts.length ? remoteParts.length : currentParts.length;
    for (int i = 0; i < length; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  /// Fetches the latest release information from GitHub Releases API
  static Future<ReleaseInfo?> getLatestRelease() async {
    if (kIsWeb) {
      return null;
    }
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest'),
      );
      request.headers.set('User-Agent', 'EduCal-Flutter-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();

      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final map = jsonDecode(content) as Map<String, dynamic>;
        return ReleaseInfo.fromJson(map);
      }
      return null;
    } catch (e) {
      debugPrint('[AppUpdateService] Check update error: $e');
      return null;
    }
  }

  /// Checks for updates and displays the pop-up notification if a newer version is available.
  static Future<void> checkForUpdates(BuildContext context, {bool isManual = false}) async {
    final release = await getLatestRelease();
    if (!context.mounted) return;

    if (release != null && isNewerVersion(release.tagName, currentVersion)) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => UpdateDialog(release: release),
      );
    } else if (isManual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(release == null
              ? 'Could not check updates from GitHub. You can visit releases directly.'
              : 'You are using the latest version ($currentVersion)! 🚀'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'GitHub',
            onPressed: () => openReleasePage(releasesUrl),
          ),
        ),
      );
    }
  }

  /// Launches the GitHub Release page of the new release directly in external browser / GitHub app
  static Future<void> openReleasePage(String url) async {
    final targetUrl = url.trim().isNotEmpty ? url.trim() : releasesUrl;
    final uri = Uri.parse(targetUrl);
    try {
      // First attempt externalApplication so Android launches external browser or GitHub App
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to platformDefault
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to open external application: $e');
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      } catch (inner) {
        debugPrint('[AppUpdateService] Secondary platform launch failed: $inner');
      }
    }
  }
}
