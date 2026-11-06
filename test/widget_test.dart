import 'package:flutter_test/flutter_test.dart';
import 'package:educal/main.dart';

void main() {
  testWidgets('EduCalApp builds and renders 3 navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const EduCalApp());
    await tester.pumpAndSettle();

    // Verify 3 navigation tabs
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Notices'), findsOneWidget);
    expect(find.text('Class Setup'), findsOneWidget);

    // Switch to Academic Notices tab
    await tester.tap(find.text('Notices'));
    await tester.pumpAndSettle();
    expect(find.text('Add Notice'), findsOneWidget);

    // Switch to Class Setup tab
    await tester.tap(find.text('Class Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Holiday Conflict Auto-Resolver Active'), findsOneWidget);
  });
}
