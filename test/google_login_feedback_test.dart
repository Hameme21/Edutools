import 'dart:async';

import 'package:educal/screens/auth/login_screen.dart';
import 'package:educal/state/calendar_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Use the plugin's platform boundary to simulate Android account-picker results.
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _GooglePlatform extends GoogleSignInPlatform {
  Future<AuthenticationResults> Function()? onAuthenticate;

  @override
  Future<void> init(InitParameters params) async {}

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) {
    return onAuthenticate!();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _GooglePlatform platform;
  late CalendarState state;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platform = _GooglePlatform();
    GoogleSignInPlatform.instance = platform;
    state = CalendarState();
  });

  tearDown(() => state.dispose());

  Future<void> showLogin(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(state: state, onLoginComplete: () {}),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
  }

  testWidgets('cancelled account selection shows feedback and permits retry', (tester) async {
    platform.onAuthenticate = () async => throw const GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
      description: 'Account reauth failed',
    );
    await showLogin(tester);
    await tester.pumpAndSettle();
    expect(find.text('Google sign-in did not finish. Please try again or use email sign-in.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(state.isLoggedIn, isFalse);
  });

  testWidgets('stalled account selection times out and restores the login button', (tester) async {
    platform.onAuthenticate = () => Completer<AuthenticationResults>().future;
    await showLogin(tester);
    await tester.pump(const Duration(seconds: 91));
    await tester.pumpAndSettle();
    expect(find.text('Google sign-in took too long. Check your connection and try again.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(state.isLoggedIn, isFalse);
  });

  testWidgets('closing the login page during authentication does not set disposed state', (tester) async {
    final pending = Completer<AuthenticationResults>();
    platform.onAuthenticate = () => pending.future;
    await showLogin(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.completeError(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
