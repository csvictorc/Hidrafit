import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StepCounterService {
  final Function(double) onDistanceUpdated; // Aceita a distância como parâmetro

  late StreamSubscription<StepCount> _stepCountStream;
  late SharedPreferences _prefs;

  static const _stepLengthInKm = 0.00075; // Tamanho do passo em km (ajustado para 0.75 metros por passo)
  int _initialStepCount = -1;
  double _totalDistanceToday = 0.0;
  String _lastSavedDate = "";

  StepCounterService({required this.onDistanceUpdated});

  Future<void> start() async {
    final permissionGranted = await _ensurePermission();
    if (!permissionGranted) {
      debugPrint('Permissão de reconhecimento de atividade negada.');
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    _initialStepCount = _prefs.getInt('initial_step_count') ?? -1;
    _totalDistanceToday = _prefs.getDouble('total_distance_today') ?? 0.0;
    _lastSavedDate = _prefs.getString('last_saved_date') ?? "";

    final String todayDate = _currentDate();

    // Resetar a contagem diária se a data mudou
    if (_lastSavedDate != todayDate) {
      _resetDailyCount(todayDate);
    }

    // Escutar o fluxo de contagem de passos
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: true,
    );
  }

  void stop() {
    _stepCountStream.cancel();
  }

  void _onStepCount(StepCount event) {
    final int totalSteps = event.steps;
    final String today = _currentDate();

    // Verificando o valor total de passos
    debugPrint("Total Steps: $totalSteps");

    // Atualizar o contador de passos inicial e a data, se necessário
    if (_initialStepCount == -1 || _lastSavedDate != today) {
      _initialStepCount = totalSteps;
      _lastSavedDate = today;

      // Salvando o valor do contador de passos inicial
      _prefs.setInt('initial_step_count', _initialStepCount);
      _prefs.setString('last_saved_date', today);

      debugPrint("Initial Step Count: $_initialStepCount");
    }

    final int dailySteps = (totalSteps - _initialStepCount).clamp(0, double.infinity).toInt();
    _totalDistanceToday = dailySteps * _stepLengthInKm;

    // Debugging para verificar valores
    debugPrint("Daily Steps: $dailySteps");
    debugPrint("Calculated Distance: $_totalDistanceToday km");

    // Adicionar um mínimo de distância para evitar valores muito baixos
    if (_totalDistanceToday < 0.01) {
      debugPrint("Distância muito baixa, ajustando para 0.01 km");
      _totalDistanceToday = 0.01;
    }

    // Salvando a distância diária
    _prefs.setDouble('total_distance_today', _totalDistanceToday);

    // Atualizando a interface com a distância calculada
    onDistanceUpdated(_totalDistanceToday);
  }

  void _onStepCountError(error) {
    debugPrint('Erro ao ler passos: $error');
  }

  void _resetDailyCount(String todayDate) {
    final historyKey = "distance_$_lastSavedDate";

    _prefs.setDouble(historyKey, _totalDistanceToday);
    _prefs.setInt("initial_step_count", -1);
    _prefs.setDouble("total_distance_today", 0.0);
    _prefs.setString("last_saved_date", todayDate);

    _initialStepCount = -1;
    _totalDistanceToday = 0.0;
  }

  String _currentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static Future<bool> isFirstUse() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey("name");
  }

  static Future<double> getSavedDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble("total_distance_today") ?? 0.0;
  }

  static Future<double> getGoalInMeters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble("step_goal_m") ?? 5000.0;
  }

  Future<bool> _ensurePermission() async {
    final status = await Permission.activityRecognition.status;
    if (status.isGranted) return true;

    final result = await Permission.activityRecognition.request();
    return result.isGranted;
  }
}
