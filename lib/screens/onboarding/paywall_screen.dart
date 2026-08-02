import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/iap_provider.dart';

/// Hard paywall — user must start trial or purchase to proceed.
/// 3-day free trial, then auto-charges unless cancelled.
class PaywallScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const PaywallScreen({super.key, required this.onComplete});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly; // Default to yearly (better value)

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPProvider>();
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // No back button — hard paywall, but allow close to see what they miss
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(PingTheme.spaceMd),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // Show "are you sure" — they'll lose access
                  _showExitConfirm(context);
                },
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: PingTheme.space2Xl, vertical: PingTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero
                  Container(
                    padding: const EdgeInsets.all(PingTheme.space2Xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [PingTheme.primary.withValues(alpha: 0.10), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(PingTheme.radiusLg),
                    ),
                    child: Column(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [PingTheme.primary, PingTheme.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.notifications_active_rounded,
                            size: 32, color: Colors.white),
                      ),
                      const SizedBox(height: PingTheme.spaceLg),
                      Text('Unlock Ping',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: PingTheme.spaceXs),
                      Text('3 days free. Cancel anytime.\nNo commitment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PingTheme.subtleText(context),
                          fontSize: PingTheme.textBody,
                          height: 1.5,
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: PingTheme.space2Xl),

                  // Features list
                  _featureItem(Icons.track_changes, 'Unlimited subscription tracking',
                      'Add and manage as many subscriptions as you need'),
                  _featureItem(Icons.notifications_active, 'Smart renewal alerts',
                      '3-day, 1-day, and day-of reminders before every bill'),
                  _featureItem(Icons.trending_up, 'Spending insights & trends',
                      'See how your costs change month over month'),
                  _featureItem(Icons.calendar_month, 'Bill calendar view',
                      'Never wonder when the next charge hits'),
                  _featureItem(Icons.currency_exchange, 'Multi-currency support',
                      'Live exchange rates for 16+ currencies'),
                  _featureItem(Icons.cancel, 'Cancel guidance',
                      'Step-by-step instructions to cancel any service'),

                  const SizedBox(height: PingTheme.space2Xl),

                  // ── Plan selector ──
                  Text('Choose your plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: PingTheme.spaceMd),

                  // Yearly (recommended)
                  _planCard(
                    plan: SubscriptionPlan.yearly,
                    isSelected: _selectedPlan == SubscriptionPlan.yearly,
                    badge: 'BEST VALUE · Save 44%',
                    price: '€19.99',
                    period: '/year',
                    subtext: 'Just €1.67/month',
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedPlan = SubscriptionPlan.yearly); },
                  ),
                  const SizedBox(height: PingTheme.spaceSm),

                  // Monthly
                  _planCard(
                    plan: SubscriptionPlan.monthly,
                    isSelected: _selectedPlan == SubscriptionPlan.monthly,
                    badge: null,
                    price: '€2.99',
                    period: '/month',
                    subtext: 'Cancel anytime',
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedPlan = SubscriptionPlan.monthly); },
                  ),

                  const SizedBox(height: PingTheme.space2Xl),

                  // ── Trial banner ──
                  Container(
                    padding: const EdgeInsets.all(PingTheme.spaceLg),
                    decoration: BoxDecoration(
                      color: PingTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                      border: Border.all(color: PingTheme.success.withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: PingTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                        ),
                        child: const Icon(Icons.card_giftcard, color: PingTheme.success, size: 20),
                      ),
                      const SizedBox(width: PingTheme.spaceMd),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('3-Day Free Trial',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: PingTheme.textBody, color: PingTheme.success)),
                          const SizedBox(height: 2),
                          Text('Start today. We won\'t charge you for 3 days.\nCancel before then and pay nothing.',
                            style: TextStyle(
                              color: PingTheme.subtleText(context),
                              fontSize: PingTheme.textCaption,
                              height: 1.4,
                            )),
                        ],
                      )),
                    ]),
                  ),

                  const SizedBox(height: PingTheme.space2Xl),

                  // ── CTA ──
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: iap.isLoading ? null : () async {
                        HapticFeedback.mediumImpact();
                        // Start trial first, then purchase (or just trial)
                        await iap.startTrial();
                        widget.onComplete();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: PingTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                        ),
                      ),
                      child: iap.isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Start 3-Day Free Trial',
                              style: TextStyle(
                                fontSize: PingTheme.textBody,
                                fontWeight: FontWeight.w800,
                              )),
                    ),
                  ),
                  const SizedBox(height: PingTheme.spaceMd),

                  // Restore + terms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async { await iap.restore(); },
                        child: Text('Restore purchases',
                            style: TextStyle(
                                color: PingTheme.subtleText(context),
                                fontSize: PingTheme.textSmall)),
                      ),
                      Text(' · ',
                          style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textSmall)),
                      TextButton(
                        onPressed: () => _showTerms(context),
                        child: Text('Terms',
                            style: TextStyle(
                                color: PingTheme.subtleText(context),
                                fontSize: PingTheme.textSmall)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PingTheme.spaceMd),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: PingTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(PingTheme.radiusSm),
          ),
          child: Icon(icon, size: 18, color: PingTheme.primary),
        ),
        const SizedBox(width: PingTheme.spaceMd),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: PingTheme.textBody)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textCaption)),
          ],
        )),
      ]),
    );
  }

  Widget _planCard({
    required SubscriptionPlan plan,
    required bool isSelected,
    String? badge,
    required String price,
    required String period,
    String? subtext,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(PingTheme.spaceLg),
        decoration: BoxDecoration(
          color: isSelected
              ? PingTheme.primary.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
          border: Border.all(
            color: isSelected ? PingTheme.primary : PingTheme.hairlineBorder(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          // Radio
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? PingTheme.primary : PingTheme.subtleText(context),
            size: 24,
          ),
          const SizedBox(width: PingTheme.spaceMd),
          // Content
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PingTheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(PingTheme.radiusXs),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: PingTheme.secondary,
                      )),
                ),
                const SizedBox(height: 4),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? PingTheme.primary : null,
                    )),
                  Text(period,
                    style: TextStyle(
                      fontSize: PingTheme.textSmall,
                      color: PingTheme.subtleText(context),
                    )),
                ],
              ),
              if (subtext != null) ...[
                const SizedBox(height: 2),
                Text(subtext,
                    style: TextStyle(
                      fontSize: PingTheme.textCaption,
                      color: PingTheme.subtleText(context),
                    )),
              ],
            ],
          )),
        ]),
      ),
    );
  }

  void _showExitConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip for now?'),
        content: const Text(
            'You can try Ping for free, but you won\'t be able to add\n'
            'subscriptions or get reminders until you start your trial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Start trial'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Exit paywall
            },
            child: Text('Skip', style: TextStyle(color: PingTheme.subtleText(context))),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PingTheme.radiusLg)),
      ),
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(PingTheme.space2Xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subscription Terms',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: PingTheme.spaceMd),
            Text(
              '• 3-day free trial: No charge for the first 3 days.\n'
              '• After trial: Auto-renews at the selected plan price.\n'
              '• Cancel anytime: Turn off auto-renewal in Settings or App Store.\n'
              '• Refunds: Subject to Apple/Google refund policies.\n'
              '• Pricing may change for future renewals with notice.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: PingTheme.spaceLg),
          ],
        ),
      ),
    );
  }
}
