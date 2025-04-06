import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Solicita permissão para reconhecimento de atividade
  await _ensureActivityRecognitionPermission();

  runApp(const MyApp());
}

Future<void> _ensureActivityRecognitionPermission() async {
  final status = await Permission.activityRecognition.status;
  if (!status.isGranted) {
    await Permission.activityRecognition.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydraFit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      navigatorObservers: [routeObserver],
      initialRoute: _getInitialRoute(), // Rota dinâmica
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  String _getInitialRoute() {
    // Verifica o estado de autenticação do Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Se o usuário estiver logado, vai para a tela principal
      return '/main';
    } else {
      // Se o usuário não estiver logado, vai para a tela de registro
      return '/register';
    }
  }
}
