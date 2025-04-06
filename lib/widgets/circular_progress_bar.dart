import 'package:flutter/material.dart';
import 'dart:math';

class CircularProgressBar extends StatefulWidget {
  final double progress;
  final double max;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;
  final Duration animationDuration;

  const CircularProgressBar({
    super.key,
    required this.progress,
    this.max = 100,
    this.progressColor = Colors.blueAccent,
    this.backgroundColor = Colors.grey,
    this.strokeWidth = 20.0,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<CircularProgressBar> createState() => _CircularProgressBarState();
}

class _CircularProgressBarState extends State<CircularProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0;

  double get _progressFraction =>
      widget.max == 0 ? 0 : widget.progress.clamp(0, widget.max) / widget.max;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_controller);

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant CircularProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaterWavePainter(
        wavePhase: _animation.value,
        progress: _progressFraction,
        progressColor: widget.progressColor,
        backgroundColor: widget.backgroundColor,
      ),
      child: const SizedBox(
        width: 200,
        height: 200,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _WaterWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color progressColor;
  final Color backgroundColor;

  _WaterWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circleRect = Rect.fromCircle(center: center, radius: radius);

    canvas.save();
    canvas.clipPath(Path()..addOval(circleRect));

    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawCircle(center, radius, backgroundPaint);

    final path = Path();
    double waveHeight = 8;
    double waveLength = size.width;
    double baseHeight = size.height * (1 - progress);

    path.moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      double y = waveHeight * sin((2 * pi / waveLength) * x + wavePhase) + baseHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final wavePaint = Paint()..color = progressColor.withOpacity(0.6);
    canvas.drawPath(path, wavePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
