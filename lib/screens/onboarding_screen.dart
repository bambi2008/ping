import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/subscription_provider.dart';
import '../services/api_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final _pageCtrl = PageController();
  bool _connecting = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildPage(
                    emoji: '💸',
                    title: 'Stop losing money\nto forgotten subscriptions',
                    subtitle: 'The average European wastes €60-90/month on subscriptions they forgot about.',
                  ),
                  _buildPage(
                    emoji: '🔍',
                    title: 'Ping finds them all\nin seconds',
                    subtitle: 'Connect your bank securely via Open Banking. We automatically detect every recurring payment.',
                  ),
                  _buildPage(
                    emoji: '🔔',
                    title: 'Get alerted before\nyou get charged',
                    subtitle: 'Bill reminders 3 days before. Free trial expiration alerts. Never pay for something you don\'t use.',
                  ),
                ],
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _page == i ? PingTheme.primary : PingTheme.primary.withValues(alpha: 0.25),
                ),
              )),
            ),
            const SizedBox(height: 32),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _connecting ? null : () => _connectBank(context),
                      icon: _connecting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.account_balance),
                      label: Text(_connecting ? 'Connecting...' : 'Connect Your Bank'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _skip(context),
                    child: const Text('Skip for now — I\'ll add subscriptions manually'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required String emoji, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(subtitle, style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _connectBank(BuildContext context) async {
    setState(() => _connecting = true);
    final provider = context.read<SubscriptionProvider>();

    if (!ApiConfig.useRealApi) {
      // Mock mode: directly load mock data
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _connecting = false);
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
      return;
    }

    final url = await provider.startBankConnection('user_${DateTime.now().millisecondsSinceEpoch}');
    if (mounted) {
      setState(() => _connecting = false);
      if (url != null) {
        // In production: url_launcher to open bank auth in Safari
        // For now: simulate success
        provider.onBankAuthCallback('mock_code');
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Try manual entry instead.')),
        );
      }
    }
  }

  void _skip(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }
}
