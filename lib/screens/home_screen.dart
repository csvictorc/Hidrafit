import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/step_counter_service.dart';
import '../widgets/circular_progress_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SharedPreferences _prefs;
  StepCounterService? _stepCounterService;
  double _stepGoalMeters = 5000.0;
  double _currentDistance = 0.0;
  bool _needsPermission = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    try {
      debugPrint("Inicializando HomeScreen...");
      _prefs = await SharedPreferences.getInstance();
      _stepGoalMeters = _prefs.getDouble('step_goal_m') ?? 5000.0;
      _currentDistance = _prefs.getDouble('total_distance_today') ?? 0.0;
      debugPrint("Valores iniciais - Meta: $_stepGoalMeters m, Distância: $_currentDistance km");

      if (!_prefs.containsKey('name')) {
        debugPrint("Redirecionando para perfil...");
        await _redirectToProfile();
        return;
      }

      final permissionGranted = await Permission.activityRecognition.isGranted;
      debugPrint("Permissão concedida? $permissionGranted");

      if (mounted) {
        setState(() {
          _needsPermission = !permissionGranted;
          _isInitialized = true;
        });
      }

      if (permissionGranted) {
        _startStepCounter();
      }
    } catch (e) {
      debugPrint("Erro na inicialização: $e");
    }
  }

  Future<void> _requestAndHandlePermission() async {
    try {
      final result = await Permission.activityRecognition.request();
      debugPrint("Resultado da permissão: ${result.isGranted}");

      if (mounted) {
        setState(() {
          _needsPermission = !result.isGranted;
        });
      }

      if (result.isGranted) {
        _startStepCounter();
      } else {
        _showToast("Permissão de reconhecimento de atividade negada.");
      }
    } catch (e) {
      debugPrint("Erro ao solicitar permissão: $e");
    }
  }

  void _startStepCounter() {
    debugPrint("Iniciando contador de passos...");
    _stepCounterService?.stop(); // Para qualquer serviço existente

    _stepCounterService = StepCounterService(
      onDistanceUpdated: (distance) {
        debugPrint("Nova distância recebida: $distance km");
        if (mounted) {
          setState(() {
            _currentDistance = distance;
          });
          _saveDistance(distance);
        } else {
          debugPrint("Widget não montado - ignorando atualização");
        }
      },
    );

    _stepCounterService?.start();
  }

  Future<void> _saveDistance(double distance) async {
    try {
      await _prefs.setDouble('total_distance_today', distance);
      debugPrint("Distância salva: $distance km");
    } catch (e) {
      debugPrint("Erro ao salvar distância: $e");
    }
  }

  Future<void> _redirectToProfile() async {
    final result = await Navigator.pushNamed(context, '/profile');
    if (result == true && mounted) {
      await _reloadGoalAndDistance();
    }
  }

  Future<void> _reloadGoalAndDistance() async {
    try {
      _stepGoalMeters = _prefs.getDouble('step_goal_m') ?? 5000.0;
      _currentDistance = _prefs.getDouble('total_distance_today') ?? 0.0;
      debugPrint("Valores recarregados - Meta: $_stepGoalMeters m, Distância: $_currentDistance km");

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Erro ao recarregar dados: $e");
    }
  }

  double _calculateProgress() {
    final progress = (_currentDistance * 1000 / _stepGoalMeters) * 100; // Converte km para metros
    debugPrint("Progresso calculado: ${progress.clamp(0, 100)}%");
    return progress.clamp(0, 100);
  }

  String _formatDistance(double distanceKm) {
    return distanceKm.toStringAsFixed(2);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    _stepCounterService?.stop();
    debugPrint("HomeScreen dispose()");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = _calculateProgress();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Debug Info Box
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Distância Total: ${_formatDistance(_currentDistance)} km',
                          style: const TextStyle(fontSize: 14)),
                      Text('Meta: ${_formatDistance(_stepGoalMeters / 1000)} km',
                          style: const TextStyle(fontSize: 14)),
                      Text('Progresso: ${progress.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_needsPermission)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.security),
                  label: const Text("Permitir reconhecimento de atividade"),
                  onPressed: _requestAndHandlePermission,
                ),
              ),
            if (!_needsPermission)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressBar(
                      progress: progress,
                      strokeWidth: 20,
                      backgroundColor: Colors.grey.shade300,
                      progressColor: Colors.blueAccent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "${progress.toInt()}%",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (!_needsPermission)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    _buildInfoCard("Distância", "${_formatDistance(_currentDistance)} km"),
                    _buildInfoCard("Meta", "${_formatDistance(_stepGoalMeters / 1000)} km"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}