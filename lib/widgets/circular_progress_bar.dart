import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class CircularProgressBar extends StatefulWidget {
  final double progress;
  final double max;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

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
  late final Ticker _ticker;

  double _xTilt = 0;
  double _yTilt = 0;
  double _waveIntensity = 0.2;
  double _targetWaveIntensity = 0.2;

  final double _maxIntensity = 1.0;
  final double _minIntensity = 0.2;
  DateTime _lastMotionTime = DateTime.now();
  Duration _startTime = Duration.zero;

  double get _progressFraction =>
      widget.max == 0 ? 0 : widget.progress.clamp(0, widget.max) / widget.max;

  @override
  void initState() {
    super.initState();

    _startTime = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
    _ticker = Ticker(_onTick)..start();

    accelerometerEvents.listen((event) {
      double dx = event.x - _xTilt;
      double dy = event.y - _yTilt;
      double delta = sqrt(dx * dx + dy * dy);

      if (delta > 1.2) {
        _xTilt = event.x.clamp(-10, 10);
        _yTilt = event.y.clamp(-10, 10);
        _lastMotionTime = DateTime.now();
        _targetWaveIntensity = _maxIntensity;
      }
    });

    _startSmoothIntensityAdjuster();
  }

  void _onTick(Duration elapsed) {
    final timeSinceLastMotion = DateTime.now().difference(_lastMotionTime).inMilliseconds;
    if (timeSinceLastMotion > 1000) {
      _targetWaveIntensity = _minIntensity;
    }

    setState(() {
      _waveIntensity += (_targetWaveIntensity - _waveIntensity) * 0.05;
    });
  }

  void _startSmoothIntensityAdjuster() {
    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) timer.cancel();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
    final wavePhase = (currentTime - _startTime).inMilliseconds / 1000.0;

    return CustomPaint(
      painter: _WaterPainter(
        progress: _progressFraction,
        wavePhase: wavePhase,
        waveIntensity: _waveIntensity,
        xTilt: _xTilt,
        yTilt: _yTilt,
        progressColor: widget.progressColor,
        backgroundColor: widget.backgroundColor,
      ),
      child: const SizedBox(width: 320, height: 120),
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final double waveIntensity;
  final double xTilt;
  final double yTilt;
  final Color progressColor;
  final Color backgroundColor;

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
    final Path roundedRect = _createRoundedRectPath(size);

    canvas.save();
    canvas.clipPath(roundedRect);

    final Paint backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawPath(roundedRect, backgroundPaint);

    final Paint waterPaint = Paint()
      ..color = progressColor.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final Path wavePath = Path();
    final double baseHeight = size.height * (1 - progress);
    final double waveHeight = 8 * waveIntensity;
    final double waveLength = size.width * 1.2;

    wavePath.moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      final y = baseHeight +
          sin((2 * pi / waveLength) * x + wavePhase) * waveHeight +
          sin((2 * pi / (waveLength / 2)) * x + wavePhase * 1.2) * (waveHeight / 2);
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, waterPaint);
    canvas.restore();
  }

  Path _createRoundedRectPath(Size size) {
    final radius = 20.0;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) => true;
}
