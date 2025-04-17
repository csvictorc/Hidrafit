import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../../helpers/google_sign_in_helper.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _errorMessage;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/videos/background.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _signInWithGoogle() async {
    final user = await GoogleSignInHelper.handleGoogleSignIn();
    if (user != null) {
      _goToHome();
    } else {
      _showError("Erro ao autenticar com Google");
    }
  }

  Future<void> _signInAsGuest() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      _goToHome();
    } on FirebaseAuthException catch (e) {
      _showError("Erro ao entrar como convidado: ${e.message}");
    } catch (_) {
      _showError("Erro ao entrar como convidado");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoController.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Bem-vindo ao HidraFit",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.asset(
                          'assets/google_logo.png',
                          height: 26,
                          width: 26,
                        ),
                        label: const Text(
                          "Continuar com o Google",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 6,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _signInAsGuest,
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Entrar como Convidado",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Já tem conta? Entrar",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
