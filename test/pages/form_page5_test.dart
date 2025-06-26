import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/pages/body_data/form_page5.dart';

void main() {
  testWidgets('BMI Test 1: Underweight', (WidgetTester tester) async {
    // BMI = 45 / (1.7^2) = 15.6
    await tester.pumpWidget(const MaterialApp(
      home: FormPage5(mockHeight: 170, mockWeight: 45),
    ));
    await tester.pumpAndSettle();

    expect(find.text('15.6'), findsOneWidget);
    expect(find.text("You need more nutrition and rest"), findsOneWidget);
  });

  testWidgets('BMI Test 2: Normal weight', (WidgetTester tester) async {
    // BMI = 70 / (1.7^2) = 24.2
    await tester.pumpWidget(const MaterialApp(
      home: FormPage5(mockHeight: 170, mockWeight: 70),
    ));
    await tester.pumpAndSettle();

    expect(find.text('24.2'), findsOneWidget);
    expect(find.text("You're in good shape! Keep it up!"), findsOneWidget);
  });

  testWidgets('BMI Test 3: Overweight', (WidgetTester tester) async {
    // BMI = 80 / (1.7^2) = 27.7
    await tester.pumpWidget(const MaterialApp(
      home: FormPage5(mockHeight: 170, mockWeight: 80),
    ));
    await tester.pumpAndSettle();

    expect(find.text('27.7'), findsOneWidget);
    expect(find.text("You need a bit more exercise to get in shape"), findsOneWidget);
  });

  testWidgets('BMI Test 4: Obese', (WidgetTester tester) async {
    // BMI = 100 / (1.7^2) = 34.6
    await tester.pumpWidget(const MaterialApp(
      home: FormPage5(mockHeight: 170, mockWeight: 100),
    ));
    await tester.pumpAndSettle();

    expect(find.text('34.6'), findsOneWidget);
    expect(find.text("Time to adopt a healthier lifestyle"), findsOneWidget);
  });
}
