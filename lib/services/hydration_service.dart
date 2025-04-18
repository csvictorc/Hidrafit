import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class HydrationService {
  final SharedPreferences prefs;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  int hydrationIntervalMinutes;
  DateTime? lastDrinkTime;
  Timer? _hydrationTimer;

  Function()? onReminder;
  Function()? onGlassRegistered;

  HydrationService({
    required this.prefs,
    required this.notificationsPlugin,
    this.hydrationIntervalMinutes = 30,
    this.onReminder,
    this.onGlassRegistered,
  });

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    // Carrega o intervalo de hidratação salvo ou usa o padrão (30 minutos)
    hydrationIntervalMinutes = prefs.getInt('hydration_interval') ?? 30;

    // Carrega o último horário de bebida usando millisecondsSinceEpoch
    final lastDrinkMillis = prefs.getInt('last_drink_millis');
    lastDrinkTime = lastDrinkMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastDrinkMillis)
        : DateTime.now();

    // Se não havia registro, salva o horário atual
    if (lastDrinkMillis == null) {
      await prefs.setInt(
          'last_drink_millis', lastDrinkTime!.millisecondsSinceEpoch);
    }

    _startTimer();
    _scheduleNextReminder();
  }

  void _startTimer() {
    _hydrationTimer?.cancel();
    _hydrationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (timeUntilNextGlass() <= Duration.zero) {
        _hydrationTimer?.cancel();
        onReminder?.call();
        showWaterReminderNotification();
      }
    });
  }

  Duration timeUntilNextGlass() {
    if (lastDrinkTime == null) return Duration.zero;

    final nextDrinkTime = lastDrinkTime!.add(Duration(minutes: hydrationIntervalMinutes));
    final timeLeft = nextDrinkTime.difference(DateTime.now());

    // Corrigido: Garante que o tempo nunca exceda o intervalo total
    return timeLeft > Duration(minutes: hydrationIntervalMinutes)
        ? Duration(minutes: hydrationIntervalMinutes)
        : timeLeft.isNegative
        ? Duration.zero
        : timeLeft;
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes min ${seconds.toString().padLeft(2, '0')}s";
  }

  Future<void> registerGlassOfWater() async {
    lastDrinkTime = DateTime.now();
    await prefs.setInt(
        'last_drink_millis', lastDrinkTime!.millisecondsSinceEpoch);

    _startTimer();
    _scheduleNextReminder();

    onGlassRegistered?.call();
  }

  Future<void> _scheduleNextReminder() async {
    final hydrationEnabled = prefs.getBool('hydration_notifications_enabled') ?? true;
    if (!hydrationEnabled) return;

    final scheduledTime = tz.TZDateTime.now(tz.local).add(
        Duration(minutes: hydrationIntervalMinutes));

    await notificationsPlugin.zonedSchedule(
      0,
      'Hora de se hidratar! 💧',
      'Beba um copo de água agora mesmo.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_channel',
          'Lembretes de Hidratação',
          channelDescription: 'Notificações para lembrar de beber água',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showWaterReminderNotification() async {
    final hydrationEnabled = prefs.getBool('hydration_notifications_enabled') ?? true;
    if (!hydrationEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'hydration_channel',
      'Lembretes de Hidratação',
      channelDescription: 'Notificações para lembrar de beber água',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );

    await notificationsPlugin.show(
      0,
      'Hora de se hidratar! 💧',
      'Beba um copo de água agora mesmo.',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelHydrationNotifications() async {
    await notificationsPlugin.cancel(0);
  }

  void dispose() {
    _hydrationTimer?.cancel();
  }
}