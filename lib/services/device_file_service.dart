import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const MethodChannel _safChannel = MethodChannel('com.example.educal/saf_picker');

  /// Requirement 1: UI Confirmation Dialog
  /// Shows confirmation dialog before opening the system file picker:
  /// - Title: "Import Calendar"
  /// - Message: "Select an existing .ics or .json file from your storage to import your schedule."
  /// - Actions: "Choose File" (positive) and "Cancel" (negative).
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

  /// Launches the Storage Access Framework (SAF) or native OS document picker
  /// without requesting obsolete READ/WRITE_EXTERNAL_STORAGE permissions.
  static Future<DevicePickedFile?> pickFileFromExplorer({
    required BuildContext context,
    String? title,
    List<String> allowedExtensions = const ['ics', 'csv', 'json', 'txt'],
  }) async {
    // 1. Show UI Confirmation Dialog
    final confirmed = await showImportConfirmationDialog(context);
    if (!confirmed) {
      return null;
    }

    // 2. Launch Storage Access Framework (SAF) on Android or Native Picker on Desktop
    if (Platform.isAndroid) {
      return await _pickUsingAndroidSaf();
    } else if (Platform.isWindows) {
      return await _openWindowsOpenFileDialog(title: title);
    } else {
      return await _openFallbackFilePicker();
    }
  }

  /// Android Storage Access Framework (SAF) invocation via MethodChannel
  static Future<DevicePickedFile?> _pickUsingAndroidSaf() async {
    try {
      final dynamic result = await _safChannel.invokeMethod('launchSafPickerDirectly');
      if (result != null && result is Map) {
        final fileName = result['fileName'] as String? ?? 'imported_calendar.ics';
        final filePath = result['filePath'] as String? ?? '';
        final content = result['content'] as String? ?? '';
        final size = (result['sizeInBytes'] as num?)?.toInt() ?? content.length;

        if (content.isNotEmpty) {
          return DevicePickedFile(
            fileName: fileName,
            filePath: filePath,
            content: content,
            sizeInBytes: size,
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Android SAF Picker PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('Android SAF Picker error: $e');
    }
    return null;
  }

  /// Launches the native Windows File Explorer OpenFileDialog
  static Future<DevicePickedFile?> _openWindowsOpenFileDialog({String? title}) async {
    try {
      final dialogTitle = title ?? 'Select Class Routine or Academic Calendar File';
      final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dlg = New-Object System.Windows.Forms.OpenFileDialog
\$dlg.Title = "$dialogTitle"
\$dlg.Filter = "Calendar & Routine Files (*.ics;*.csv;*.json;*.txt)|*.ics;*.csv;*.json;*.txt|iCalendar Files (*.ics)|*.ics|JSON Files (*.json)|*.json|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
\$dlg.RestoreDirectory = \$true
if (\$dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    Write-Output \$dlg.FileName
}
''';

      final result = await Process.run('powershell', ['-NoProfile', '-Command', script]);
      final output = result.stdout.toString().trim();

      if (output.isNotEmpty) {
        final filePath = output.split('\n').last.trim();
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final fileName = file.uri.pathSegments.last;
          final size = await file.length();

          return DevicePickedFile(
            fileName: fileName,
            filePath: filePath,
            content: content,
            sizeInBytes: size,
          );
        }
      }
    } catch (e) {
      debugPrint('Windows File Explorer error: $e');
    }
    return null;
  }

  static Future<DevicePickedFile?> _openFallbackFilePicker() async {
    return null;
  }
}
