import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInHelper {
  static final _googleSignIn = GoogleSignIn();

  static Future<User?> handleGoogleSignIn() async {
    try {
      print("Iniciando o Google Sign-In...");

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Usuário não selecionou uma conta Google.");
        return null;
      }

      print("Usuário autenticado: ${googleUser.email}");

      final googleAuth = await googleUser.authentication;
      print("Autenticação do Google concluída.");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Tentando fazer login no Firebase com o Google...");

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print("Usuário logado com sucesso no Firebase: ${userCredential.user?.email}");

      return userCredential.user;
    } catch (e) {
      print("Erro durante o login: $e");
      rethrow;
    }
  }
}
