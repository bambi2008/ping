import 'package:flutter/foundation.dart';
import '../services/tink_service.dart';
import '../services/subscription_detector.dart';
import '../services/notification_service.dart';
import '../services/api_config.dart';

class Subscription {
  final String id;
  final String name;
  final String logoUrl;
  final double amount;
  final String currency;
  final String billingCycle;
  final DateTime nextBillingDate;
  final String category;
  bool isActive;
  final DateTime? pausedUntil;
  final String? source; // 'bank' or 'manual'

  Subscription({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.amount,
    this.currency = '€',
    required this.billingCycle,
    required this.nextBillingDate,
    this.category = 'Other',
    this.isActive = true,
    this.pausedUntil,
    this.source,
  });

  double get monthlyAmount {
    switch (billingCycle) {
      case 'yearly': return amount / 12;
      case 'weekly': return amount * 4.33;
      default: return amount;
    }
  }
}

class SubscriptionProvider extends ChangeNotifier {
  final TinkService _tink = TinkService();
  final SubscriptionDetector _detector = SubscriptionDetector();

  final List<Subscription> _subscriptions = [];
  String? _tinkUserId;
  bool _isLoading = false;
  bool _bankConnected = false;
  String? _errorMessage;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  bool get bankConnected => _bankConnected;
  String? get errorMessage => _errorMessage;

