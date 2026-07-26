import 'package:flutter/material.dart';
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
        child: ListView(padding: const EdgeInsets.all(20), children: [
          // Service name with autocomplete
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Service name',
                hintText: 'e.g. Netflix, Spotify, Gym...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
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
                        borderRadius: BorderRadius.circular(8),
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
                const SizedBox(width: 8),
                Text('Matched theme',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
            ),
          const SizedBox(height: 16),

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
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      prefixIcon: Icon(Icons.euro)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      (v == null || double.tryParse(v.trim()) == null)
                          ? 'Invalid'
                          : null,
                )),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)))),
                  items: CurrencyProvider.popular
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${CurrencyProvider.getSymbol(c)} $c',
                              style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                )),
          ]),
          const SizedBox(height: 16),

          // Billing cycle
          DropdownButtonFormField<String>(
            initialValue: _billingCycle,
            decoration: const InputDecoration(
                labelText: 'Billing cycle',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.repeat)),
            items: SubscriptionProvider.cycles
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(c[0].toUpperCase() + c.substring(1))))
                .toList(),
            onChanged: (v) => setState(() => _billingCycle = v!),
          ),
          const SizedBox(height: 16),

          // Category
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.category)),
            items: SubscriptionProvider.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),

          // Payment method
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            decoration: const InputDecoration(
                labelText: 'Payment method',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.credit_card)),
            items: SubscriptionProvider.paymentMethods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          const SizedBox(height: 16),

          // Date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: PingTheme.primary),
            title: const Text('Next billing date'),
            subtitle: Text(
                '${_nextBilling.day}/${_nextBilling.month}/${_nextBilling.year}'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          const SizedBox(height: 32),

          FilledButton.icon(
              onPressed: _submit,
              icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
              label: Text(_isEditing ? 'Save Changes' : 'Add Subscription'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)))),
        ]),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${sub.name} added'),
        behavior: SnackBarBehavior.floating));
    Navigator.pop(context);
  }
}
