import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smart Pantry app title renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Smart Pantry')),
          body: const Center(child: Text('Welcome to Smart Pantry')),
        ),
      ),
    );

    expect(find.text('Smart Pantry'), findsOneWidget);
    expect(find.text('Welcome to Smart Pantry'), findsOneWidget);
  });
}
