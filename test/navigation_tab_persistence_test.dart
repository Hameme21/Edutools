import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/screens/main_screen.dart';
import 'package:educal/state/calendar_state.dart';

void main() {
  testWidgets('Searching notices never resets active tab back to Dashboard', (WidgetTester tester) async {
    final state = CalendarState();
    await tester.pumpWidget(MaterialApp(home: MainScreen(state: state)));
    await tester.pumpAndSettle();

    // Verify currently on Dashboard (tab index 0)
    expect(state.currentTabIndex, 0);
    expect(find.text('Classes Today'), findsOneWidget);

    // Tap Academic Notices (tab index 1)
    await tester.tap(find.text('Academic Notices'));
    await tester.pumpAndSettle();

    expect(state.currentTabIndex, 1);
    expect(find.text('Search holidays, fees, exams...'), findsOneWidget);

    // Enter search text "fee" in search box
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'fee');
    await tester.pumpAndSettle();

    // Verify still on Academic Notices tab (index 1), NOT reset to Dashboard
    expect(state.currentTabIndex, 1);
    expect(find.text('Search holidays, fees, exams...'), findsOneWidget);
    expect(find.text('Classes Today'), findsNothing);

    // Verify search query filtered notices
    expect(state.noticeSearchQuery, 'fee');
    expect(state.upcomingNotices.isNotEmpty, isTrue);

    // Clear search using clear icon
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    expect(state.currentTabIndex, 1);
    expect(state.noticeSearchQuery, '');
  });

  testWidgets('Going from one date to another updates selection smoothly without snapping', (WidgetTester tester) async {
    final state = CalendarState();
    await tester.pumpWidget(MaterialApp(home: MainScreen(state: state)));
    await tester.pumpAndSettle();

    // Select date
    state.selectDate(DateTime(2026, 9, 4));
    await tester.pumpAndSettle();

    expect(state.selectedDate.day, 4);

    state.selectDate(DateTime(2026, 9, 14));
    await tester.pumpAndSettle();

    expect(state.selectedDate.day, 14);
  });
}
