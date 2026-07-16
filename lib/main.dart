import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/theme.dart';
import 'models/subscription_provider.dart';
import 'services/notification_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => SubscriptionProvider()..init(),
      child: const PingApp(),
    ),
  );
}

class PingApp extends StatelessWidget {
  const PingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ping — Subscription Tracker',
      debugShowCheckedModeBanner: false,
      theme: PingTheme.light,
      darkTheme: PingTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
        Locale('nl'),
      ],
      home: const DashboardScreen(),
    );
  }
}
