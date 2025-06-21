import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/pages/login_page.dart';
import 'package:gymfit/services/auth_interface.dart';

class MockLoginAuthService implements AuthInterface {
  bool shouldThrow = false;
  bool wasCalled = false;
  late Exception exception;

  @override
  Future<void> login(String email, String password) async {
    wasCalled = true;
    if (shouldThrow) throw exception;
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> register(String email, String password) async {}
}

void main() {
  group('LoginPage Tests', () {
    testWidgets('TC001 - shows error on invalid credentials', (tester) async {
      final mock =
          MockLoginAuthService()
            ..shouldThrow = true
            ..exception = Exception('invalid-credential');

      await tester.pumpWidget(
        MaterialApp(home: LoginPage(onTap: () {}, authService: mock)),
      );

      await tester.enterText(
        find.byKey(const Key('emailField')),
        'wrong@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'wrongpass',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Login failed:'), findsOneWidget);
    });

    testWidgets('TC002 - handles unexpected error', (tester) async {
      final mock =
          MockLoginAuthService()
            ..shouldThrow = true
            ..exception = Exception('some-random-error');

      await tester.pumpWidget(
        MaterialApp(home: LoginPage(onTap: () {}, authService: mock)),
      );

      await tester.enterText(
        find.byKey(const Key('emailField')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'validpass',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Login failed:'), findsOneWidget);
    });

    testWidgets('TC003 - Google sign-in button exists', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage(onTap: () {})));

      expect(find.byType(Image), findsWidgets);
    });
  });
}
