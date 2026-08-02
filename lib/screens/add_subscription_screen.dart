import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final Subscription? subscription;
  const AddSubscriptionScreen({super.key, this.subscription});
  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _billingCycle = 'monthly';
  String _category = 'Entertainment';
  String _currency = 'EUR';
  String _paymentMethod = 'Unknown';
  DateTime _nextBilling = DateTime.now().add(const Duration(days: 30));

  bool get _isEditing => widget.subscription != null;

  @override
  void initState() {
    super.initState();
    final subscription = widget.subscription;
    if (subscription != null) {
      _nameCtrl.text = subscription.name;
      _amountCtrl.text = subscription.amount.toStringAsFixed(2);
      _billingCycle = subscription.billingCycle;
      _category = subscription.category;
      _currency = subscription.currency;
      _paymentMethod = subscription.paymentMethod;
      _nextBilling = subscription.nextBillingDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Subscription' : 'Add Subscription'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(PingTheme.spaceXl), children: [
          // Service name with autocomplete
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Service name',
                hintText: 'e.g. Netflix, Spotify, Gym...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(PingTheme.radiusMd))),
                prefixIcon: Icon(Icons.loyalty)),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) {
              final theme = SubscriptionTheme.match(v);
              if (theme != null) setState(() {});
            },
          ),
          // Show matched theme if found
          if (SubscriptionTheme.match(_nameCtrl.text) != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                        color: SubscriptionTheme.match(_nameCtrl.text)!
                            .color
                            .withValues(alpha: 0.2)),
                    child: Center(
                        child: Text(
                            _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : '?',
                            style: TextStyle(
                                color: SubscriptionTheme.match(_nameCtrl.text)!
                                    .color,
                                fontWeight: FontWeight.w700)))),
                const SizedBox(width: PingTheme.spaceSm),
                Text('Matched theme',
                    style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textSmall)),
              ]),
            ),
          const SizedBox(height: PingTheme.spaceLg),

          // Amount + Currency row
          Row(children: [
            Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '13.99',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(PingTheme.radiusMd))),
                      prefixIcon: Icon(Icons.euro)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      (v == null || double.tryParse(v.trim()) == null)
                          ? 'Invalid'
                          : null,
                )),
            const SizedBox(width: PingTheme.spaceMd),
            Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(PingTheme.radiusMd)))),
                  items: CurrencyProvider.popular
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${CurrencyProvider.getSymbol(c)} $c',
                              style: const TextStyle(fontSize: PingTheme.textSmall))))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                )),
          ]),
          const SizedBox(height: PingTheme.spaceLg),

          // Billing cycle
          DropdownButtonFormField<String>(
            initialValue: _billingCycle,
            decoration: const InputDecoration(
                labelText: 'Billing cycle',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(PingTheme.radiusMd))),
                prefixIcon: Icon(Icons.repeat)),
            items: SubscriptionProvider.cycles
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(c[0].toUpperCase() + c.substring(1))))
                .toList(),
            onChanged: (v) => setState(() => _billingCycle = v!),
          ),
          const SizedBox(height: PingTheme.spaceLg),

          // Category
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(PingTheme.radiusMd))),
                prefixIcon: Icon(Icons.category)),
            items: [
              ...SubscriptionProvider.categories.map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))),
              if (!SubscriptionProvider.categories.contains(_category))
                DropdownMenuItem(value: _category, child: Text(_category)),
              const DropdownMenuItem(
                value: '__custom__',
                child: Row(children: [
                  Icon(Icons.add_circle_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Add custom...'),
                ]),
              ),
            ],
            onChanged: (v) async {
              if (v == '__custom__') {
                final custom = await _showCustomCategoryDialog(context);
                if (custom != null && custom.isNotEmpty) {
                  setState(() => _category = custom);
                }
              } else {
                setState(() => _category = v!);
              }
            },
          ),
          const SizedBox(height: PingTheme.spaceLg),

          // Payment method
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            decoration: const InputDecoration(
                labelText: 'Payment method',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(PingTheme.radiusMd))),
                prefixIcon: Icon(Icons.credit_card)),
            items: SubscriptionProvider.paymentMethods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          const SizedBox(height: PingTheme.spaceLg),

          // Date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: PingTheme.primary),
            title: const Text('Next billing date'),
            subtitle: Text(
                '${_nextBilling.day}/${_nextBilling.month}/${_nextBilling.year}'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(PingTheme.radiusMd)),
            tileColor: Theme.of(context).cardColor,
            onTap: () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextBilling,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)));
              if (picked != null) setState(() => _nextBilling = picked);
            },
          ),
          const SizedBox(height: PingTheme.space3Xl),

          FilledButton.icon(
              onPressed: _submit,
              icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
              label: Text(_isEditing ? 'Save Changes' : 'Add Subscription'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd)))),
        ]),
      ),
    );
  }

  Future<String?> _showCustomCategoryDialog(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Education, Fitness...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final theme = SubscriptionTheme.match(_nameCtrl.text.trim());
    final provider = context.read<SubscriptionProvider>();
    if (_isEditing) {
      await provider.updateSubscription(
        widget.subscription!.id,
        name: _nameCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        currency: _currency,
        billingCycle: _billingCycle,
        nextBillingDate: _nextBilling,
        category: _category,
        paymentMethod: _paymentMethod,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    final sub = Subscription(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      logoUrl: _nameCtrl.text.trim().toLowerCase(),
      amount: double.parse(_amountCtrl.text.trim()),
      currency: _currency,
      billingCycle: _billingCycle,
      nextBillingDate: _nextBilling,
      category: _category,
      paymentMethod: _paymentMethod,
      source: 'manual',
      themeColor: theme?.color,
    );
    await provider.addManual(sub);
    if (!mounted) return;
    // Haptic + animated success feedback
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: PingTheme.success, size: 20),
          const SizedBox(width: PingTheme.spaceSm),
          Text('${sub.name} added'),
        ]),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
    ));
    Navigator.pop(context);
  }
}
