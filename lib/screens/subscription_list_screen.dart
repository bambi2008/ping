import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../widgets/brand_icon.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_transitions.dart';
import '../widgets/press_scale.dart';
import '../widgets/cancel_celebration.dart';
import 'subscription_detail_screen.dart';
import 'add_subscription_screen.dart';

class SubscriptionListScreen extends StatefulWidget {
  const SubscriptionListScreen({super.key});
  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SubscriptionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Subscriptions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PingTheme.spaceMd, 0, PingTheme.spaceMd, PingTheme.spaceSm),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search subscriptions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(slivers: [
        // ── Sort & Filter bar ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PingTheme.spaceLg, PingTheme.spaceSm, PingTheme.spaceLg, PingTheme.spaceSm),
            child: Row(children: [
              // Sort button
              _sortButton(context, p),
              const SizedBox(width: PingTheme.spaceSm),
              // Filter chip
              _filterChip(context, p),
            ]),
          ),
        ),

        // ── List ──
        ..._buildBody(context, p),
      ]),
    );
  }

  List<Widget> _buildBody(BuildContext context, SubscriptionProvider p) {
    if (p.subscriptions.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.subscriptions_outlined, size: 64, color: PingTheme.primary),
              const SizedBox(height: PingTheme.spaceLg),
              Text('No subscriptions',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: PingTheme.spaceLg),
              PressScale(
                onTap: () async => await Navigator.push(context,
                    SlideFadeRoute(page: const AddSubscriptionScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: PingTheme.space2Xl, vertical: PingTheme.spaceMd),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [PingTheme.primary, PingTheme.primaryLight]),
                    borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                    boxShadow: [BoxShadow(color: PingTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Add Your First', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: PingTheme.textBody)),
                  ]),
                ),
              ),
            ]),
          ),
        )
      ];
    }

    final filtered = _query.isEmpty
        ? p.sortedSubscriptions
        : p.sortedSubscriptions
            .where((s) =>
                s.name.toLowerCase().contains(_query) ||
                s.category.toLowerCase().contains(_query))
            .toList();
    final active = filtered.where((s) => s.isActive).toList();
    final inactive = filtered.where((s) => !s.isActive).toList();

    if (filtered.isEmpty && _query.isNotEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.search_off, size: 56, color: PingTheme.subtleText(context)),
              const SizedBox(height: PingTheme.spaceMd),
              Text('No results for "$_query"',
                  style: TextStyle(
                      color: PingTheme.subtleText(context),
                      fontSize: PingTheme.textBody)),
            ]),
          ),
        )
      ];
    }

    return [
      if (active.isNotEmpty) ...[
        _sectionHeader(context, 'Active', active.length),
        SliverList.builder(
          itemCount: active.length,
          itemBuilder: (context, i) => _tile(context, active[i]),
        ),
      ],
      if (inactive.isNotEmpty) ...[
        _sectionHeader(context, 'Inactive', inactive.length,
            topPadding: PingTheme.space2Xl),
        SliverList.builder(
          itemCount: inactive.length,
          itemBuilder: (context, i) => _tile(context, inactive[i]),
        ),
      ],
    ];
  }

  // ── Sort Button ──
  Widget _sortButton(BuildContext context, SubscriptionProvider p) {
    return InkWell(
      onTap: () => _showSortMenu(context, p),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd, vertical: 7),
        decoration: BoxDecoration(
          color: PingTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(p.sortOption.icon, size: 16, color: PingTheme.primary),
          const SizedBox(width: 5),
          Text(p.sortOption.label,
              style: const TextStyle(
                fontSize: PingTheme.textSmall,
                fontWeight: FontWeight.w600,
                color: PingTheme.primary,
              )),
          const Icon(Icons.expand_more, size: 16, color: PingTheme.primary),
        ]),
      ),
    );
  }

  void _showSortMenu(BuildContext context, SubscriptionProvider p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PingTheme.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(PingTheme.spaceXl),
            child: Text('Sort by',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ...SortOption.values.map((opt) => RadioListTile<SortOption>(
                value: opt,
                groupValue: p.sortOption,
                activeColor: PingTheme.primary,
                title: Text(opt.label),
                onChanged: (v) {
                  if (v != null) p.setSortOption(v);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: PingTheme.spaceSm),
        ]),
      ),
    );
  }

  // ── Filter Chip ──
  Widget _filterChip(BuildContext context, SubscriptionProvider p) {
    if (p.availableCategories.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _showFilterMenu(context, p),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd, vertical: 7),
        decoration: BoxDecoration(
          color: p.filterCategory != null
              ? PingTheme.secondary.withValues(alpha: 0.12)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: p.filterCategory != null
                ? PingTheme.secondary.withValues(alpha: 0.3)
                : PingTheme.hairlineBorder(context),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.filter_list, size: 16,
              color: p.filterCategory != null
                  ? PingTheme.secondary
                  : PingTheme.subtleText(context)),
          const SizedBox(width: 5),
          Text(p.filterCategory ?? 'Filter',
              style: TextStyle(
                fontSize: PingTheme.textSmall,
                fontWeight: FontWeight.w600,
                color: p.filterCategory != null
                    ? PingTheme.secondary
                    : PingTheme.subtleText(context),
              )),
          if (p.filterCategory != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => p.setFilterCategory(null),
              child: Icon(Icons.close, size: 14,
                  color: PingTheme.secondary.withValues(alpha: 0.6)),
            ),
          ],
        ]),
      ),
    );
  }

  void _showFilterMenu(BuildContext context, SubscriptionProvider p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PingTheme.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(PingTheme.spaceXl),
            child: Text('Filter by category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          RadioListTile<String?>(
            value: null,
            groupValue: p.filterCategory,
            activeColor: PingTheme.primary,
            title: const Text('All categories'),
            onChanged: (v) {
              p.setFilterCategory(null);
              Navigator.pop(ctx);
            },
          ),
          ...p.availableCategories.map((cat) => RadioListTile<String?>(
                value: cat,
                groupValue: p.filterCategory,
                activeColor: PingTheme.primary,
                title: Text(cat),
                onChanged: (v) {
                  p.setFilterCategory(v);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: PingTheme.spaceSm),
        ]),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label, int count,
      {double topPadding = PingTheme.spaceLg}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            PingTheme.spaceLg, topPadding, PingTheme.spaceLg, PingTheme.spaceSm),
        child: Text('$label ($count)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: PingTheme.subtleText(context),
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Tile with swipe-to-reveal actions ──
  Widget _tile(BuildContext context, Subscription s) {
    final themeColor = s.themeColor ??
        SubscriptionTheme.categoryColors[s.category] ??
        PingTheme.primary;

    final actions = <SwipeAction>[
      if (s.isActive)
        SwipeAction(
          icon: Icons.pause_circle_outline,
          label: 'Pause',
          color: PingTheme.warning,
          onTap: () {
            HapticFeedback.mediumImpact();
            context.read<SubscriptionProvider>().setStatus(s.id, SubscriptionStatus.paused);
          },
        ),
      SwipeAction(
        icon: Icons.edit_outlined,
        label: 'Edit',
        color: PingTheme.primary,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(context,
              SlideFadeRoute(page: AddSubscriptionScreen(subscription: s)));
        },
      ),
      SwipeAction(
        icon: Icons.delete_outline,
        label: 'Delete',
        color: PingTheme.danger,
        onTap: () async {
          HapticFeedback.heavyImpact();
          final confirmed = await _confirmDelete(context, s.name);
          if (confirmed && context.mounted) {
            await context.read<SubscriptionProvider>().removeSubscription(s.id);
          }
        },
      ),
    ];

    return RepaintBoundary(
      child: ElasticAppear(
        delay: Duration(milliseconds: (i * 60).clamp(0, 300)),
        child: SwipeToReveal(
          actions: actions,
          revealWidth: 72,
        child: PressScale(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(context,
                SlideFadeRoute(page: SubscriptionDetailScreen(id: s.id)));
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(
                PingTheme.spaceLg, 0, PingTheme.spaceLg, PingTheme.spaceSm),
            padding: const EdgeInsets.symmetric(
                horizontal: PingTheme.spaceMd, vertical: PingTheme.spaceSm + 2),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                border: Border.all(color: PingTheme.hairlineBorder(context))),
            child: Row(
              children: [
                Hero(
                  tag: 'brand_${s.id}',
                  child: BrandIcon(name: s.name, fallbackColor: themeColor, size: 42),
                ),
                const SizedBox(width: PingTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s.name,
                              style: TextStyle(
                                  fontSize: PingTheme.textBody,
                                  fontWeight: FontWeight.w600,
                                  decoration: s.isActive
                                      ? null
                                      : TextDecoration.lineThrough)),
                          if (s.source == 'manual') ...[
                            const SizedBox(width: 6),
                            Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                    color: PingTheme.primary.withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(PingTheme.radiusXs)),
                                child: const Text('manual',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: PingTheme.primary,
                                        fontWeight: FontWeight.w600))),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                          '${s.currencySymbol}${s.amount.toStringAsFixed(2)} · ${s.billingCycle} · ${s.paymentMethod}',
                          style: TextStyle(
                              fontSize: PingTheme.textCaption,
                              color: PingTheme.subtleText(context))),
                    ],
                  ),
                ),
                Icon(
                  s.isActive ? Icons.check_circle : Icons.pause_circle,
                  color: s.isActive
                      ? PingTheme.success
                      : PingTheme.subtleText(context),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

    Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subscription?'),
        content: Text('Remove "$name" from Ping? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          PressScale(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [PingTheme.danger, PingTheme.danger.withValues(alpha: 0.85)]),
                borderRadius: BorderRadius.circular(PingTheme.radiusSm),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}
