import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/subscription.dart';
import '../models/subscription_provider.dart';
import '../services/subscription_templates.dart';
import 'add_subscription_screen.dart';

/// 快速添加 — 从模板网格一键选择常见订阅，预填好价格和分类。
/// 也可以跳到手动添加。
class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});
  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final Set<String> _selected = {};
  bool _showManual = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subscription'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showManual = !_showManual),
            child: Text(_showManual ? 'Pick from list' : 'Manual'),
          ),
        ],
      ),
      body: _showManual
          ? const AddSubscriptionScreen()
          : _buildTemplateGrid(context),
    );
  }

  Widget _buildTemplateGrid(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final existingNames = provider.subscriptions.map((s) => s.name.toLowerCase()).toSet();

    return Column(
      children: [
        // Hint
        Padding(
          padding: const EdgeInsets.fromLTRB(
              PingTheme.spaceLg, PingTheme.spaceMd, PingTheme.spaceLg, PingTheme.spaceSm),
          child: Row(
            children: [
              Icon(Icons.bolt, size: 16, color: PingTheme.primary),
              const SizedBox(width: 6),
              Text('Tap to add — we pre-fill the details',
                  style: TextStyle(
                    color: PingTheme.subtleText(context),
                    fontSize: PingTheme.textSmall,
                  )),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
                PingTheme.spaceLg, 0, PingTheme.spaceLg, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: SubscriptionTemplates.all.length,
            itemBuilder: (context, index) {
              final t = SubscriptionTemplates.all[index];
              final alreadyAdded = existingNames.contains(t.name.toLowerCase());
              return _buildTemplateCard(t, alreadyAdded);
            },
          ),
        ),

        // Bottom CTA
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildTemplateCard(SubscriptionTemplate t, bool alreadyAdded) {
    final isSelected = _selected.contains(t.id);

    return GestureDetector(
      onTap: alreadyAdded ? null : () {
        HapticFeedback.mediumImpact();
        setState(() {
          if (isSelected) {
            _selected.remove(t.id);
          } else {
            _selected.add(t.id);
          }
        });
      },
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: alreadyAdded
                ? Theme.of(context).cardColor.withValues(alpha: 0.4)
                : isSelected
                    ? t.brandColor.withValues(alpha: 0.12)
                    : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(PingTheme.radiusMd),
            border: Border.all(
              color: alreadyAdded
                  ? PingTheme.hairlineBorder(context)
                  : isSelected ? t.brandColor : PingTheme.hairlineBorder(context),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: t.brandColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? t.brandColor : t.brandColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        t.logoText,
                        style: TextStyle(
                          color: isSelected ? Colors.white : t.brandColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(t.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: alreadyAdded
                            ? PingTheme.subtleText(context)
                            : isSelected ? t.brandColor : null,
                        decoration: alreadyAdded ? TextDecoration.lineThrough : null,
                      )),
                  const SizedBox(height: 2),
                  Text('€${t.defaultPrice}',
                      style: TextStyle(
                        fontSize: 10,
                        color: alreadyAdded
                            ? PingTheme.subtleText(context)
                            : isSelected ? t.brandColor : PingTheme.subtleText(context),
                      )),
                ],
              ),
              // Already added badge
              if (alreadyAdded)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: PingTheme.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                ),
              // Selected check
              if (isSelected && !alreadyAdded)
                Positioned(
                  top: 6, right: 6,
                  child: Icon(Icons.check_circle, size: 18, color: t.brandColor),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PingTheme.spaceXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: PingTheme.spaceSm),
                child: Text(
                  '${_selected.length} selected · €${_selectedTotal.toStringAsFixed(2)}/mo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: PingTheme.textBody,
                  ),
                ),
              ),
            Row(
              children: [
                // Manual add
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Manual'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: PingTheme.spaceMd),
                // Add selected
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _selected.isEmpty ? null : () async {
                      HapticFeedback.mediumImpact();
                      final provider = context.read<SubscriptionProvider>();
                      for (final id in _selected) {
                        final t = SubscriptionTemplates.all.where((x) => x.id == id).first;
                        provider.add(Subscription(
                          id: 'template_${DateTime.now().millisecondsSinceEpoch}_$id',
                          name: t.name,
                          amount: t.defaultPrice,
                          currency: t.currency,
                          billingCycle: t.billingCycle,
                          category: t.category,
                          nextBillingDate: DateTime.now().add(Duration(days: 30 + _selected.toList().indexOf(id))),
                          paymentMethod: 'Unknown',
                          isActive: true,
                          createdAt: DateTime.now(),
                        ));
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                      ),
                    ),
                    child: Text(
                      _selected.isEmpty ? 'Select above' : 'Add ${_selected.length} subscription${_selected.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double get _selectedTotal {
    return _selected.map((id) {
      final t = SubscriptionTemplates.all.where((x) => x.id == id).first;
      return t.defaultPrice;
    }).fold(0.0, (a, b) => a + b);
  }
}
