import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Esse botão é usado só na home screen pra cofirmar que o usuário acabou de beber água

class PressableButton extends StatefulWidget {
  final VoidCallback onPressed; // Função a ser chamada quando o botão é pressionado
  final String label; // Texto a ser exibido no botão

  const PressableButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  double _scale = 1.0; // Escala inicial do botão
  double _opacity = 1.0; // Opacidade inicial do botão

  // Método para animar o efeito de pressionar o botão
  void _animatePressDown() {
    setState(() {
      _scale = 0.92; // Reduz a escala para dar um efeito de pressão
      _opacity = 0.85; // Reduz a opacidade para dar um efeito de destaque
    });
    HapticFeedback.lightImpact(); // Adiciona feedback tátil ao pressionar
  }

  // Método para animar o efeito de soltar o botão
  void _animatePressUp() {
    setState(() {
      _scale = 1.0; // Restaura a escala original
      _opacity = 1.0; // Restaura a opacidade original
    });
  }

  // Método para lidar com o toque no botão
  Future<void> _handleTap() async {
    _animatePressDown(); // Anima o pressionamento
    await Future.delayed(const Duration(milliseconds: 150)); // Espera a animação acontecer
    _animatePressUp(); // Anima a liberação
    widget.onPressed(); // Chama a função passada como parâmetro
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, // Permite detectar toques em áreas transparentes
        onTap: _handleTap, // Define o que acontece ao tocar no botão
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100), // Duração da animação de opacidade
          opacity: _opacity, // Aplica a opacidade animada
          child: AnimatedScale(
            scale: _scale, // Aplica a escala animada
            duration: const Duration(milliseconds: 180), // Duração da animação de escala
            curve: Curves.easeOutBack, // Curva da animação
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12), // Bordas arredondadas
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efeito de desfoque de fundo
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Espaçamento interno
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent.withOpacity(0.15), // Cor de fundo com opacidade
                    borderRadius: BorderRadius.circular(12), // Bordas arredondadas
                    border: Border.all(color: Colors.grey.withOpacity(0.3)), // Borda cinza com opacidade
                  ),
                  child: Text(
                    widget.label, // Exibe o texto do botão
                    style: const TextStyle(
                      fontSize: 16, // Tamanho da fonte
                      color: Colors.black, // Cor do texto
                      fontWeight: FontWeight.bold, // Peso da fonte
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
