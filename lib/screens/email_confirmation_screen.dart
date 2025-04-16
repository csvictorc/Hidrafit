import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key});

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  Timer? _emailCheckTimer;
  bool _isEmailVerified = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _checkVerification();
    _startEmailVerificationTimer();
  }

  void _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    setState(() {
      _isEmailVerified = user?.emailVerified ?? false;
    });

    if (_isEmailVerified) {
      _emailCheckTimer?.cancel();
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  void _startEmailVerificationTimer() {
    _emailCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerification());
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de verificação reenviado')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao reenviar o e-mail')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_outlined, size: 64, color: Colors.blueAccent),
                const SizedBox(height: 24),
                const Text(
                  'Verifique seu e-mail',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enviamos um link de verificação para seu e-mail. Clique no link para ativar sua conta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSending ? null : _resendVerificationEmail,
                    child: _isSending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Reenviar e-mail"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
