import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../models/subscription_provider.dart';
import '../services/api_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _connecting = false;

  Future<void> _finish(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
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
              width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [PingTheme.primary, Color(0xFFA29BFE)]), boxShadow: [BoxShadow(color: PingTheme.primary.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 8))]),
              child: const Icon(Icons.auto_awesome, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 40),
            // Headline
            const Text('Stop losing money to\nforgotten subscriptions', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 16),
            Text('Ping finds every recurring payment and alerts you before you get charged.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 12),
            // Feature pills
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              _chip('🏦 Bank sync', PingTheme.primary),
              _chip('🔔 Alerts', PingTheme.secondary),
              _chip('💰 Save €60/mo', PingTheme.success),
              _chip('🔒 Private', PingTheme.warning),
            ]),
            const Spacer(flex: 2),
            // CTA
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton.icon(
                onPressed: _connecting ? null : () => _connectBank(context),
                icon: _connecting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.account_balance),
                label: Text(_connecting ? 'Connecting...' : 'Connect Your Bank'),
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => _finish(context), child: const Text('Skip — I\'ll add subscriptions manually')),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _connectBank(BuildContext context) async {
    setState(() => _connecting = true);
    final provider = context.read<SubscriptionProvider>();
    if (!ApiConfig.useRealApi) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) { setState(() => _connecting = false); await _finish(context); }
      return;
    }
    final url = await provider.startBankConnection('user_${DateTime.now().millisecondsSinceEpoch}');
    if (mounted) {
      setState(() => _connecting = false);
      if (url != null) {
        provider.onBankAuthCallback('mock_code');
        await _finish(context);
      }
    }
  }
}
