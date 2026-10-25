import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/main.dart';

void main() {
  group('Display Ratio & Window Inset Responsive Layout Tests', () {
    testWidgets('Dashboard renders with zero overflow on short 16:9 screen (360x640)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const EduCalApp());
      await tester.pumpAndSettle();

      // Check key sections are loaded
      expect(find.text('Classes Today'), findsOneWidget);
      expect(find.text('Holidays Left'), findsOneWidget);
      expect(find.text('Fee Deadlines'), findsOneWidget);

      // Verify scrollability on short screens
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // No overflow exceptions thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dashboard renders with zero overflow on narrow screen (320x568)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const EduCalApp());
      await tester.pumpAndSettle();

      // In narrow screen, stats row stacks into vertical column safely
      expect(find.text('Classes Today'), findsOneWidget);
      expect(find.text('Holidays Left'), findsOneWidget);
      expect(find.text('Fee Deadlines'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('App renders cleanly under high font accessibility scaling (1.5x)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(const EduCalApp());
      await tester.pumpAndSettle();

      // 1. Dashboard Tab
      expect(find.text('Dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Dashboard tab had overflow');

      // 2. Academic Notices Tab
      await tester.tap(find.text('Academic Notices'));
      await tester.pumpAndSettle();
      expect(find.text('All Notices'), findsOneWidget);
      final err = tester.takeException();
      if (err is FlutterError) {
        debugPrint(err.toStringDeep());
      }
      expect(err, isNull, reason: 'Notices tab had overflow');

      // 3. Setup Tab
      await tester.tap(find.text('Class Setup'));
      await tester.pumpAndSettle();
      expect(find.text('Official 2026 Academic Calendar'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Setup tab had overflow');
    });
  });
}
