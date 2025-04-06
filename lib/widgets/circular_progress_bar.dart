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
    this.progressColor = Colors.green,
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
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(
      begin: 0,
      end: _progressFraction,
    ).animate(_controller)
      ..addListener(() => setState(() {}));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CircularProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progress != widget.progress || oldWidget.max != widget.max) {
      _oldProgress = _animation.value;

      _controller
        ..reset()
        ..duration = widget.animationDuration;

      _animation = Tween<double>(
        begin: _oldProgress,
        end: _progressFraction,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.decelerate),
      )..addListener(() => setState(() {}));

      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircularProgressPainter(
        progress: _animation.value,
        progressColor: widget.progressColor,
        backgroundColor: widget.backgroundColor,
        strokeWidth: widget.strokeWidth,
      ),
        child: SizedBox(
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

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  const _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fgPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double radius = (min(size.width, size.height) - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
