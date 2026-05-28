import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Simple app launch or component test', (WidgetTester tester) async {
    // Build a simple mock container to make sure flutter test works
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('KYU App'),
        ),
      ),
    );
    expect(find.text('KYU App'), findsOneWidget);
  });
}
