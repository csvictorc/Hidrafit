import 'package:flutter/material.dart';

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
  );
}

void showHydrationModal(BuildContext context, Function() onConfirm) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("Hora de beber água!"),
      content: const Text("Já bebeu água hoje? Hidratação é essencial. Lembre-se de beber água regularmente"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text("Bebi!"),
        ),
      ],
    ),
  );
}