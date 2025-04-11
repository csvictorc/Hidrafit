import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StepCounterService {
  final Function(double) onDistanceUpdated; // Recebo a distância atualizada

  late StreamSubscription<StepCount> _stepCountStream;
  late SharedPreferences _prefs;

  static const _stepLengthInKm = 0.00075; // Defino o tamanho do passo em km (0.75 metros)
  int _initialStepCount = -1; // Contador de passos inicial
  double _totalDistanceToday = 0.0; // Distância total percorrida hoje
  String _lastSavedDate = ""; // Data da última contagem salva

  StepCounterService({required this.onDistanceUpdated});

  Future<void> start() async {
    final permissionGranted = await _ensurePermission(); // Verifico se tenho permissão
    if (!permissionGranted) {
      debugPrint('Permissão de reconhecimento de atividade negada.');
      return; // Saio se a permissão não for concedida
    }

    _prefs = await SharedPreferences.getInstance(); // Carrego as preferências
    _initialStepCount = _prefs.getInt('initial_step_count') ?? -1; // Obtenho o contador de passos inicial
    _totalDistanceToday = _prefs.getDouble('total_distance_today') ?? 0.0; // Obtenho a distância total
    _lastSavedDate = _prefs.getString('last_saved_date') ?? ""; // Obtenho a última data salva

    final String todayDate = _currentDate(); // Obtenho a data de hoje

    // Se a data mudou, reseto a contagem diária
    if (_lastSavedDate != todayDate) {
      _resetDailyCount(todayDate);
    }

    // Começo a escutar o fluxo de contagem de passos
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: true,
    );
  }

  void stop() {
    _stepCountStream.cancel(); // Paro o fluxo de contagem de passos
  }

  void _onStepCount(StepCount event) {
    final int totalSteps = event.steps; // Obtenho o total de passos
    final String today = _currentDate(); // Obtenho a data de hoje

    // Mostro o total de passos no debug
    debugPrint("Total Steps: $totalSteps");

    // Atualizo o contador de passos inicial e a data, se necessário
    if (_initialStepCount == -1 || _lastSavedDate != today) {
      _initialStepCount = totalSteps;
      _lastSavedDate = today;

      // Salvo o valor do contador de passos inicial
      _prefs.setInt('initial_step_count', _initialStepCount);
      _prefs.setString('last_saved_date', today);

      debugPrint("Initial Step Count: $_initialStepCount");
    }

    final int dailySteps = (totalSteps - _initialStepCount).clamp(0, double.infinity).toInt(); // Calculo os passos diários
    _totalDistanceToday = dailySteps * _stepLengthInKm; // Calculo a distância total

    // Verifico se a distância é muito baixa
    debugPrint("Daily Steps: $dailySteps");
    debugPrint("Calculated Distance: $_totalDistanceToday km");

    // Ajusto a distância mínima para evitar valores muito baixos
    if (_totalDistanceToday < 0.01) {
      debugPrint("Distância muito baixa, ajustando para 0.01 km");
      _totalDistanceToday = 0.01;
    }

    // Salvo a distância diária
    _prefs.setDouble('total_distance_today', _totalDistanceToday);

    // Atualizo a interface com a distância calculada
    onDistanceUpdated(_totalDistanceToday);
  }

  void _onStepCountError(error) {
    debugPrint('Erro ao ler passos: $error'); // Mostro o erro no debug
  }

  void _resetDailyCount(String todayDate) {
    final historyKey = "distance_$_lastSavedDate"; // Chave para armazenar o histórico

    _prefs.setDouble(historyKey, _totalDistanceToday); // Salvo a distância total no histórico
    _prefs.setInt("initial_step_count", -1); // Reseto o contador de passos inicial
    _prefs.setDouble("total_distance_today", 0.0); // Reseto a distância total
    _prefs.setString("last_saved_date", todayDate); // Atualizo a última data salva

    _initialStepCount = -1; // Reseto o contador de passos
    _totalDistanceToday = 0.0; // Reseto a distância total
  }

  String _currentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now()); // Formato a data atual
  }

  static Future<bool> isFirstUse() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey("name"); // Verifico se é a primeira vez que o app é usado
  }

  static Future<double> getSavedDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble("total_distance_today") ?? 0.0; // Recupero a distância salva
  }

  static Future<double> getGoalInMeters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble("step_goal_m") ?? 5000.0; // Recupero a meta em metros
  }

  Future<bool> _ensurePermission() async {
    final status = await Permission.activityRecognition.status; // Verifico o status da permissão
    if (status.isGranted) return true; // Retorno se a permissão já foi concedida

    final result = await Permission.activityRecognition.request(); // Solicito a permissão
    return result.isGranted; // Retorno se a permissão foi concedida
  }
}

class StepService {
  final SharedPreferences prefs;
  StepCounterService? _stepCounterService;

  double stepGoalMeters; // Meta de passos em metros
  double currentDistance; // Distância atual
  Function(double)? onDistanceUpdated; // Função para atualizar a distância

  StepService({
    required this.prefs,
    this.stepGoalMeters = 5000.0,
    this.currentDistance = 0.0,
    this.onDistanceUpdated,
  });

  Future<void> initialize() async {
    stepGoalMeters = prefs.getDouble('step_goal_m') ?? 5000.0; // Carrego a meta de passos
    currentDistance = prefs.getDouble('total_distance_today') ?? 0.0; // Carrego a distância atual
  }

  void startStepCounter() {
    _stepCounterService?.stop(); // Paro o contador anterior

    _stepCounterService = StepCounterService(
      onDistanceUpdated: (distance) {
        currentDistance = distance; // Atualizo a distância atual
        onDistanceUpdated?.call(distance); // Chamo a função de atualização
        _saveDistance(distance); // Salvo a nova distância
      },
    );

    _stepCounterService?.start(); // Inicio o contador de passos
  }

  Future<void> _saveDistance(double distance) async {
    await prefs.setDouble('total_distance_today', distance); // Salvo a distância total
  }

  double calculateProgress() {
    final progress = (currentDistance * 1000 / stepGoalMeters) * 100; // Calculo o progresso
    return progress.clamp(0, 100); // Retorno o progresso limitado entre 0 e 100
  }

  String formatDistance(double distanceKm) {
    return distanceKm.toStringAsFixed(2); // Formato a distância com duas casas decimais
  }

  Map<String, int> getActivityMetrics() {
    return {
      'steps': (currentDistance * 1312.3359).toInt(), // Calculo os passos
      'calories': (currentDistance * 60).toInt(), // Calculo as calorias
      'activeMinutes': (currentDistance * 12).toInt(), // Calculo os minutos ativos
    };
  }

  void dispose() {
    _stepCounterService?.stop(); // Paro o contador ao descartar o serviço
  }
}
