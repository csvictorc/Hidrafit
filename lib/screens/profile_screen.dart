import 'package:flutter/material.dart';
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
  String _cachedName = 'Usuário';
  String _cachedPhotoUrl = '';
  bool _usingCachedData = false;
  bool _connectionChecked = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      _cachedName = _prefs.getString('name') ?? 'Usuário';
      _cachedPhotoUrl = _prefs.getString('photo_url') ?? '';
      _stepGoalMeters = _prefs.getDouble('step_goal_m') ?? 5000;
      _hydrationInterval = _prefs.getInt('hydration_interval') ?? 30;

      _nameController.text = _cachedName;
      _stepGoalController.text = (_stepGoalMeters / 1000).toStringAsFixed(1);
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

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final parsedStepGoal = double.tryParse(_stepGoalController.text.replaceAll(',', '.'));
    final parsedHydrationInterval = int.tryParse(_hydrationIntervalController.text);

    if (newName.isEmpty) {
      _showToast('Digite um nome válido.');
      return;
    }

    if (parsedStepGoal == null || parsedStepGoal <= 0) {
      _showToast('Digite uma meta válida em quilômetros.');
      return;
    }

    if (parsedHydrationInterval == null || parsedHydrationInterval <= 0) {
      _showToast('Digite um intervalo válido para hidratação (minutos).');
      return;
    }

    try {
      await _prefs.setString('name', newName);
      await _prefs.setDouble('step_goal_m', parsedStepGoal * 1000);
      await _prefs.setInt('hydration_interval', parsedHydrationInterval);
      await ProfileHelper.updateDisplayName(newName);

      _showToast('Perfil salvo com sucesso.');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      _showToast('Erro ao salvar perfil. Tente novamente.');
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
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
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stepGoalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Meta diária (km)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hydrationIntervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Intervalo entre copos de água (min)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
