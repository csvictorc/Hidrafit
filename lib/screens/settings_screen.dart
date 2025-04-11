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
  bool _waterReminderEnabled = true; // Controle para lembretes de hidratação
  bool _goalCompleteNotificationEnabled = true; // Controle para notificações de metas

  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Instância do Google Sign-In

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Carrego as configurações ao iniciar a tela
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterReminderEnabled = prefs.getBool('water_reminder_enabled') ?? true; // Pego o estado do lembrete de água
      _goalCompleteNotificationEnabled = prefs.getBool('goal_notification_enabled') ?? true; // Pego o estado da notificação de metas
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value); // Salvo a configuração no SharedPreferences
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Desconecto do Google se o usuário estiver logado
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await FirebaseAuth.instance.signOut(); // Desconecto do Firebase

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Levo o usuário de volta para a tela de login
      }
    } catch (e) {
      debugPrint('Erro ao sair: $e'); // Exibo erro no console
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao sair da conta.')), // Aviso ao usuário
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser; // Pego o usuário atual
    if (user == null) return; // Se não houver usuário, não faço nada

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja deletar sua conta? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Botão de cancelar
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Botão para deletar
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return; // Se não confirmar, cancelo a exclusão

    try {
      await user.delete(); // Tenta deletar o usuário

      // Se estiver logado com Google, desconecto também
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Volto para a tela de login
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
      debugPrint('Erro ao deletar conta: $e'); // Exibo erro no console
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado ao deletar conta.')), // Aviso ao usuário
      );
    }
  }

  Future<void> _openGithubRepo() async {
    final Uri url = Uri.parse('https://github.com/csvictorc/Hidrafit/'); // URL do repositório
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')), // Aviso se não conseguir abrir
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
      onTap: onPressed, // Ao tocar no botão, chama a função passada
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
            Icon(icon, color: Colors.black45), // Ícone do botão
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
      appBar: AppBar(title: const Text('Configurações')), // Título da tela
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Lembretes de hidratação'), // Título do switch
              subtitle: const Text('Receber notificações para beber água'), // Subtítulo
              activeColor: Colors.lightBlueAccent,
              value: _waterReminderEnabled, // Estado do switch
              onChanged: (value) {
                setState(() => _waterReminderEnabled = value); // Atualizo o estado
                _saveSetting('water_reminder_enabled', value); // Salvo a configuração
              },
            ),
            SwitchListTile(
              title: const Text('Notificação de meta atingida'), // Título do switch
              subtitle: const Text('Avisar quando a meta diária for concluída'), // Subtítulo
              activeColor: Colors.lightBlueAccent,
              value: _goalCompleteNotificationEnabled, // Estado do switch
              onChanged: (value) {
                setState(() => _goalCompleteNotificationEnabled = value); // Atualizo o estado
                _saveSetting('goal_notification_enabled', value); // Salvo a configuração
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser), // Ícone do botão
              label: const Text('Ver projeto no GitHub'), // Texto do botão
              onPressed: _openGithubRepo, // Ação ao pressionar
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87, // Cor de fundo
                foregroundColor: Colors.white, // Cor do texto
              ),
            ),
            const SizedBox(height: 32),
            _buildNeumorphicButton(
              text: 'Sair', // Texto do botão
              icon: Icons.logout, // Ícone do botão
              onPressed: () => _logout(context), // Ação ao pressionar
            ),
            const SizedBox(height: 16),
            _buildNeumorphicButton(
              text: 'Deletar Conta', // Texto do botão
              icon: Icons.delete_forever, // Ícone do botão
              onPressed: () => _deleteAccount(context), // Ação ao pressionar
            ),
          ],
        ),
      ),
    );
  }
}
