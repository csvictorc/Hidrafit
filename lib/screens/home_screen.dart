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
import '../widgets/circular_progress_bar.dart';
import '../main.dart';
import '../widgets/pressable_button.dart';

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
    _initializeServices(notificationsPlugin: flutterLocalNotificationsPlugin);
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        _checkGoalReached();
      }
    });
  }

  bool get _isImperial => Localizations.localeOf(context).languageCode == 'en';

  String _formatDistance(double distanceInKm) {
    if (_isImperial) {
      final miles = distanceInKm * 0.621371;
      return "${miles.toStringAsFixed(2)} mi";
    } else {
      return "${distanceInKm.toStringAsFixed(2)} km";
    }
  }

  Future<void> _checkAndRequestNotificationPermission() async {
    if (await Permission.notification.isDenied || await Permission.notification.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initializeServices({required FlutterLocalNotificationsPlugin notificationsPlugin}) async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('name');
    final newGoalKm = (prefs.getDouble('step_goal_m') ?? 5000) / 1000;

    if (newGoalKm != _dailyGoalKm) {
      _hasCongratulated = false;
    }

    _dailyGoalKm = newGoalKm;

    if (userName == null && !_hasRedirectedToProfile && mounted) {
      _hasRedirectedToProfile = true;
      await Future.delayed(Duration.zero);
      Navigator.pushNamed(context, '/profile').then((_) {
        _hasRedirectedToProfile = false;
        _initializeServices(notificationsPlugin: notificationsPlugin);
      });
      return;
    }

    _hydrationService = HydrationService(
      prefs: prefs,
      notificationsPlugin: notificationsPlugin,
      onReminder: _showHydrationModal,
      onGlassRegistered: () {
        if (mounted) {
          UiHelpers.showToast(context, "💧");
        }
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
    }

    if (hasPermission) {
      _stepService.startStepCounter();
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
      final goalNotificationEnabled = prefs.getBool('goal_notifications_enabled') ?? true;

      if (goalNotificationEnabled) {
        final l10n = AppLocalizations.of(context)!;
        final formattedDistance = _isImperial
            ? (_dailyGoalKm * 0.621371).toStringAsFixed(1)
            : _dailyGoalKm.toStringAsFixed(1);

        await flutterLocalNotificationsPlugin.show(
          1,
          l10n.goalReachedTitle,
          l10n.goalReachedBody(formattedDistance),
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
    if (mounted) {
      setState(() => _needsPermission = !granted);
    }

    if (granted) {
      _stepService.startStepCounter();
    } else {
      final l10n = AppLocalizations.of(context)!;
      UiHelpers.showToast(context, l10n.activityPermissionDenied);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = _stepService.calculateProgress();
    final timeLeft = _hydrationService.timeUntilNextGlass();
    final safeTimeLeft = timeLeft.isNegative ? Duration.zero : timeLeft;
    final hydrationProgress = (safeTimeLeft.inSeconds / (_hydrationService.hydrationIntervalMinutes * 60)).clamp(0.0, 1.0);
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
              userName != null ? l10n.helloUser(userName!) : l10n.helloUserAnonymous,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildHydrationProgress(l10n, hydrationProgress, _hydrationService.formatDuration(safeTimeLeft)),
            const SizedBox(height: 12),
            PressableButton(
              label: l10n.justDrank,
              onPressed: _hydrationService.registerGlassOfWater,
            ),
            const SizedBox(height: 24),
            _buildStepGoalProgress(l10n, progress),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildInfoCard(l10n.dailyDistance, _formatDistance(_stepService.currentDistance)),
                _buildInfoCard(l10n.dailyGoal, _formatDistance(_dailyGoalKm)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoCard(l10n.caloriesBurned, "${metrics['calories']} kcal"),
                _buildInfoCard(l10n.stepsToday, "${metrics['steps']}"),
              ],
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
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.stepGoalProgress,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: MediaQuery.of(context).size.width * (progress / 100),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 20,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                    ),
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

  Widget _buildHydrationProgress(AppLocalizations l10n, double progress, String timeLabel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.hydrationProgress,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressBar(
                      progress: (progress * 100).toDouble(),
                      strokeWidth: 20,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      progressColor: Colors.lightBlueAccent,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeLabel,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          l10n.nextGlassIn,
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.security),
          label: Text(l10n.activityPermissionButton),
          onPressed: _requestPermission,
        ),
      ),
    );
  }
}
