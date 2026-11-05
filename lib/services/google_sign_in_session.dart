import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInSession {
  static Future<void>? _initialization;
  static GoogleSignInAccount? _account;

  static const identityKey = 'edutools_google_identity';

  static Future<void> remember(GoogleSignInAccount account) async {
    _account = account;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(identityKey, jsonEncode({'id': account.id, 'email': account.email.toLowerCase()}));
  }

  static Future<void> clear() async {
    _account = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(identityKey);
  }

  static Future<({String id, String email})> identityFor(String email) async {
    final expected = email.trim().toLowerCase();
    await initialize();
    if (_account?.email.toLowerCase() == expected) return (id: _account!.id, email: expected);
    // Reuse Firebase's Google provider identity without opening a sign-in UI.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email?.toLowerCase() == expected) {
        for (final provider in user!.providerData) {
          final id = provider.uid;
          if (provider.providerId == 'google.com' && id != null && id.isNotEmpty) {
            return (id: id, email: expected);
          }
        }
      }
    } catch (_) { /* Non-Firebase sessions can use the last explicit Google login. */ }
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = jsonDecode(prefs.getString(identityKey) ?? 'null');
      if (saved is Map && saved['email'] == expected && saved['id'] is String && (saved['id'] as String).isNotEmpty) {
        return (id: saved['id'] as String, email: expected);
      }
    } catch (_) { /* Invalid identity metadata is never used for authorization. */ }
    throw StateError('Your Google session needs reconnecting. Sign in with Google using $email, then try sync again.');
  }

  static Future<void> initialize() async {
    try {
      await (_initialization ??= GoogleSignIn.instance.initialize(
        serverClientId: '1097225985625-1tgbd5ie7vl09cda6tj2iulnoqsu9fhq.apps.googleusercontent.com',
      )).timeout(const Duration(seconds: 15));
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }
}
