import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/time_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  try {
    await StorageService.initialize();
    await ApiService.initialize();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runZonedGuarded(
    () => runApp(const TimeSetorApp()),
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

class TimeSetorApp extends StatefulWidget {
  const TimeSetorApp({super.key});

  @override
  State<TimeSetorApp> createState() => _TimeSetorAppState();
}

class _TimeSetorAppState extends State<TimeSetorApp> {
  final AuthProvider _authProvider = AuthProvider();
  final TimeProvider _timeProvider = TimeProvider();
  final PomodoroProvider _pomodoroProvider = PomodoroProvider();
  final SettingsProvider _settingsProvider = SettingsProvider();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _authProvider.initialize();
    await _settingsProvider.initialize();
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _timeProvider),
        ChangeNotifierProvider.value(value: _pomodoroProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
      ],
      child: MaterialApp(
        title: 'TimeSetor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: AppConstants.backgroundColor,
          cardColor: AppConstants.cardColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppConstants.cardColor,
            elevation: 0,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
            brightness: Brightness.dark,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoggedIn) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
