import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/pages/body_data/form_page6.dart';

void main() {
  group('FormPage6 Weight Difference Tests', () {
    testWidgets('Test Case 1: +5.0 kg difference shown in green', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FormPage6(userWeight: 65.0, mockTargetWeight: 70.0),
        ),
      );

      await tester.pump();

      expect(find.text('+5.0 kg'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('+5.0 kg'));
      expect(textWidget.style?.color, Colors.green);
    });

    testWidgets('Test Case 2: -3.5 kg difference shown in red', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FormPage6(userWeight: 68.5, mockTargetWeight: 65.0),
        ),
      );

      await tester.pump();

      expect(find.text('-3.5 kg'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('-3.5 kg'));
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('Test Case 3: 0.0 kg difference shown in green', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FormPage6(userWeight: 70.0, mockTargetWeight: 70.0),
        ),
      );

      await tester.pump();

      expect(find.text('0.0 kg'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('0.0 kg'));
      expect(
        textWidget.style?.color,
        Colors.green,
      ); // Still green, indicating no weight loss/gain needed
    });
  });
}
