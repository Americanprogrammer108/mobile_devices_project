import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_devices_project/features/history/history_screen.dart';

void main() {
  testWidgets('History screen displays correctly', (WidgetTester tester) async {
    // Load the History screen
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));

    // Check the screen title
    expect(find.text('History'), findsOneWidget);

    // Check the filter buttons
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Searched'), findsOneWidget);
    expect(find.text('Scanned'), findsOneWidget);
    expect(find.text('Added'), findsOneWidget);
  });

  testWidgets('History filter works', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));

    // Select the Scanned filter
    await tester.tap(find.text('Scanned'));
    await tester.pumpAndSettle();

    // Scanned groceries should be displayed
    expect(find.text('Milk 2%'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);

    // Searched groceries should be hidden
    expect(find.text('Banana'), findsNothing);
  });
}
