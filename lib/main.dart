import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart'; // Configurações do Firebase
import 'screens/register_screen.dart'; // Tela de registro
import 'screens/login_screen.dart'; // Tela de login
import 'screens/main_screen.dart'; // Tela principal
import 'screens/profile_screen.dart'; // Tela de perfil

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Garante que o Flutter esteja inicializado antes de qualquer coisa

  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Configurações específicas da plataforma
  );

  // Solicita permissão para reconhecimento de atividade
  await _ensureActivityRecognitionPermission();

  // Cria o canal de notificações
  await _setupNotificationChannel();

  runApp(const MyApp()); // Executa o aplicativo
}

// Função para garantir que a permissão de reconhecimento de atividade seja concedida
Future<void> _ensureActivityRecognitionPermission() async {
  final status = await Permission.activityRecognition.status; // Verifica o status da permissão
  if (!status.isGranted) {
    await Permission.activityRecognition.request(); // Solicita a permissão se não estiver concedida
  }
}

// Função para configurar o canal de notificações
Future<void> _setupNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'hydration_channel', // ID do canal
    'Lembretes de Hidratação', // Nome do canal
    description: 'Notificações para lembrar de beber água', // Descrição do canal
    importance: Importance.high, // Importância das notificações
  );

  // Cria o canal de notificações para Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Inicializa as configurações de notificações
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'), // Ícone das notificações
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HidraFit', // Título do aplicativo
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Esquema de cores
        useMaterial3: true, // Usa Material Design 3
      ),
      navigatorObservers: [routeObserver], // Observador de rotas
      initialRoute: _getInitialRoute(), // Define a rota inicial
      routes: {
        '/login': (context) => const LoginScreen(), // Rota para a tela de login
        '/register': (context) => const RegisterScreen(), // Rota para a tela de registro
        '/main': (context) => const MainScreen(), // Rota para a tela principal
        '/profile': (context) => const ProfileScreen(), // Rota para a tela de perfil
      },
      debugShowCheckedModeBanner: false, // Oculta a faixa de depuração
    );
  }

  // Função para determinar a rota inicial com base na autenticação do usuário
  String _getInitialRoute() {
    final user = FirebaseAuth.instance.currentUser; // Verifica se o usuário está autenticado
    return user != null ? '/main' : '/register'; // Rota inicial: tela principal ou tela de registro
  }
}
