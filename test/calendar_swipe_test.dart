import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/screens/dashboard/calendar_view_widget.dart';
import 'package:educal/services/calendar_service.dart';

void main() {
  group('Calendar Swipe Tests', () {
    testWidgets('Swiping left on calendar advances to next month', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final calendarService = CalendarService();
      final initialDate = DateTime(2026, 3, 15); // March 2026
      DateTime selectedDate = initialDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarViewWidget(
                selectedDate: selectedDate,
                onDateSelected: (d) => selectedDate = d,
                calendarService: calendarService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify March 2026 is displayed
      expect(find.text('March 2026'), findsOneWidget);

      // Swipe Left (drag right to left)
      await tester.drag(find.byType(CalendarViewWidget), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Should now show April 2026
      expect(find.text('April 2026'), findsOneWidget);

      // Swipe Right (drag left to right)
      await tester.drag(find.byType(CalendarViewWidget), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Should return to March 2026
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('Tapping any date cell selects that date', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final calendarService = CalendarService();
      DateTime selectedDate = DateTime(2026, 9, 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarViewWidget(
                selectedDate: selectedDate,
                onDateSelected: (d) => selectedDate = d,
                calendarService: calendarService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on day 15
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      expect(selectedDate.day, equals(15));
      expect(selectedDate.month, equals(9));
      expect(selectedDate.year, equals(2026));
    });
  });
}
