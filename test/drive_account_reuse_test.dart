import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Exercise the SDK at its native platform boundary without Google UI or network.
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:educal/services/google_sign_in_session.dart';
import 'package:educal/services/google_drive_sync_service.dart';

class AccountPlatform extends GoogleSignInPlatform {
  int interactiveCalls = 0;
  int restoreCalls = 0;
  bool granted = true;
  AuthenticationResults? restored;
  final requests = <AuthorizationRequestDetails>[];
  static const result = AuthenticationResults(
    user: GoogleSignInUserData(email:'student@example.com', id:'google-student'),
    authenticationTokens: AuthenticationTokenData(idToken:'fake-id-token'),
  );
  @override
  Future<void> init(InitParameters params) async {}
  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) async {
    interactiveCalls++; return result;
  }
  @override
  Future<AuthenticationResults?> attemptLightweightAuthentication(AttemptLightweightAuthenticationParameters params) async {
    restoreCalls++; return restored;
  }
  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(ClientAuthorizationTokensForScopesParameters params) async {
    requests.add(params.request);
    if (!granted && !params.request.promptIfUnauthorized) return null;
    return const ClientAuthorizationTokenData(accessToken:'drive-access');
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  late AccountPlatform platform;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GoogleSignInSession.clear();
    platform = AccountPlatform();
    GoogleSignInPlatform.instance = platform;
  });
  test('sync reuses the signed-in account and existing Drive grant without an account picker', () async {
    await GoogleSignInSession.initialize();
    await GoogleSignInSession.remember(await GoogleSignIn.instance.authenticate());
    final drive = GoogleDriveSyncService();
    await drive.ensureAccess(email:'student@example.com');
    await drive.ensureAccess(email:'student@example.com');
    expect(platform.interactiveCalls, 1); // The original login only.
    expect(platform.restoreCalls, 0);
    expect(platform.requests, hasLength(1));
    expect(platform.requests.single.promptIfUnauthorized, isFalse);
    expect(platform.requests.single.userId, 'google-student');
    expect(platform.requests.single.email, 'student@example.com');
    expect(platform.requests.single.scopes, ['https://www.googleapis.com/auth/drive.file']);
  });
  test('after app restart saved Google identity is reused without any authentication flow', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GoogleSignInSession.identityKey, jsonEncode({'id':'google-student','email':'student@example.com'}));
    await GoogleDriveSyncService().ensureAccess(email:'student@example.com');
    expect(platform.restoreCalls, 0);
    expect(platform.interactiveCalls, 0);
    expect(platform.requests.single.promptIfUnauthorized, isFalse);
  });
  test('first Drive permission request is bound to the same account, not an account chooser', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GoogleSignInSession.identityKey, jsonEncode({'id':'google-student','email':'student@example.com'}));
    platform.granted = false;
    await GoogleDriveSyncService().ensureAccess(email:'student@example.com');
    expect(platform.interactiveCalls, 0);
    expect(platform.requests.map((r) => r.promptIfUnauthorized), [false, true]);
    expect(platform.requests.every((r) => r.userId == 'google-student' && r.email == 'student@example.com'), isTrue);
  });
  test('expired cached Drive token is refreshed for the signed-in account', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GoogleSignInSession.identityKey, jsonEncode({'id':'google-student','email':'student@example.com'}));
    final drive = GoogleDriveSyncService();
    drive.setAccessToken('expired', email:'student@example.com', expiresAt:DateTime(2000));
    await drive.ensureAccess(email:'student@example.com');
    expect(platform.interactiveCalls, 0);
    expect(platform.requests, hasLength(1));
  });
  test('missing or different Google session cannot silently sync the wrong account', () async {
    final drive = GoogleDriveSyncService();
    await expectLater(drive.ensureAccess(email:'student@example.com'), throwsStateError);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GoogleSignInSession.identityKey, jsonEncode({'id':'google-student','email':'student@example.com'}));
    await expectLater(drive.ensureAccess(email:'different@example.com'), throwsStateError);
    expect(platform.interactiveCalls, 0);
    expect(platform.requests, isEmpty);
  });
}