  double get totalMonthly =>
      _subscriptions.where((s) => s.isActive).fold(0.0, (sum, s) => sum + s.monthlyAmount);
  double get totalYearly => totalMonthly * 12;
  int get activeCount => _subscriptions.where((s) => s.isActive).length;
  int get pausedCount => _subscriptions.where((s) => !s.isActive).length;

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final s in _subscriptions.where((s) => s.isActive)) {
      map[s.category] = (map[s.category] ?? 0) + s.monthlyAmount;
    }
    return map;
  }

  List<Subscription> get upcomingBills {
    final active = _subscriptions.where((s) => s.isActive).toList();
    active.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return active;
  }

  // ── Initialization ──
  void init() {
    if (ApiConfig.useMockData) {
      _loadMockData();
    }
  }

  // ── Bank Connection Flow ──
  Future<String?> startBankConnection(String externalUserId) async {
    if (!ApiConfig.useRealApi) {
      _bankConnected = true;
      _loadMockTransactionsAndDetect();
      notifyListeners();
      return null;
    }
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _tinkUserId = await _tink.createUser(externalUserId: externalUserId);
      final authUrl = await _tink.getAuthorizationUrl(_tinkUserId!);
      _isLoading = false;
      notifyListeners();
      return authUrl; // Open in browser for user to select bank
    } catch (e) {
      _errorMessage = 'Failed to connect: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> onBankAuthCallback(String code) async {
    if (!ApiConfig.useRealApi) return;
    try {
      _isLoading = true;
      notifyListeners();
      await _tink.exchangeCode(code);
      _bankConnected = true;
      await _loadRealTransactions();
    } catch (e) {
      _errorMessage = 'Bank auth failed: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Transaction Loading & Detection ──
  Future<void> _loadRealTransactions() async {
    if (_tinkUserId == null) return;
    final txs = await _tink.fetchTransactions(userId: _tinkUserId!);
    final (confirmed, possible) = _detector.detect(txs);
    _subscriptions.clear();
    _subscriptions.addAll(confirmed);
    _subscriptions.addAll(possible);
    scheduleAllNotifications();
  }

  void _loadMockTransactionsAndDetect() {
    final mockTxs = _generateMockTransactions();
    final (confirmed, possible) = _detector.detect(mockTxs);
    _subscriptions.clear();
    _subscriptions.addAll(confirmed);
    _subscriptions.addAll(possible);
    scheduleAllNotifications();
  }

  void _loadMockData() {
    _subscriptions.clear();
    _subscriptions.addAll([
      Subscription(id: 'm1', name: 'Netflix', logoUrl: 'netflix', amount: 13.99, billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 12)), category: 'Entertainment', source: 'bank'),
      Subscription(id: 'm2', name: 'Spotify', logoUrl: 'spotify', amount: 10.99, billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 5)), category: 'Music', source: 'bank'),
      Subscription(id: 'm3', name: 'Disney+', logoUrl: 'disney', amount: 89.90, billingCycle: 'yearly',
        nextBillingDate: DateTime.now().add(const Duration(days: 89)), category: 'Entertainment', source: 'bank'),
      Subscription(id: 'm4', name: 'iCloud+', logoUrl: 'icloud', amount: 2.99, billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 3)), category: 'Cloud', source: 'bank'),
      Subscription(id: 'm5', name: 'Adobe CC', logoUrl: 'adobe', amount: 62.99, billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 18)), category: 'Software', isActive: false, source: 'bank'),
      Subscription(id: 'm6', name: 'Gym', logoUrl: 'gym', amount: 29.99, billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 1)), category: 'Health', source: 'bank'),
      Subscription(id: 'm7', name: 'Amazon Prime', logoUrl: 'amazon', amount: 8.99, billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 22)), category: 'Shopping', source: 'bank'),
      Subscription(id: 'm8', name: 'YouTube Premium', logoUrl: 'youtube', amount: 12.99, billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 15)), category: 'Entertainment', source: 'bank'),
    ]);
    _bankConnected = true;
    _isLoading = false;
    notifyListeners();
  }

  // ── Notifications ──
  void scheduleAllNotifications() {
    for (final sub in _subscriptions.where((s) => s.isActive)) {
      NotificationService.scheduleBillReminder(sub);
    }
  }

  // ── Manual subscription management ──
  void addManual(Subscription sub) {
    _subscriptions.add(sub);
    NotificationService.scheduleBillReminder(sub);
    notifyListeners();
  }

  void toggleSubscription(String id) {
    final sub = _subscriptions.firstWhere((s) => s.id == id);
    sub.isActive = !sub.isActive;
    if (!sub.isActive) {
      NotificationService.cancelForSubscription(id);
    } else {
      NotificationService.scheduleBillReminder(sub);
    }
    notifyListeners();
  }

  void removeSubscription(String id) {
    _subscriptions.removeWhere((s) => s.id == id);
    NotificationService.cancelForSubscription(id);
    notifyListeners();
  }

  // ── Mock transaction generator (for demo without real bank) ──
  List<Map<String, dynamic>> _generateMockTransactions() {
    final now = DateTime.now();
    final txs = <Map<String, dynamic>>[];
    
    void addRecurring(String desc, double amount, int monthsBack, int dayOfMonth) {
      for (int i = monthsBack; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, dayOfMonth.clamp(1, 28));
        if (date.isAfter(now)) continue;
        txs.add({'description': desc, 'amount': amount, 'date': date.toIso8601String(), 'currency': '€'});
      }
    }

    addRecurring('Netflix.com', 13.99, 6, 15);
    addRecurring('Spotify', 10.99, 6, 8);
    addRecurring('Disney+', 89.90, 12, 20); // yearly — one charge per year
    addRecurring('Apple.com/bill iCloud', 2.99, 5, 1);
    addRecurring('Adobe Systems', 62.99, 8, 12);
    addRecurring('McFit Gym', 29.99, 10, 25);
    addRecurring('Amazon Prime', 8.99, 7, 3);
    addRecurring('YouTube Premium', 12.99, 6, 10);

    // Some non-subscription noise
    txs.addAll(List.generate(20, (i) => {
      'description': ['ALDI Einkauf', 'REWE', 'Shell Tankstelle', 'Starbucks', 'Uber Ride', 'Bolt Food'][i % 6],
      'amount': [45.23, 33.50, 62.00, 5.40, 12.80, 18.90][i % 6],
      'date': now.subtract(Duration(days: i * 3 + 1)).toIso8601String(),
      'currency': '€',
    }));

    return txs;
  }

  @override
  void dispose() {
    _tink.dispose();
    super.dispose();
  }
}
