import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _message;
  Color? _messageColor;

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _message = "Digite seu e-mail";
        _messageColor = Colors.red.shade700;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _message = "E-mail de recuperação enviado! Cheque a caixa de Spam";
        _messageColor = Colors.green.shade700;
      });
    } catch (_) {
      setState(() {
        _message = "Erro ao enviar e-mail. Verifique o endereço digitado.";
        _messageColor = Colors.red.shade700;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Senha")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "E-mail"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendPasswordResetEmail,
              child: const Text("Enviar e-mail de recuperação"),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _message!,
                  style: TextStyle(color: _messageColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
