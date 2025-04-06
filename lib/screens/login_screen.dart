import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../helpers/google_sign_in_helper.dart';
import '../../helpers/login_helper.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _goToHome() {
    Navigator.of(context).pushReplacementNamed('/main');
  }


  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Preencha todos os campos");
      return;
    }

    try {
      final user = await LoginHelper.signInWithEmail(email, password);
      if (user != null) {
        _goToHome();
      } else {
        _showError("Erro ao fazer login");
      }
    } catch (_) {
      _showError("Erro ao fazer login");
    }
  }

  Future<void> _signInWithGoogle() async {
    final user = await GoogleSignInHelper.handleGoogleSignIn();
    if (user != null) {
      _goToHome();
    } else {
      _showError("Erro no login com Google");
    }
  }

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _goToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "E-mail"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Senha"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signInWithEmail,
              child: const Text("Entrar"),
            ),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text("Entrar com Google"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: const Text("Esqueci minha senha"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text("Não tem conta? Cadastre-se"),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
