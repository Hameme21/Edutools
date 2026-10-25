import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DevicePickedFile {
  final String fileName;
  final String filePath;
  final String content;
  final int sizeInBytes;

  DevicePickedFile({
    required this.fileName,
    required this.filePath,
    required this.content,
    required this.sizeInBytes,
  });

  double get sizeInKb => sizeInBytes / 1024.0;
  double get sizeInMb => sizeInBytes / (1024.0 * 1024.0);
}

class DeviceFileService {
  /// Exports .ICS calendar data directly to device storage / Downloads folder
  static Future<String?> exportIcsToFile({
    required String icsContent,
    String fileName = 'edutools_schedule.ics',
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(icsContent));

    // 1. Try prompt user with native Save File dialog if supported
    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Save Calendar (.ics) to Device',
        fileName: fileName,
        bytes: bytes,
      );
      if (savedUri != null) {
        return savedUri.toFilePath();
      }
    } catch (_) {}

    // 2. Direct directory writing (Downloads / Documents / App files)
    final List<Directory> targetDirs = [];
    try {
      if (!kIsWeb && Platform.isAndroid) {
        targetDirs.add(Directory('/storage/emulated/0/Download'));
        targetDirs.add(Directory('/storage/emulated/0/Documents'));
        targetDirs.add(Directory('/sdcard/Download'));
        targetDirs.add(Directory('/storage/emulated/0/Android/data/com.example.educal/files'));
        targetDirs.add(Directory('/data/user/0/com.example.educal/files'));
      } else if (!kIsWeb && Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          targetDirs.add(Directory('$userProfile\\Downloads'));
          targetDirs.add(Directory('$userProfile\\Documents'));
          targetDirs.add(Directory('$userProfile\\Desktop'));
        }
      }
    } catch (_) {}

    targetDirs.add(Directory('.'));

    for (final dir in targetDirs) {
      try {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final separator = Platform.isWindows ? '\\' : '/';
        final file = File('${dir.path}$separator$fileName');
        file.writeAsBytesSync(bytes, flush: true);
        return file.path;
      } catch (e) {
        debugPrint('[DeviceFileService] Could not write to ${dir.path}: $e');
      }
    }

    return null;
  }

  /// Picks a calendar/routine file (.ics, .json, .csv, .txt) directly from mobile device files
  static Future<DevicePickedFile?> pickFileFromDevice({
    List<String> allowedExtensions = const ['ics', 'json', 'csv', 'txt'],
  }) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (files.isNotEmpty) {
        final platformFile = files.first;
        final content = await platformFile.xFile.readAsString();
        final size = await platformFile.length() ?? content.length;

        if (content.isNotEmpty) {
          return DevicePickedFile(
            fileName: platformFile.name,
            filePath: platformFile.path ?? platformFile.name,
            content: content,
            sizeInBytes: size,
          );
        }
      }
    } catch (e) {
      debugPrint('[DeviceFileService] pickFileFromDevice error: $e');
    }
    return null;
  }

  /// Launches the native system file explorer / document picker (backward compatible)
  static Future<DevicePickedFile?> pickFileFromExplorer({
    BuildContext? context,
    String? title,
    List<String> allowedExtensions = const ['ics', 'csv', 'json', 'txt'],
  }) async {
    if (context != null) {
      final confirmed = await showImportConfirmationDialog(context);
      if (!confirmed) return null;
    }
    return await pickFileFromDevice(allowedExtensions: allowedExtensions);
  }

  /// Shows confirmation dialog before opening the system file picker
  static Future<bool> showImportConfirmationDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.file_open_rounded, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Import Calendar',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Select an existing .ics or .json file from your storage to import your schedule.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Choose File'),
          ),
        ],
      ),
    );

    return result == true;
  }
}
