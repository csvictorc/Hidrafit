import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _ensureActivityRecognitionPermission();
  await _setupNotificationChannel();
  runApp(const MyApp());
}

Future<void> _ensureActivityRecognitionPermission() async {
  final status = await Permission.activityRecognition.status;
  if (!status.isGranted) {
    await Permission.activityRecognition.request();
  }
}

Future<void> _setupNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'hydration_channel',
    'Lembretes de Hidratação',
    description: 'Notificações para lembrar de beber água',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?._setLocale(locale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  // Carregar o idioma baseado no idioma do sistema ou idioma salvo nas preferências
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLangCode = prefs.getString('locale');
    if (savedLangCode != null) {
      setState(() {
        _locale = Locale(savedLangCode);
      });
    } else {
      _setSystemLocale();
    }
  }

  // Definir o idioma baseado no sistema Android (pt-BR ou outro)
  Future<void> _setSystemLocale() async {
    final locale = WidgetsBinding.instance.window.locale;
    String langCode = 'en'; // Padrão é inglês
    if (locale.languageCode == 'pt' && locale.countryCode == 'BR') {
      langCode = 'pt'; // Se for português do Brasil, define pt
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', langCode); // Salva o idioma
    setState(() {
      _locale = Locale(langCode); // Atualiza o estado com o novo idioma
    });
  }

  // Salvar o idioma selecionado nas preferências e atualizar o locale
  void _setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    setState(() {
      _locale = locale; // Atualiza o estado com o novo idioma
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HidraFit',
      locale: _locale, // Definir o locale baseado na variável de estado
      localizationsDelegates: const [
        AppLocalizations.delegate, // Carrega as traduções
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      navigatorObservers: [routeObserver],
      initialRoute: _getInitialRoute(),
      routes: {
        '/login': (context) => LoginScreen(onLocaleChange: _setLocale),
        '/register': (context) => RegisterScreen(onLocaleChange: _setLocale),
        '/main': (context) => const MainScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  // Definir a rota inicial baseado no estado de autenticação do usuário
  String _getInitialRoute() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? '/main' : '/register';
  }
}
