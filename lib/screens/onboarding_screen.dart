import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            const Spacer(flex: 2),
            // Hero illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [PingTheme.primary, Color(0xFFA29BFE)]),
                  boxShadow: [
                    BoxShadow(
                        color: PingTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 8))
                  ]),
              child:
                  const Icon(Icons.auto_awesome, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 40),
            // Headline
            const Text('Stop losing money to\nforgotten subscriptions',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 16),
            Text(
                'Track recurring payments locally and get a reminder before the next charge.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 12),
            // Feature pills
            Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _chip('✍️ Simple tracking', PingTheme.primary),
                  _chip('🔔 Alerts', PingTheme.secondary),
                  _chip('📅 Renewal calendar', PingTheme.success),
                  _chip('🔒 Private', PingTheme.warning),
                ]),
            const Spacer(flex: 2),
            // CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _finish,
                icon: const Icon(Icons.add),
                label: const Text('Add My First Subscription'),
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your subscription data stays on this device.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              fontSize: 13, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
