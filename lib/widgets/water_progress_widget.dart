import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class WaterProgressWidget extends StatefulWidget {
  final double progress;
  final Color waterColor;

  const WaterProgressWidget({
    super.key,
    required this.progress,
    this.waterColor = Colors.blue,
  });

  @override
  State<WaterProgressWidget> createState() => _WaterProgressWidgetState();
}

class _WaterProgressWidgetState extends State<WaterProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  double _xTilt = 0;
  double _yTilt = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Armazenamos a subscription para poder cancelar depois
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (mounted) { // Verificamos se o widget ainda está montado
        setState(() {
          _xTilt = event.x.clamp(-3, 3) * 0.3;
          _yTilt = event.y.clamp(-3, 3) * 0.3;
        });
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _accelerometerSubscription?.cancel(); // Cancelamos a subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(320, 120),
                  painter: WaterPainter(
                    progress: widget.progress,
                    wavePhase: _waveController.value * 2 * pi,
                    xTilt: _xTilt,
                    yTilt: _yTilt,
                    waterColor: widget.waterColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class WaterPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final double xTilt;
  final double yTilt;
  final Color waterColor;

  WaterPainter({
    required this.progress,
    required this.wavePhase,
    required this.xTilt,
    required this.yTilt,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waterLevel = size.height * (1 - progress);
    final waveHeight = 4 * (0.3 + progress * 0.7);
    final waveLength = size.width * 1.5;

    final waterPath = Path()
      ..moveTo(-10, waterLevel);

    for (double x = -10; x <= size.width + 10; x += 5) {
      final y = waterLevel +
          sin((2 * pi / waveLength) * x + wavePhase) * waveHeight;
      waterPath.lineTo(x, y);
    }

    waterPath
      ..lineTo(size.width + 10, size.height + 10)
      ..lineTo(-10, size.height + 10)
      ..close();

    final paint = Paint()
      ..color = waterColor.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // CORREÇÃO: Transformação do canvas de forma correta
    final matrix = Matrix4.identity()
      ..rotateX(xTilt * pi / 180)
      ..rotateY(yTilt * pi / 180);

    canvas.save();
    canvas.transform(matrix.storage); // Usando .storage para obter Float64List

    canvas.drawPath(waterPath, paint);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) => true;
}