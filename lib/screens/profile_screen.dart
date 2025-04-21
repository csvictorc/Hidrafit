import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../helpers/profile_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stepGoalController = TextEditingController();
  final TextEditingController _hydrationIntervalController = TextEditingController();

  late SharedPreferences _prefs;
  double _stepGoalMeters = 5000;
  int _hydrationInterval = 30;

  bool _isLoading = true;
  String _cachedName = '';
  String _cachedPhotoUrl = '';
  bool _usingCachedData = false;
  bool _connectionChecked = false;
  String _selectedLanguage = 'en'; // Idioma salvo nas SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadProfileData();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('locale') ?? 'en'; // Carregar o idioma salvo
    });
  }

  Future<void> _loadProfileData() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      _cachedName = _prefs.getString('name') ?? '';
      _cachedPhotoUrl = _prefs.getString('photo_url') ?? '';
      _stepGoalMeters = _prefs.getDouble('step_goal_m') ?? 5000;
      _hydrationInterval = _prefs.getInt('hydration_interval') ?? 30;

      _nameController.text = _cachedName;
      _stepGoalController.text = _getLocalizedStepGoalValue().toStringAsFixed(1);
      _hydrationIntervalController.text = _hydrationInterval.toString();

      setState(() {
        _isLoading = false;
      });

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _usingCachedData = true;
          _connectionChecked = true;
        });
        return;
      }

      await ProfileHelper.updateFirebaseProfileIfNeeded(
        context: context,
        prefs: _prefs,
        onProfileUpdated: (name, photoUrl) {
          if (mounted) {
            setState(() {
              _cachedName = name;
              _cachedPhotoUrl = photoUrl;
              _nameController.text = name;
              _usingCachedData = false;
              _connectionChecked = true;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      setState(() {
        _isLoading = false;
        _usingCachedData = true;
        _connectionChecked = true;
      });
    }
  }

  double _getLocalizedStepGoalValue() {
    // Use o idioma salvo no app para determinar se é métrico ou imperial
    return _selectedLanguage == 'en' ? _stepGoalMeters / 1609.34 : _stepGoalMeters / 1000;
  }

  double _convertToMeters(double value) {
    // Convertendo o valor para metros ou quilômetros dependendo do idioma
    return _selectedLanguage == 'en' ? value * 1609.34 : value * 1000;
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context)!;
    final newName = _nameController.text.trim();
    final parsedStepGoal = double.tryParse(_stepGoalController.text.replaceAll(',', '.'));
    final parsedHydrationInterval = int.tryParse(_hydrationIntervalController.text);

    if (newName.isEmpty) {
      _showToast(loc.invalidName);
      return;
    }

    if (parsedStepGoal == null || parsedStepGoal <= 0) {
      _showToast(loc.invalidStepGoal);
      return;
    }

    if (parsedHydrationInterval == null || parsedHydrationInterval <= 0) {
      _showToast(loc.invalidHydrationInterval);
      return;
    }

    try {
      // Converta o valor para metros antes de salvar
      final stepGoalInMeters = _convertToMeters(parsedStepGoal);

      await _prefs.setString('name', newName);
      await _prefs.setDouble('step_goal_m', stepGoalInMeters);
      await _prefs.setInt('hydration_interval', parsedHydrationInterval);
      await ProfileHelper.updateDisplayName(newName);

      _showToast(loc.profileSaved);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      _showToast(loc.profileSaveError);
      debugPrint('Erro ao salvar dados: $e');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Widget _buildProfilePhoto() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: _cachedPhotoUrl.isNotEmpty ? NetworkImage(_cachedPhotoUrl) : null,
          child: _cachedPhotoUrl.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        if (_usingCachedData && _connectionChecked)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off, size: 16, color: Colors.white),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadProfileData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Center(child: _buildProfilePhoto()),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.nameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stepGoalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.dailyGoalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hydrationIntervalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.hydrationIntervalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 32),
              _buildNeumorphicButton(
                text: loc.saveButton,
                icon: Icons.save,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
