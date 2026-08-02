import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme.dart';
import 'widgets/page_transitions.dart';
import 'models/subscription_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/iap_provider.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/dashboard_screen.dart';
import 'screens/subscription_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/quick_add_screen.dart';
import 'screens/add_subscription_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final hasOnboarded = prefs.getBool('onboarded') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => IAPProvider()..init()),
      ],
      child: PingApp(showOnboarding: !hasOnboarded),
    ),
  );
}

class PingApp extends StatefulWidget {
  final bool showOnboarding;
  const PingApp({super.key, this.showOnboarding = false});

  @override
  State<PingApp> createState() => _PingAppState();
}

class _PingAppState extends State<PingApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PingTheme.light,
        darkTheme: PingTheme.dark,
        themeMode: ThemeMode.system,
        home: SplashScreen(onComplete: () => setState(() => _showSplash = false)),
      );
    }
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
      home: widget.showOnboarding
          ? OnboardingFlow(onComplete: () => _navigateToHome(context))
          : const _MainShell(),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      SlideFadeRoute(page: const _MainShell()),
      (route) => false,
    );
  }
}

/// Bottom-nav shell hosting Dashboard, List, Calendar, and Settings.
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
    final iap = context.watch<IAPProvider>();

    // If trial expired and no active subscription, show paywall again
    if (iap.isExpired && (ModalRoute.of(context)?.isCurrent ?? false)) {
      // Show banner but don't block
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Your trial has ended. Subscribe to continue.'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Subscribe',
                onPressed: () {
                  // Navigate to settings or paywall
                },
              ),
            ),
          );
        }
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      floatingActionButton: _index <= 2
          ? FloatingActionButton.extended(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(
                  context,
                  SlideFadeRoute(page: const QuickAddScreen()),
                );
              },
              icon: const Icon(Icons.add, semanticLabel: 'Add subscription'),
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
