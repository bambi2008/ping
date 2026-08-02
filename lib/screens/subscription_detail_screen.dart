import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../app/theme.dart';
import '../widgets/brand_icon.dart';
import '../widgets/glass_card.dart';
import '../widgets/cancel_celebration.dart';
import '../widgets/page_transitions.dart';
import '../widgets/press_scale.dart';
import '../widgets/glass_card.dart' as glass;
import '../widgets/odometer_roll.dart';
import 'add_subscription_screen.dart';
import 'cancel_guide_screen.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final String id;
  const SubscriptionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, p, _) {
        final s = p.subscriptions.firstWhere((sub) => sub.id == id);
        final daysLeft = DateTime(s.nextBillingDate.year, s.nextBillingDate.month, s.nextBillingDate.day)
            .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
        final themeColor = s.themeColor ?? SubscriptionTheme.categoryColors[s.category] ?? PingTheme.primary;
        final sym = CurrencyProvider.getSymbol(p.displayCurrency);
        final priceChanges = p.priceChangesFor(id);

        return Scaffold(
          appBar: AppBar(
            title: Text(s.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context,
                  SlideFadeRoute(page: AddSubscriptionScreen(subscription: s))),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(PingTheme.spaceXl),
            children: [
              // ── Hero ──
              Center(child: Column(children: [
                Hero(
                  tag: 'brand_${s.id}',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(scale: 0.7 + scale * 0.3, child: child),
                    child: BrandIcon(name: s.name, fallbackColor: themeColor, size: 80, borderRadius: PingTheme.radiusLg),
                  ),
                ),
                const SizedBox(height: PingTheme.spaceLg),
                Text(s.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: PingTheme.spaceXs),
                Text(s.category, style: TextStyle(fontSize: PingTheme.textSmall, color: PingTheme.subtleText(context))),
                const SizedBox(height: PingTheme.spaceSm),
                _StatusBadge(status: s.status),
              ])),

              const SizedBox(height: PingTheme.space2Xl),

              // ── Cost Card ──
              ElasticAppear(
                child: Container(
                padding: const EdgeInsets.all(PingTheme.spaceXl),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor.withValues(alpha: 0.08), themeColor.withValues(alpha: 0.03)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(PingTheme.radiusLg),
                    border: Border.all(color: themeColor.withValues(alpha: 0.15))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('You pay', style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textSmall, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    OdometerRoll(
                      value: s.amount,
                      prefix: s.currencySymbol,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: themeColor),
                    ),
                    Text('per ${s.billingCycle}', style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textCaption)),
                  ]),
                  Container(height: 50, width: 1, color: PingTheme.hairlineBorder(context)),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Monthly eq.', style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textSmall, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('$sym${s.convertedMonthlyAmount(p.displayCurrency).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: PingTheme.primary)),
                    Text('converted', style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textCaption)),
                  ]),
                ]),
              ),

              // ── Price change history ──
              if (priceChanges != null && priceChanges.isNotEmpty) ...[
                const SizedBox(height: PingTheme.spaceLg),
                Container(
                  padding: const EdgeInsets.all(PingTheme.spaceLg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(PingTheme.radiusLg),
                    border: Border.all(color: PingTheme.hairlineBorder(context))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.history, size: 18, color: PingTheme.subtleText(context)),
                      const SizedBox(width: PingTheme.spaceSm),
                      Text('Price history', style: Theme.of(context).textTheme.titleMedium),
                    ]),
                    const SizedBox(height: PingTheme.spaceMd),
                    ...priceChanges.map((change) => _priceChangeRow(context, change)),
                  ]),
                ),
              ],

              const SizedBox(height: PingTheme.spaceLg),

              // ── Next Billing Countdown ──
              Container(
                padding: const EdgeInsets.all(PingTheme.spaceLg),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(PingTheme.radiusLg),
                    border: Border.all(color: PingTheme.hairlineBorder(context))),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: (daysLeft <= 3 ? PingTheme.danger : PingTheme.warning).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd)),
                    child: Icon(daysLeft <= 3 ? Icons.warning_amber_rounded : Icons.event_rounded,
                        color: daysLeft <= 3 ? PingTheme.danger : PingTheme.warning, size: 24),
                  ),
                  const SizedBox(width: PingTheme.spaceMd),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Next billing', style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textCaption, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(_fmt(s.nextBillingDate), style: const TextStyle(fontSize: PingTheme.textBody, fontWeight: FontWeight.w600)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd, vertical: 6),
                    decoration: BoxDecoration(
                      color: daysLeft <= 3 ? PingTheme.danger.withValues(alpha: 0.12) : PingTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(PingTheme.radiusSm)),
                    child: Text(daysLeft <= 0 ? 'Due today' : '$daysLeft days left',
                        style: TextStyle(color: daysLeft <= 3 ? PingTheme.danger : PingTheme.primary, fontWeight: FontWeight.w700, fontSize: PingTheme.textSmall)),
                  ),
                ]),
              ),

              const SizedBox(height: PingTheme.spaceLg),

              // ── Info Grid ──
              ElasticAppear(
                delay: const Duration(milliseconds: 200),
                child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(PingTheme.radiusLg),
                    border: Border.all(color: PingTheme.hairlineBorder(context))),
                child: Column(children: [
                  _infoRow(context, Icons.repeat_rounded, 'Billing cycle', s.billingCycle),
                  _divider(context),
                  _infoRow(context, Icons.category_outlined, 'Category', s.category),
                  _divider(context),
                  _infoRow(context, Icons.credit_card_rounded, 'Payment', s.paymentMethod),
                  _divider(context),
                  _infoRow(context, Icons.language_rounded, 'Currency', '${s.currency} (${s.currencySymbol})'),
                  _divider(context),
                  _infoRow(context, Icons.source_outlined, 'Source', s.source == 'manual' ? 'Manual entry' : s.source.capitalize()),
                ]),
                ),
              ),

              const SizedBox(height: PingTheme.space2Xl),

              // ── Actions ──
              RepaintBoundary(child: PressScale(
                onTap: () => Navigator.push(context,
                    SlideFadeRoute(page: AddSubscriptionScreen(subscription: s))),
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [PingTheme.primary, PingTheme.primaryLight]),
                    borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                    boxShadow: [BoxShadow(color: PingTheme.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Subscription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: PingTheme.textBody)),
                  ]),
                ),
              )),
              const SizedBox(height: PingTheme.spaceMd),
              PressScale(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final cancelled = await Navigator.push<bool>(context,
                      SlideFadeRoute<bool>(page: CancelGuideScreen(serviceName: s.name)));
                  if (cancelled == true && context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => CancelCelebration(
                        subscriptionName: s.name,
                        monthlyAmount: s.amount,
                        currencySymbol: s.currencySymbol,
                        onDismiss: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                    );
                    await p.setStatus(id, SubscriptionStatus.cancelled);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    color: PingTheme.danger.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                    border: Border.all(color: PingTheme.danger.withValues(alpha: 0.2)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.cancel_outlined, color: PingTheme.danger, size: 20),
                    SizedBox(width: 8),
                    Text('Cancel Guide', style: TextStyle(color: PingTheme.danger, fontWeight: FontWeight.w700, fontSize: PingTheme.textBody)),
                  ]),
                ),
              ),
              const SizedBox(height: PingTheme.spaceSm),
              Row(children: [
                Expanded(child: PressScale(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await p.setStatus(id, s.isActive ? SubscriptionStatus.paused : SubscriptionStatus.active);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        s.isActive ? PingTheme.warning : PingTheme.success,
                        (s.isActive ? PingTheme.warning : PingTheme.success).withValues(alpha: 0.85),
                      ]),
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                      boxShadow: [BoxShadow(
                        color: (s.isActive ? PingTheme.warning : PingTheme.success).withValues(alpha: 0.3),
                        blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(s.isActive ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text(s.isActive ? 'Pause' : 'Resume', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                )),
                const SizedBox(width: PingTheme.spaceMd),
                Expanded(child: PressScale(
                  onTap: () async {
                    HapticFeedback.heavyImpact();
                    await p.removeSubscription(id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: PingTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                      border: Border.all(color: PingTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.delete_outline, color: PingTheme.danger, size: 20),
                      SizedBox(width: 6),
                      Text('Remove', style: TextStyle(color: PingTheme.danger, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                )),
              ]),
              const SizedBox(height: PingTheme.space2Xl),
            ],
          ),
        );
      },
    );
  }

  Widget _priceChangeRow(BuildContext context, dynamic change) {
    final isIncrease = change.isIncrease as bool;
    final delta = change.delta as double;
    final oldAmount = change.oldAmount as double;
    final newAmount = change.newAmount as double;
    return Padding(
      padding: const EdgeInsets.only(bottom: PingTheme.spaceSm),
      child: Row(children: [
        Icon(isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: isIncrease ? PingTheme.danger : PingTheme.success),
        const SizedBox(width: PingTheme.spaceSm),
        Text('${oldAmount.toStringAsFixed(2)} → ${newAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: PingTheme.textSmall, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text('${isIncrease ? '+' : ''}${delta.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: PingTheme.textSmall,
              fontWeight: FontWeight.w700,
              color: isIncrease ? PingTheme.danger : PingTheme.success,
            )),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg, vertical: PingTheme.spaceMd + 2),
      child: Row(children: [
        Icon(icon, size: 20, color: PingTheme.subtleText(context)),
        const SizedBox(width: PingTheme.spaceMd),
        Text(label, style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textBody)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: PingTheme.textBody)),
      ]),
    );
  }

  Widget _divider(BuildContext context) => Divider(height: 1, color: PingTheme.hairlineBorder(context));

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ── Status Badge ──
class _StatusBadge extends StatelessWidget {
  final SubscriptionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd, vertical: PingTheme.spaceXs + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: PingTheme.textSmall)),
      ]),
    );
  }

  Color _statusColor(SubscriptionStatus status) => switch (status) {
        SubscriptionStatus.active => PingTheme.success,
        SubscriptionStatus.trial => PingTheme.primary,
        SubscriptionStatus.paused => PingTheme.warning,
        SubscriptionStatus.cancelled => PingTheme.danger,
        SubscriptionStatus.expired => Colors.grey,
      };
}

extension _CapExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
