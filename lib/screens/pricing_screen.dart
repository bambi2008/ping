import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/subscription_provider.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ping Premium'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          // Hero
          const Icon(Icons.auto_awesome, size: 64, color: PingTheme.primary),
          const SizedBox(height: 16),
          const Text('Unlock the Full Power of Ping', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('One payment. Lifetime access. No subscriptions. Ever.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          const SizedBox(height: 32),

          // Features comparison
          _buildFeatureRow('Manual subscription tracking', true, true),
          _buildFeatureRow('Unlimited subscriptions', false, true),
          _buildFeatureRow('Bank auto-discovery', false, true),
          _buildFeatureRow('Renewal notifications', true, true),
          _buildFeatureRow('Multi-currency support', false, true),
          _buildFeatureRow('Widget (Home + Lock Screen)', false, true),
          _buildFeatureRow('Custom themes & logos', false, true),
          _buildFeatureRow('Data export (CSV/PDF)', false, true),
          _buildFeatureRow('iCloud sync', false, true),
          const SizedBox(height: 32),

          // Price card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [PingTheme.primary, Color(0xFFA29BFE)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Forever Pass', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('€19.99', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800)),
                const Text('one-time · lifetime access', style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('No subscription required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: FilledButton(
                    onPressed: _purchasing ? null : _purchase,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: PingTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _purchasing
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Unlock Forever', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe later — continue with free version'),
            ),
          ),
          const SizedBox(height: 32),
          // Trust signals
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text('Secure payment', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 16),
              Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text('No data collection', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String label, bool free, bool premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Icon(free ? Icons.check : Icons.close, size: 18, color: free ? PingTheme.success : Colors.grey[400]),
          const SizedBox(width: 24),
          Icon(Icons.check, size: 18, color: PingTheme.primary),
        ],
      ),
    );
  }

  void _purchase() async {
    setState(() => _purchasing = true);
    // Simulate purchase — in production, integrate RevenueCat or StoreKit
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      await context.read<SubscriptionProvider>().unlockPremium();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Welcome to Ping Premium! Lifetime access unlocked.'), behavior: SnackBarBehavior.floating),
      );
    }
    setState(() => _purchasing = false);
  }
}
