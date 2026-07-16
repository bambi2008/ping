import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/subscription_provider.dart';

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _billingCycle = 'monthly';
  String _category = 'Entertainment';
  DateTime _nextBilling = DateTime.now().add(const Duration(days: 30));

  static const _categories = ['Entertainment', 'Music', 'Cloud', 'Software', 'Health', 'Shopping', 'Food', 'Other'];
  static const _cycles = ['weekly', 'monthly', 'yearly'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Subscription')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Service name',
                hintText: 'e.g. Netflix, Spotify, Gym...',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.loyalty),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '13.99',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.euro),
                suffixText: '€',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Billing cycle
            DropdownButtonFormField<String>(
              value: _billingCycle,
              decoration: const InputDecoration(
                labelText: 'Billing cycle',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: _cycles.map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
              onChanged: (v) => setState(() => _billingCycle = v!),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            // Next billing date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: PingTheme.primary),
              title: const Text('Next billing date'),
              subtitle: Text('${_nextBilling.day}/${_nextBilling.month}/${_nextBilling.year}'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Theme.of(context).cardColor,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextBilling,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (picked != null) setState(() => _nextBilling = picked);
              },
            ),
            const SizedBox(height: 32),

            // Submit button
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Add Subscription'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final sub = Subscription(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      logoUrl: _nameCtrl.text.trim().toLowerCase(),
      amount: double.parse(_amountCtrl.text.trim()),
      billingCycle: _billingCycle,
      nextBillingDate: _nextBilling,
      category: _category,
      source: 'manual',
    );

    context.read<SubscriptionProvider>().addManual(sub);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${sub.name} added'), behavior: SnackBarBehavior.floating),
    );
    Navigator.pop(context);
  }
}
