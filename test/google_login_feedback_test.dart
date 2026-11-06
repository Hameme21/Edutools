import 'dart:async';

import 'package:educal/screens/auth/login_screen.dart';
import 'package:educal/state/calendar_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Use the plugin's platform boundary to simulate Android account-picker results.
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:educal/services/api_service.dart';

class _User implements User {
  _User(this.token);
  final Future<String?> token;
  @override
  String get email => 'student@example.com';
  @override
  String get displayName => 'Student';
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) => token;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credential implements UserCredential {
  _Credential(this.user);
  @override
  final User user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api extends ApiService {
  _Api(this.session);
  final Future<Map<String, dynamic>> session;
  int calls = 0;
  @override
  Future<Map<String, dynamic>> googleSession(String token,
      {Map<String, dynamic>? profile}) {
    calls++;
    return session;
  }
}

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

  Future<void> showLogin(WidgetTester tester,
      {Future<UserCredential> Function()? authenticate,
      ApiService? api,
      VoidCallback? onComplete}) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
          state: state,
          onLoginComplete: onComplete ?? () {},
          googleAuthenticator: authenticate,
          apiService: api),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
  }

  testWidgets(
      'after account selection progress remains visible until a server error and permits retry',
      (tester) async {
    final response = Completer<Map<String, dynamic>>();
    final api = _Api(response.future);
    await showLogin(tester,
        authenticate: () async =>
            _Credential(_User(Future.value('firebase-token'))),
        api: api);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Completing sign-in'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(api.calls, 1);
    response.completeError(Exception(
        'Registration storage is temporarily unavailable. Please try again shortly; you do not need to register again.'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Registration storage is temporarily unavailable'),
        findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(state.isLoggedIn, isFalse);
  });

  testWidgets('stalled backend session shows an error after a bounded wait',
      (tester) async {
    await showLogin(tester,
        authenticate: () async =>
            _Credential(_User(Future.value('firebase-token'))),
        api: _Api(Completer<Map<String, dynamic>>().future));
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    expect(find.textContaining('Google sign-in took too long'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'stalled Firebase token shows an error instead of silently waiting',
      (tester) async {
    await showLogin(tester,
        authenticate: () async =>
            _Credential(_User(Completer<String?>().future)));
    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();
    expect(find.textContaining('Google sign-in took too long'), findsOneWidget);
  });

  testWidgets(
      'registered Google account completes local login after server confirmation',
      (tester) async {
    var completed = 0;
    await showLogin(tester,
        authenticate: () async =>
            _Credential(_User(Future.value('firebase-token'))),
        api: _Api(Future.value({
          'success': true,
          'token': 'app-token',
          'student': {
            'email': 'student@example.com',
            'studentId': '123',
            'fullName': 'Student',
            'department': 'CSE'
          }
        })),
        onComplete: () => completed++);
    await tester.pumpAndSettle();
    expect(state.isLoggedIn, isTrue);
    expect(completed, 1);
  });

  testWidgets('cancelled account selection shows feedback and permits retry',
      (tester) async {
    platform.onAuthenticate = () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'Account reauth failed',
        );
    await showLogin(tester);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Google sign-in did not finish. Please try again or use email sign-in.'),
        findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(state.isLoggedIn, isFalse);
  });

  testWidgets(
      'stalled account selection times out and restores the login button',
      (tester) async {
    platform.onAuthenticate = () => Completer<AuthenticationResults>().future;
    await showLogin(tester);
    await tester.pump(const Duration(seconds: 91));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Google sign-in took too long. Check your connection and try again.'),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(state.isLoggedIn, isFalse);
  });

  testWidgets(
      'closing the login page during authentication does not set disposed state',
      (tester) async {
    final pending = Completer<AuthenticationResults>();
    platform.onAuthenticate = () => pending.future;
    await showLogin(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.completeError(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
