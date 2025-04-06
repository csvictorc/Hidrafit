import 'package:firebase_auth/firebase_auth.dart';

class LoginHelper {
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
