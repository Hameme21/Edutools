import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInSession {
  static Future<void>? _initialization;
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
