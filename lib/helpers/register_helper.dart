import 'package:firebase_auth/firebase_auth.dart';

class RegisterHelper {
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  static Future<User?> registerUser(String name, String email, String password) async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);
    return credential.user;
  }
}
