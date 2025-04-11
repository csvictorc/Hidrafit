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
    tz_data.initializeTimeZones(); // Inicializo os fusos horários

    hydrationIntervalMinutes = prefs.getInt('hydration_interval') ?? 30; // Defino o intervalo de hidratação

    final lastDrinkStr = prefs.getString('last_drink_time');
    lastDrinkTime = lastDrinkStr != null
        ? DateTime.tryParse(lastDrinkStr)
        : DateTime.now(); // Recupero o último horário de bebida ou uso agora

    if (lastDrinkTime == null) {
      lastDrinkTime = DateTime.now();
      await prefs.setString('last_drink_time', lastDrinkTime!.toIso8601String()); // Salvo o horário atual
    }

    _startTimer(); // Começo o timer para lembrar de beber água
    _scheduleNextReminder(); // Agendo o próximo lembrete
  }

  void _startTimer() {
    _hydrationTimer?.cancel(); // Cancelo qualquer timer anterior
    _hydrationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (timeUntilNextGlass() <= Duration.zero) {
        _hydrationTimer?.cancel(); // Cancelo o timer se o tempo até o próximo copo for zero
        onReminder?.call(); // Chamo a função de lembrete
        showWaterReminderNotification(); // Mostro a notificação para beber água
      }
    });
  }

  Duration timeUntilNextGlass() {
    final nextDrinkTime = lastDrinkTime!.add(Duration(minutes: hydrationIntervalMinutes)); // Calculo o próximo horário de bebida
    return nextDrinkTime.difference(DateTime.now()); // Retorno a diferença de tempo
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes min ${seconds.toString().padLeft(2, '0')}s"; // Formato a duração para exibir
  }

  Future<void> registerGlassOfWater() async {
    lastDrinkTime = DateTime.now(); // Registro o horário atual
    await prefs.setString('last_drink_time', lastDrinkTime!.toIso8601String()); // Atualizo o horário no armazenamento

    _startTimer(); // Reinicio o timer
    _scheduleNextReminder(); // Agendo o próximo lembrete

    onGlassRegistered?.call(); // Chamo a função de registro do copo
  }

  Future<void> _scheduleNextReminder() async {
    final hydrationEnabled = prefs.getBool('hydration_notifications_enabled') ?? true; // Verifico se as notificações estão habilitadas
    if (!hydrationEnabled) return; // Se não estiver habilitado, não faço nada

    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: hydrationIntervalMinutes)); // Agendo o horário da próxima notificação

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
    final hydrationEnabled = prefs.getBool('hydration_notifications_enabled') ?? true; // Verifico novamente se as notificações estão habilitadas
    if (!hydrationEnabled) return; // Se não estiver habilitado, não mostro a notificação

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
      'Beba um copo de água agora mesmo.', // Mensagem da notificação
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelHydrationNotifications() async {
    await notificationsPlugin.cancel(0); // Cancelo a notificação com ID 0
  }

  void dispose() {
    _hydrationTimer?.cancel(); // Cancelo o timer ao descartar o serviço
  }
}
