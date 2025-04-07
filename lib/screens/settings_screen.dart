import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _waterReminderEnabled = true;
  bool _goalCompleteNotificationEnabled = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterReminderEnabled = prefs.getBool('water_reminder_enabled') ?? true;
      _goalCompleteNotificationEnabled = prefs.getBool('goal_notification_enabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Desconecta do Google se estiver logado por ele
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Erro ao sair: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao sair da conta.')),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja deletar sua conta? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Tenta deletar o usuário
      await user.delete();

      // Se logado com Google, desconecta também
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você precisa se autenticar novamente para deletar sua conta.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar conta: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao deletar conta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado ao deletar conta.')),
      );
    }
  }

  Future<void> _openGithubRepo() async {
    final Uri url = Uri.parse('https://github.com/csvictorc/Hydrafit/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  }

  Widget _buildNeumorphicButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black12,
              offset: Offset(1, 3),
              blurRadius: 1,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black45),
            const SizedBox(width: 8),
            Stack(
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1
                      ..color = Colors.black45,
                  ),
                ),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Lembretes de hidratação'),
              subtitle: const Text('Receber notificações para beber água'),
              activeColor: Colors.lightBlueAccent,
              value: _waterReminderEnabled,
              onChanged: (value) {
                setState(() => _waterReminderEnabled = value);
                _saveSetting('water_reminder_enabled', value);
              },
            ),
            SwitchListTile(
              title: const Text('Notificação de meta atingida'),
              subtitle: const Text('Avisar quando a meta diária for concluída'),
              activeColor: Colors.lightBlueAccent,
              value: _goalCompleteNotificationEnabled,
              onChanged: (value) {
                setState(() => _goalCompleteNotificationEnabled = value);
                _saveSetting('goal_notification_enabled', value);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Ver projeto no GitHub'),
              onPressed: _openGithubRepo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            _buildNeumorphicButton(
              text: 'Sair',
              icon: Icons.logout,
              onPressed: () => _logout(context),
            ),
            const SizedBox(height: 16),
            _buildNeumorphicButton(
              text: 'Deletar Conta',
              icon: Icons.delete_forever,
              onPressed: () => _deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}
