import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/state/calendar_state.dart';
import 'package:educal/services/calendar_service.dart';
import 'package:educal/services/reminder_service.dart';
import 'package:educal/screens/setup/setup_screen.dart';
import 'package:educal/screens/setup/file_import_card.dart';

void main() {
  group('ICS Export & Mobile Import Widget Tests', () {
    late CalendarState state;

    setUp(() {
      state = CalendarState();
      state.loadSampleData();
    });

    testWidgets('ExportIcsDialog renders clean metadata and mobile export actions without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportIcsDialog(state: state),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export .ICS Calendar'), findsOneWidget);
      expect(find.textContaining('Holiday conflict logic applied'), findsOneWidget);
      expect(find.text('File Name'), findsOneWidget);
      expect(find.text('edutools_schedule.ics'), findsOneWidget);
      expect(find.text('Export .ICS to Mobile Files'), findsOneWidget);
      expect(find.text('Copy .ICS Data to Clipboard'), findsOneWidget);

      // Verify no raw code dump is shown on screen
      expect(find.text('BEGIN:VCALENDAR'), findsNothing);
    });

    testWidgets('SetupScreen displays Import .ICS File primary action button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupScreen(state: state),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Import .ICS File'), findsOneWidget);
      expect(find.text('Export .ICS'), findsOneWidget);
    });

    testWidgets('FileImportCard displays Pick from Device action button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileImportCard(
              title: 'Class Calendar / Routine File',
              description: 'Upload or pick from files',
              icon: Icons.schedule_rounded,
              themeColor: const Color(0xFF3B82F6),
              isClassRoutine: true,
              loadedCount: 5,
              onImport: (_) {},
              onLoadSample: () {},
              onClear: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pick from Device'), findsOneWidget);
      expect(find.text('Or Paste Text'), findsOneWidget);
    });
  });
}
