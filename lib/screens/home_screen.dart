import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../helpers/ui_helpers.dart' as UiHelpers;
import '../services/hydration_service.dart';
import '../services/step_service.dart';
import '../helpers/permission_helper.dart';
import '../main.dart';
import '../widgets/pressable_button.dart';
import '../widgets/water_progress_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HydrationService _hydrationService;
  late final StepService _stepService;

  bool _needsPermission = false;
  bool _isInitialized = false;
  bool _isHydrationModalVisible = false;
  bool _hasRedirectedToProfile = false;
  String? userName;
  double _dailyGoalKm = 5.0;
  Timer? _uiUpdateTimer;
  bool _hasCongratulated = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestNotificationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices(
        context: context,
        notificationsPlugin: flutterLocalNotificationsPlugin,
      );
    });
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        _checkGoalReached();
      }
    });
  }

  bool get _isImperial =>
      Localizations.localeOf(context).languageCode == 'en';

  String _formatDistance(double km) {
    if (_isImperial) {
      final miles = km * 0.621371;
      return "${miles.toStringAsFixed(2)} mi";
    } else {
      return "${km.toStringAsFixed(2)} km";
    }
  }

  Future<void> _checkAndRequestNotificationPermission() async {
    if (await Permission.notification.isDenied ||
        await Permission.notification.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initializeServices({
    required BuildContext context,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('name');
    _dailyGoalKm = (prefs.getDouble('step_goal_m') ?? 5000) / 1000;
    _hasCongratulated = false;

    if (userName == null && !_hasRedirectedToProfile && mounted) {
      _hasRedirectedToProfile = true;
      await Future.delayed(Duration.zero);
      Navigator.pushNamed(context, '/profile').then((_) {
        _hasRedirectedToProfile = false;
        _initializeServices(
          context: context,
          notificationsPlugin: notificationsPlugin,
        );
      });
      return;
    }

    _hydrationService = HydrationService(
      prefs: prefs,
      notificationsPlugin: notificationsPlugin,
      onReminder: _showHydrationModal,
      onGlassRegistered: () {
        if (mounted) UiHelpers.showToast(context, AppLocalizations.of(context)!.cupRegistered + "💧");
      },
    );
    await _hydrationService.initialize();

    _stepService = StepService(
      prefs: prefs,
      onDistanceUpdated: (_) => setState(() {}),
    );
    await _stepService.initialize();

    final hasPermission = await PermissionHelper.checkActivityPermission();
    if (mounted) {
      setState(() {
        _needsPermission = !hasPermission;
        _isInitialized = true;
      });
      if (hasPermission) _stepService.startStepCounter();
    }
  }

  void _showHydrationModal() {
    if (_isHydrationModalVisible) return;
    setState(() => _isHydrationModalVisible = true);
    UiHelpers.showHydrationModal(context, () {
      _hydrationService.registerGlassOfWater();
      setState(() => _isHydrationModalVisible = false);
    });
  }

  Future<void> _checkGoalReached() async {
    final progress = _stepService.calculateProgress();
    if (progress >= 100 && !_hasCongratulated) {
      _hasCongratulated = true;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('goal_notifications_enabled') ?? true) {
        final l10n = AppLocalizations.of(context)!;
        final dist = _isImperial
            ? (_dailyGoalKm * 0.621371).toStringAsFixed(1)
            : _dailyGoalKm.toStringAsFixed(1);
        await flutterLocalNotificationsPlugin.show(
          1,
          l10n.goalReachedTitle,
          l10n.goalReachedBody(dist),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'goal_channel',
              'Meta Atingida',
              channelDescription: 'Notificações para quando a meta de passos é atingida',
              importance: Importance.high,
              priority: Priority.high,
              visibility: NotificationVisibility.public,
            ),
          ),
        );
      }
    } else if (progress < 100) {
      _hasCongratulated = false;
    }
  }

  Future<void> _requestPermission() async {
    final granted = await PermissionHelper.requestActivityPermission();
    if (mounted) setState(() => _needsPermission = !granted);
    if (granted) {
      _stepService.startStepCounter();
    } else {
      UiHelpers.showToast(
          context, AppLocalizations.of(context)!.activityPermissionDenied);
    }
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _hydrationService.dispose();
    _stepService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stepProgress = _stepService.calculateProgress();
    final timeLeft = _hydrationService.timeUntilNextGlass();
    final safeLeft = timeLeft.isNegative ? Duration.zero : timeLeft;
    final totalSec = _hydrationService.hydrationIntervalMinutes * 60;
    final hydrationProgress = (safeLeft.inSeconds / totalSec).clamp(0.0, 1.0);
    final metrics = _stepService.getActivityMetrics();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      body: SafeArea(
        child: _needsPermission
            ? _buildPermissionRequest(l10n)
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              userName != null
                  ? l10n.helloUser(userName!)
                  : l10n.helloUserAnonymous,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildHydrationProgress(
              l10n,
              hydrationProgress,
              _hydrationService.formatDuration(safeLeft),
            ),
            const SizedBox(height: 12),
            PressableButton(
              label: l10n.justDrank,
              onPressed: () {
                _hydrationService.registerGlassOfWater();
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            _buildStepGoalProgress(l10n, stepProgress),
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                children: [
                  _buildInfoCard(
                    l10n.dailyDistance,
                    _formatDistance(_stepService.currentDistance),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoCard(
                    l10n.dailyGoal,
                    _formatDistance(_dailyGoalKm),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                children: [
                  _buildInfoCard(
                    l10n.caloriesBurned,
                    "${metrics['calories']} kcal",
                  ),
                  const SizedBox(width: 8),
                  _buildInfoCard(
                    l10n.stepsToday,
                    "${metrics['steps']}",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepGoalProgress(AppLocalizations l10n, double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.stepGoalProgress,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 20,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.lightBlueAccent),
                  ),
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

  Widget _buildHydrationProgress(
      AppLocalizations l10n, double progress, String timeLabel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.hydrationProgress,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              WaterProgressWidget(
                progress: progress,
                waterColor: Colors.blue.withOpacity(0.8),
              ),
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // Reduzi o padding horizontal
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12, // Diminuí o tamanho da fonte do título
            ),
            textAlign: TextAlign.center,
            maxLines: 1, // Garante que o título fique em uma linha
            overflow: TextOverflow.ellipsis, // Adiciona "..." se o texto for muito longo
          ),
          const SizedBox(height: 8), // Reduzi o espaçamento
          Text(
            value,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 18, // Aumentei o tamanho da fonte do valor
              fontWeight: FontWeight.bold, // Deixei o valor em negrito
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildPermissionRequest(AppLocalizations l10n) => Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.permissionNeeded,
            style:
            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _requestPermission,
            child: Text(l10n.requestPermission),
          ),
        ],
      ),
    ),
  );
}
