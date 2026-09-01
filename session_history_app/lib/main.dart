import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/messaging/app_messenger.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const SessionHistoryApp());
}

class SessionHistoryApp extends StatefulWidget {
  const SessionHistoryApp({super.key});

  @override
  State<SessionHistoryApp> createState() => _SessionHistoryAppState();
}

class _SessionHistoryAppState extends State<SessionHistoryApp> {
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Session History',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: appMessengerKey,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
