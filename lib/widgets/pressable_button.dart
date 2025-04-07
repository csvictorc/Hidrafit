import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PressableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const PressableButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  double _scale = 1.0;
  double _opacity = 1.0;

  void _animatePressDown() {
    setState(() {
      _scale = 0.92;
      _opacity = 0.85;
    });
    HapticFeedback.lightImpact();
  }

  void _animatePressUp() {
    setState(() {
      _scale = 1.0;
      _opacity = 1.0;
    });
  }

  Future<void> _handleTap() async {
    _animatePressDown();
    await Future.delayed(const Duration(milliseconds: 150)); // deixa a animação acontecer
    _animatePressUp();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _opacity,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
