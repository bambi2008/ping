import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme.dart';
import 'models/subscription_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final hasOnboarded = prefs.getBool('onboarded') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => SubscriptionProvider()..init(),
      child: PingApp(showOnboarding: !hasOnboarded),
    ),
  );
}

class PingApp extends StatelessWidget {
  final bool showOnboarding;
  const PingApp({super.key, this.showOnboarding = false});

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
        Locale('en'), Locale('de'), Locale('fr'), Locale('es'), Locale('nl'),
      ],
      initialRoute: showOnboarding ? '/onboarding' : '/dashboard',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          default:
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
        }
      },
    );
  }
}
