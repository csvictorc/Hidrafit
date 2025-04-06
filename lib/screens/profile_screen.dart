import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _stepGoalController = TextEditingController();
  late SharedPreferences _prefs;
  double _stepGoalMeters = 5000;
  User? _user;
  bool _isLoading = true;

  // Dados em cache
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

      // Carrega dados em cache imediatamente
      _cachedName = _prefs.getString('name') ?? 'Usuário';
      _cachedPhotoUrl = _prefs.getString('photo_url') ?? '';
      _stepGoalMeters = _prefs.getDouble('step_goal_m') ?? 5000;
      _stepGoalController.text = (_stepGoalMeters / 1000).toStringAsFixed(1);

      setState(() {
        _isLoading = false;
      });

      // Tenta atualizar os dados do Firebase em segundo plano
      await _updateProfileFromFirebase();

      setState(() {
        _connectionChecked = true;
      });
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      setState(() {
        _isLoading = false;
        _usingCachedData = true;
        _connectionChecked = true;
      });
    }
  }

  Future<void> _updateProfileFromFirebase() async {
    try {
      // Verifica a conectividade
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Não há conexão
        setState(() {
          _usingCachedData = true;
          _connectionChecked = true;
        });
        return;
      }

      _user = await FirebaseAuth.instance.currentUser;

      if (_user != null) {
        final newName = _user!.displayName ?? 'Usuário';
        final newPhotoUrl = _user!.photoURL ?? '';

        // Atualiza apenas se os dados forem diferentes
        if (newName != _cachedName || newPhotoUrl != _cachedPhotoUrl) {
          await _prefs.setString('name', newName);
          await _prefs.setString('photo_url', newPhotoUrl);

          if (mounted) {
            setState(() {
              _cachedName = newName;
              _cachedPhotoUrl = newPhotoUrl;
              _usingCachedData = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao atualizar do Firebase: $e');
      if (mounted) {
        setState(() {
          _usingCachedData = true;
          _connectionChecked = true;
        });
      }
    }
  }

  Future<void> _saveStepGoal() async {
    final parsed = double.tryParse(_stepGoalController.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      _showToast('Digite uma meta válida em quilômetros.');
      return;
    }

    try {
      await _prefs.setDouble('step_goal_m', parsed * 1000);
      _showToast('Meta atualizada com sucesso.');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      _showToast('Erro ao salvar a meta. Tente novamente.');
      debugPrint('Erro ao salvar meta: $e');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_cachedPhotoUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_cachedPhotoUrl),
                    )
                  else
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 40),
                    ),
                  if (_usingCachedData && _connectionChecked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _cachedName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_usingCachedData && _connectionChecked)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Modo offline - dados podem não estar atualizados',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              TextField(
                controller: _stepGoalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Meta diária (km)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveStepGoal,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
