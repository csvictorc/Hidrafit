import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _waterReminderEnabled = true;
  bool _goalCompleteNotificationEnabled = true;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadLanguage();
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

  Future<void> _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('locale') ?? 'en';
    });
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
    _saveLanguage(languageCode);
    MyApp.setLocale(context, Locale(languageCode));
  }

  Future<void> _logout(BuildContext context) async {
    try {
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoggingOut)),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // ... implementação existente ...
  }

  Future<void> _openGithubRepo() async {
    final Uri url = Uri.parse('https://github.com/csvictorc/Hidrafit/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningLink)),
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
            Text(text, style: const TextStyle(fontSize: 18, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.black54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.grey),
                      onChanged: (String? newValue) {
                        if (newValue != null) _changeLanguage(newValue);
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(AppLocalizations.of(context)!.english),
                        ),
                        DropdownMenuItem(
                          value: 'pt',
                          child: Text(AppLocalizations.of(context)!.portuguese),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.hydrationReminder),
              subtitle: Text(AppLocalizations.of(context)!.hydrationReminderDescription),
              activeColor: Colors.lightBlueAccent,
              value: _waterReminderEnabled,
              onChanged: (value) {
                setState(() => _waterReminderEnabled = value);
                _saveSetting('water_reminder_enabled', value);
              },
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.goalCompletionNotification),
              subtitle: Text(AppLocalizations.of(context)!.goalCompletionNotificationDescription),
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
              label: Text(AppLocalizations.of(context)!.viewOnGithub),
              onPressed: _openGithubRepo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            _buildNeumorphicButton(
              text: AppLocalizations.of(context)!.logout,
              icon: Icons.logout,
              onPressed: () => _logout(context),
            ),
            const SizedBox(height: 16),
            _buildNeumorphicButton(
              text: AppLocalizations.of(context)!.deleteAccount,
              icon: Icons.delete_forever,
              onPressed: () => _deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}
