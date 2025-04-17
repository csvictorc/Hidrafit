import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInHelper {
  static final _googleSignIn = GoogleSignIn();

  static Future<User?> handleGoogleSignIn() async {
    try {

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }


      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );


      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
}
