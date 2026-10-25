import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/services/device_file_service.dart';

void main() {
  group('Storage Access Framework (SAF) Import Dialog Tests', () {
    testWidgets('UI Confirmation Dialog displays exact title, message, and actions', (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await DeviceFileService.showImportConfirmationDialog(context);
                },
                child: const Text('Import'),
              ),
            ),
          ),
        ),
      );

      // Tap Import button to launch UI Confirmation Dialog
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      // 1. Verify Dialog Title
      expect(find.text('Import Calendar'), findsOneWidget);

      // 2. Verify Dialog Message
      expect(
        find.text('Select an existing .ics or .json file from your storage to import your schedule.'),
        findsOneWidget,
      );

      // 3. Verify Positive and Negative Action Buttons
      expect(find.text('Choose File'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });

    testWidgets('Tapping Choose File confirms and dismisses dialog', (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await DeviceFileService.showImportConfirmationDialog(context);
                },
                child: const Text('Import'),
              ),
            ),
          ),
        ),
      );

      // Tap Import button
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      // Tap "Choose File"
      await tester.tap(find.text('Choose File'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and returned true
      expect(find.text('Import Calendar'), findsNothing);
      expect(dialogResult, isTrue);
    });
  });
}
