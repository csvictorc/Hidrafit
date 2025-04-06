import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  bool _isHydrationModalVisible = false;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  int hydrationIntervalMinutes = 30;
  DateTime? lastDrinkTime;
  Timer? _hydrationTimer;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showWaterReminderNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'hydration_channel',
      'Hidratação',
      channelDescription: 'Lembretes para beber água',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Hora de se hidratar!',
      'Beba um copo de água agora mesmo 💧',
      platformChannelSpecifics,
    );
    _showHydrationModal();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _stepGoalMeters = _prefs.getDouble('step_goal_m') ?? 5000.0;
      _currentDistance = _prefs.getDouble('total_distance_today') ?? 0.0;
      hydrationIntervalMinutes = _prefs.getInt('hydration_interval') ?? 30;

      String? lastDrinkStr = _prefs.getString('last_drink_time');
      if (lastDrinkStr != null) {
        lastDrinkTime = DateTime.tryParse(lastDrinkStr);
      } else {
        lastDrinkTime = DateTime.now();
        await _prefs.setString('last_drink_time', lastDrinkTime!.toIso8601String());
      }

      _startHydrationTimer();

      if (!_prefs.containsKey('name')) {
        await _redirectToProfile();
        return;
      }

      final permissionGranted = await Permission.activityRecognition.isGranted;

      setState(() {
        _needsPermission = !permissionGranted;
        _isInitialized = true;
      });

      if (permissionGranted) {
        _startStepCounter();
      }
    } catch (e) {
      debugPrint("Erro na inicialização: $e");
    }
  }

  void _startHydrationTimer() {
    _hydrationTimer?.cancel();
    _hydrationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final timeLeft = _timeUntilNextGlass();
      if (timeLeft <= Duration.zero) {
        _hydrationTimer?.cancel();
        _showWaterReminderNotification();
      }
      setState(() {}); // atualiza tempo restante
    });
  }

  Duration _timeUntilNextGlass() {
    final now = DateTime.now();
    final nextDrinkTime = lastDrinkTime!.add(Duration(minutes: hydrationIntervalMinutes));
    final difference = nextDrinkTime.difference(now);
    return difference.isNegative ? Duration.zero : difference;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes min ${seconds.toString().padLeft(2, '0')}s";
  }

  void _registerGlassOfWater() async {
    lastDrinkTime = DateTime.now();
    await _prefs.setString('last_drink_time', lastDrinkTime!.toIso8601String());
    _startHydrationTimer();
    setState(() {});
    _showToast("Copinho registrado 💧");
  }

  Future<void> _requestAndHandlePermission() async {
    try {
      final result = await Permission.activityRecognition.request();

      setState(() {
        _needsPermission = !result.isGranted;
      });

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
    _stepCounterService?.stop();

    _stepCounterService = StepCounterService(
      onDistanceUpdated: (distance) {
        if (mounted) {
          setState(() {
            _currentDistance = distance;
          });
          _saveDistance(distance);
        }
      },
    );

    _stepCounterService?.start();
  }

  Future<void> _saveDistance(double distance) async {
    try {
      await _prefs.setDouble('total_distance_today', distance);
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
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Erro ao recarregar dados: $e");
    }
  }

  double _calculateProgress() {
    final progress = (_currentDistance * 1000 / _stepGoalMeters) * 100;
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

  void _showHydrationModal() {
    if (_isHydrationModalVisible || !mounted) return;

    setState(() {
      _isHydrationModalVisible = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Hora de beber água!"),
        content: const Text("Já se passaram 30 minutos desde o último copo 💧"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _registerGlassOfWater();
              setState(() {
                _isHydrationModalVisible = false;
              });
            },
            child: const Text("Bebi!"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stepCounterService?.stop();
    _hydrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = _calculateProgress();
    final timeLeft = _timeUntilNextGlass();
    final hydrationProgress = (timeLeft.inSeconds / (hydrationIntervalMinutes * 60)).clamp(0.0, 1.0);
    final steps = (_currentDistance * 1312.3359).toInt();
    final calories = (_currentDistance * 60).toInt();
    final activeMinutes = (_currentDistance * 12).toInt();
    final userName = _prefs.getString('name') ?? 'Usuário';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      body: SafeArea(
        child: _needsPermission
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.security),
              label: const Text("Permitir reconhecimento de atividade"),
              onPressed: _requestAndHandlePermission,
            ),
          ),
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              "Olá, $userName 👋",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStepGoalProgress(progress),
            const SizedBox(height: 24),
            _buildHydrationProgress(hydrationProgress, _formatDuration(timeLeft)),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: _registerGlassOfWater,
                child: const Text("Acabei de beber 💧"),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildInfoCard("Distância diária", "${_formatDistance(_currentDistance)} km"),
                _buildInfoCard("Passos hoje", "$steps"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoCard("Calorias perdidas", "$calories kcal"),
                _buildInfoCard("Tempo ativo", "$activeMinutes min"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepGoalProgress(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Progresso da meta de caminhada",
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 12,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${progress.toInt()}%",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHydrationProgress(double progress, String timeLabel) {
    return Center(
      child: SizedBox(
        height: 200,
        width: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressBar(
              progress: (progress * 100).toDouble(),
              strokeWidth: 20,
              backgroundColor: Colors.grey.shade300,
              progressColor: Colors.lightBlueAccent,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text("até o próximo copo", style: TextStyle(fontSize: 16)),
              ],
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
          color: Colors.lightBlueAccent.withOpacity(0.1),
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
