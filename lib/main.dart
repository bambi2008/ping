import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme.dart';
import 'models/subscription_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/subscription_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/add_subscription_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';

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
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      initialRoute: showOnboarding ? '/onboarding' : '/home',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const _MainShell());
          default:
            return MaterialPageRoute(builder: (_) => const _MainShell());
        }
      },
    );
  }
}

/// Bottom-nav shell hosting Dashboard, List, and Settings.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const SubscriptionListScreen(),
    const CalendarScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddSubscriptionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Subs',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
