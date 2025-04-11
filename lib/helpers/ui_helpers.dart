import 'package:flutter/material.dart';
//Provavelmente seria melhor refazer isso com um texto que mostra dinâmicamente o tempo desde o último copo d'água (futuramente quem sabe)
// Função para exibir uma mensagem de toast (notificação temporária) na tela
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 3)), // Mensagem e duração do toast
  );
}

// Função para mostrar um modal de hidratação
void showHydrationModal(BuildContext context, Function() onConfirm) {
  showDialog(
    context: context,
    barrierDismissible: false, // Impede que o modal seja fechado ao tocar fora dele
    builder: (_) => AlertDialog(
      title: const Text("Hora de beber água!"), // Título do modal
      content: const Text("Já bebeu água hoje? Hidratação é essencial. Lembre-se de beber água regularmente"), // Mensagem no modal
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Fecha o modal
            onConfirm(); // Chama a função de confirmação passada como argumento
          },
          child: const Text("Bebi!"), // Texto do botão de confirmação
        ),
      ],
    ),
  );
}
