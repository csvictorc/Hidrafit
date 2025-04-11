import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

// A minha idéia inicial era fazer uma barra de progresso redonda pra registrar o progresso da hidratação, mas para uma melhor visualização do usuário isso virou uma espécie de "caixa dágua"

class CircularProgressBar extends StatefulWidget {
  final double progress; // A porcentagem de progresso a ser exibida
  final double max; // O valor máximo para o progresso
  final Color progressColor; // A cor da parte preenchida
  final Color backgroundColor; // A cor de fundo
  final double strokeWidth; // A largura da barra

  const CircularProgressBar({
    super.key,
    required this.progress,
    this.max = 100,
    this.progressColor = Colors.blueAccent,
    this.backgroundColor = Colors.grey,
    this.strokeWidth = 20.0,
  });

  @override
  State<CircularProgressBar> createState() => _CircularProgressBarState();
}

class _CircularProgressBarState extends State<CircularProgressBar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker; // Um ticker para animações

  double _xTilt = 0; // Inclinação no eixo X
  double _yTilt = 0; // Inclinação no eixo Y
  double _waveIntensity = 0.2; // Intensidade da onda
  double _targetWaveIntensity = 0.2; // Intensidade alvo da onda

  final double _maxIntensity = 1.0; // Intensidade máxima da onda
  final double _minIntensity = 0.2; // Intensidade mínima da onda
  DateTime _lastMotionTime = DateTime.now(); // Última vez que detectei movimento
  Duration _startTime = Duration.zero; // Tempo de início da animação

  double get _progressFraction =>
      widget.max == 0 ? 0 : widget.progress.clamp(0, widget.max) / widget.max;

  @override
  void initState() {
    super.initState();

    _startTime = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
    _ticker = Ticker(_onTick)..start(); // Inicializo o ticker

    // Escuto os eventos do acelerômetro
    accelerometerEvents.listen((event) {
      double dx = event.x - _xTilt; // Calculo a mudança na inclinação X
      double dy = event.y - _yTilt; // Calculo a mudança na inclinação Y
      double delta = sqrt(dx * dx + dy * dy); // Distância total da mudança

      // Se a mudança for significativa, atualizo a inclinação
      if (delta > 1.2) {
        _xTilt = event.x.clamp(-10, 10); // Limito a inclinação X
        _yTilt = event.y.clamp(-10, 10); // Limito a inclinação Y
        _lastMotionTime = DateTime.now(); // Atualizo o tempo do último movimento
        _targetWaveIntensity = _maxIntensity; // Aumento a intensidade da onda
      }
    });

    _startSmoothIntensityAdjuster(); // Começo a ajustar a intensidade suavemente
  }

  void _onTick(Duration elapsed) {
    // Verifico quanto tempo passou desde o último movimento
    final timeSinceLastMotion = DateTime.now().difference(_lastMotionTime).inMilliseconds;
    if (timeSinceLastMotion > 1000) {
      _targetWaveIntensity = _minIntensity; // Reduzo a intensidade se não houver movimento
    }

    // Atualizo a intensidade da onda suavemente
    setState(() {
      _waveIntensity += (_targetWaveIntensity - _waveIntensity) * 0.05;
    });
  }

  void _startSmoothIntensityAdjuster() {
    // Crio um timer que ajusta a intensidade da onda a cada 60 milissegundos
    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) timer.cancel(); // Cancelo o timer se o widget não estiver mais montado
      setState(() {}); // Atualizo o estado para forçar uma nova renderização
    });
  }

  @override
  void dispose() {
    _ticker.dispose(); // Descarto o ticker ao finalizar
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
    final wavePhase = (currentTime - _startTime).inMilliseconds / 1000.0; // Calcula a fase da onda

    return CustomPaint(
      painter: _WaterPainter(
        progress: _progressFraction, // Passo a fração de progresso
        wavePhase: wavePhase, // Passo a fase da onda
        waveIntensity: _waveIntensity, // Passo a intensidade da onda
        xTilt: _xTilt, // Passo a inclinação no eixo X
        yTilt: _yTilt, // Passo a inclinação no eixo Y
        progressColor: widget.progressColor, // Passo a cor do progresso
        backgroundColor: widget.backgroundColor, // Passo a cor de fundo
      ),
      child: const SizedBox(width: 320, height: 120), // Tamanho do widget
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double progress; // Progresso atual
  final double wavePhase; // Fase da onda
  final double waveIntensity; // Intensidade da onda
  final double xTilt; // Inclinação no eixo X
  final double yTilt; // Inclinação no eixo Y
  final Color progressColor; // Cor do progresso
  final Color backgroundColor; // Cor de fundo

  _WaterPainter({
    required this.progress,
    required this.wavePhase,
    required this.waveIntensity,
    required this.xTilt,
    required this.yTilt,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path roundedRect = _createRoundedRectPath(size); // Crio um caminho para o fundo arredondado

    canvas.save(); // Salvo o estado atual do canvas
    canvas.clipPath(roundedRect); // Aplico a máscara de recorte

    final Paint backgroundPaint = Paint()..color = backgroundColor; // Crio a tinta de fundo
    canvas.drawPath(roundedRect, backgroundPaint); // Desenho o fundo

    final Paint waterPaint = Paint()
      ..color = progressColor.withOpacity(0.65) // Crio a tinta da água com opacidade
      ..style = PaintingStyle.fill; // Defino o estilo de preenchimento

    final Path wavePath = Path(); // Crio um novo caminho para a onda
    final double baseHeight = size.height * (1 - progress); // Altura base da onda
    final double waveHeight = 8 * waveIntensity; // Altura da onda
    final double waveLength = size.width * 1.2; // Comprimento da onda

    wavePath.moveTo(0, baseHeight); // Começo o caminho da onda na base

    // Desenho a onda usando funções seno para criar um efeito de onda
    for (double x = 0; x <= size.width; x++) {
      final y = baseHeight +
          sin((2 * pi / waveLength) * x + wavePhase) * waveHeight +
          sin((2 * pi / (waveLength / 2)) * x + wavePhase * 1.2) * (waveHeight / 2);
      wavePath.lineTo(x, y); // Adiciono o ponto ao caminho
    }

    wavePath.lineTo(size.width, size.height); // Fecho o caminho na parte inferior direita
    wavePath.lineTo(0, size.height); // Fecho o caminho na parte inferior esquerda
    wavePath.close(); // Fecho o caminho da onda

    canvas.drawPath(wavePath, waterPaint); // Desenho a onda no canvas
    canvas.restore(); // Restaura o estado anterior do canvas
  }

  Path _createRoundedRectPath(Size size) {
    final radius = 20.0; // Defino o raio para as bordas arredondadas
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), // Crio um retângulo baseado no tamanho
        Radius.circular(radius), // Aplico o raio para bordas arredondadas
      ));
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) => true; // Indico que o desenho deve ser repintado
}
