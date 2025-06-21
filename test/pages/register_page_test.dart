import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/pages/register_page.dart';
import 'package:gymfit/services/auth_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockAuthService implements AuthInterface {
  bool shouldThrow = false;
  late FirebaseAuthException exception;

  @override
  Future<void> register(String email, String password) async {
    if (shouldThrow) throw exception;
  }
}

void main() {
  group('RegisterPage Tests with AuthInterface', () {
    testWidgets('shows error if passwords do not match', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: RegisterPage(onTap: () {}),
      ));

      await tester.enterText(find.byKey(const Key('emailField')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('passwordField')), 'pass123');
      await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'pass456');

      await tester.tap(find.text('Sign Up Now'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords don’t match'), findsOneWidget);
    });

    testWidgets('shows weak-password error from mock auth', (tester) async {
      final mock = MockAuthService()
        ..shouldThrow = true
        ..exception = FirebaseAuthException(code: 'weak-password');

      await tester.pumpWidget(MaterialApp(
        home: RegisterPage(onTap: () {}, authService: mock),
      ));

      await tester.enterText(find.byKey(const Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(const Key('passwordField')), '123');
      await tester.enterText(find.byKey(const Key('confirmPasswordField')), '123');

      await tester.tap(find.text('Sign Up Now'));
      await tester.pumpAndSettle();

      expect(find.text('Password should be at least 6 characters.'), findsOneWidget);
    });
  });
}
