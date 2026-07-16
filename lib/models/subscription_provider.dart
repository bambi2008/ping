import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tink_service.dart';
import '../services/subscription_detector.dart';
import '../services/notification_service.dart';
import '../services/api_config.dart';
import 'subscription.dart';

class SubscriptionProvider extends ChangeNotifier {
  final TinkService _tink = TinkService();
  final SubscriptionDetector _detector = SubscriptionDetector();

  final List<Subscription> _subscriptions = [];
  String? _tinkUserId;
  bool _isLoading = false;
  bool _bankConnected = false;
  String? _errorMessage;
  String _displayCurrency = 'EUR';
  bool _isPremium = false;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  bool get bankConnected => _bankConnected;
  String? get errorMessage => _errorMessage;
  String get displayCurrency => _displayCurrency;
  bool get isPremium => _isPremium;

  double get totalMonthly => _subscriptions.where((s) => s.isActive).fold(0.0, (sum, s) => sum + s.convertedMonthlyAmount(_displayCurrency));
  double get totalYearly => totalMonthly * 12;
  int get activeCount => _subscriptions.where((s) => s.isActive).length;
  int get pausedCount => _subscriptions.where((s) => !s.isActive).length;

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final s in _subscriptions.where((s) => s.isActive)) {
      map[s.category] = (map[s.category] ?? 0) + s.convertedMonthlyAmount(_displayCurrency);
    }
    return map;
  }

  List<Subscription> get upcomingBills {
    final active = _subscriptions.where((s) => s.isActive).toList();
    active.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return active;
  }

  int get dueSoonCount => upcomingBills.where((s) => s.nextBillingDate.difference(DateTime.now()).inDays <= 3).length;

  static const paymentMethods = ['Apple Pay', 'PayPal', 'Credit Card', 'Debit Card', 'Bank Transfer', 'SEPA', 'iDEAL', 'Unknown'];
  static const categories = ['Entertainment', 'Music', 'Cloud', 'Software', 'Health', 'Shopping', 'Food', 'Other'];
  static const cycles = ['weekly', 'monthly', 'yearly'];

  // ── Init ──
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _displayCurrency = prefs.getString('currency') ?? 'EUR';
    _isPremium = prefs.getBool('premium') ?? false;
    if (ApiConfig.useMockData) _loadMockData();
  }

  Future<void> setCurrency(String code) async {
    _displayCurrency = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', code);
    notifyListeners();
  }

  // ── Bank Connection ──
  Future<String?> startBankConnection(String externalUserId) async {
    if (!ApiConfig.useRealApi) {
      _bankConnected = true;
      _loadMockTransactionsAndDetect();
      notifyListeners();
      return null;
    }
    try {
      _isLoading = true; _errorMessage = null; notifyListeners();
      _tinkUserId = await _tink.createUser(externalUserId: externalUserId);
      final authUrl = await _tink.getAuthorizationUrl(_tinkUserId!);
      _isLoading = false; notifyListeners();
      return authUrl;
    } catch (e) {
      _errorMessage = 'Failed to connect: $e';
      _isLoading = false; notifyListeners();
      return null;
    }
  }

  Future<void> onBankAuthCallback(String code) async {
    if (!ApiConfig.useRealApi) return;
    try {
      _isLoading = true; notifyListeners();
      await _tink.exchangeCode(code);
      _bankConnected = true;
      await _loadRealTransactions();
    } catch (e) {
      _errorMessage = 'Bank auth failed: $e';
    }
    _isLoading = false; notifyListeners();
  }

  Future<void> _loadRealTransactions() async {
    if (_tinkUserId == null) return;
    final txs = await _tink.fetchTransactions(userId: _tinkUserId!);
    final (confirmed, possible) = _detector.detect(txs);
    _subscriptions.clear();
    _subscriptions.addAll([...confirmed, ...possible].map(_enrichSubscription));
    scheduleAllNotifications();
  }

  void _loadMockTransactionsAndDetect() {
    final txs = _generateMockTransactions();
    final (confirmed, possible) = _detector.detect(txs);
    _subscriptions.clear();
    _subscriptions.addAll([...confirmed, ...possible].map(_enrichSubscription));
    scheduleAllNotifications();
  }

  void _loadMockData() {
    _subscriptions.clear();
    _subscriptions.addAll([
      _enrichSubscription(Subscription(id: 'm1', name: 'Netflix', logoUrl: 'netflix', amount: 13.99, billingCycle: 'monthly', nextBillingDate: DateTime.now().add(const Duration(days: 12)), category: 'Entertainment', source: 'bank', paymentMethod: 'Credit Card')),
      _enrichSubscription(Subscription(id: 'm2', name: 'Spotify', logoUrl: 'spotify', amount: 10.99, billingCycle: 'monthly', nextBillingDate: DateTime.now().add(const Duration(days: 5)), category: 'Music', source: 'bank', paymentMethod: 'PayPal')),
      _enrichSubscription(Subscription(id: 'm3', name: 'Disney+', logoUrl: 'disney', amount: 89.90, billingCycle: 'yearly', nextBillingDate: DateTime.now().add(const Duration(days: 89)), category: 'Entertainment', source: 'bank', paymentMethod: 'Credit Card')),
      _enrichSubscription(Subscription(id: 'm4', name: 'iCloud+', logoUrl: 'icloud', amount: 2.99, billingCycle: 'monthly', nextBillingDate: DateTime.now().add(const Duration(days: 3)), category: 'Cloud', source: 'bank', paymentMethod: 'Apple Pay')),
      _enrichSubscription(Subscription(id: 'm5', name: 'Adobe CC', logoUrl: 'adobe', amount: 62.99, billingCycle: 'monthly', nextBillingDate: DateTime.now().add(const Duration(days: 18)), category: 'Software', isActive: false, source: 'bank', paymentMethod: 'Credit Card')),
      _enrichSubscription(Subscription(id: 'm6', name: 'Gym', logoUrl: 'gym', amount: 29.99, billingCycle: 'monthly', nextBillingDate: DateTime.now().add(const Duration(days: 1)), category: 'Health', source: 'bank', paymentMethod: 'SEPA')),
      _enrichSubscription(Subscription(id: 'm7', name: 'Amazon Prime', logoUrl: 'amazon', amount: 8.99, billingCycle: 'monthly', nextBillingDate: DateTime.now().add(const Duration(days: 22)), category: 'Shopping', source: 'bank', paymentMethod: 'Credit Card')),
      _enrichSubscription(Subscription(id: 'm8', name: 'YouTube Premium', logoUrl: 'youtube', amount: 12.99, billingCycle: 'monthly', nextBillingDate: DateTime.now().add(const Duration(days: 15)), category: 'Entertainment', source: 'bank', paymentMethod: 'PayPal')),
    ]);
    _bankConnected = true;
    _isLoading = false;
    notifyListeners();
  }

  Subscription _enrichSubscription(Subscription s) {
    final theme = SubscriptionTheme.match(s.name);
    return Subscription(
      id: s.id, name: s.name, logoUrl: s.logoUrl, amount: s.amount,
      currency: s.currency, billingCycle: s.billingCycle,
      nextBillingDate: s.nextBillingDate, category: s.category,
      isActive: s.isActive, paymentMethod: s.paymentMethod,
      pausedUntil: s.pausedUntil, source: s.source,
      themeColor: theme?.color,
    );
  }

  // ── Notifications ──
  void scheduleAllNotifications() {
    for (final sub in _subscriptions.where((s) => s.isActive)) {
      NotificationService.scheduleBillReminder(sub);
    }
  }

  // ── CRUD ──
  void addManual(Subscription sub) {
    _subscriptions.add(_enrichSubscription(sub));
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

  void updateSubscription(String id, {String? name, String? category, String? paymentMethod, String? currency}) {
    final sub = _subscriptions.firstWhere((s) => s.id == id);
    if (name != null) { sub.name = name; final t = SubscriptionTheme.match(name); if (t != null) sub.themeColor = t.color; }
    if (category != null) sub.category = category;
    if (paymentMethod != null) sub.paymentMethod = paymentMethod;
    if (currency != null) sub.currency = currency;
    notifyListeners();
  }

  void removeSubscription(String id) {
    _subscriptions.removeWhere((s) => s.id == id);
    NotificationService.cancelForSubscription(id);
    notifyListeners();
  }

  // ── Premium ──
  Future<void> unlockPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('premium', true);
    notifyListeners();
  }

  // ── Mock transactions ──
  List<Map<String, dynamic>> _generateMockTransactions() {
    final now = DateTime.now();
    final txs = <Map<String, dynamic>>[];
    void add(String desc, double amt, int months, int day) {
      for (int i = months; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, day.clamp(1, 28));
        if (d.isAfter(now)) continue;
        txs.add({'description': desc, 'amount': amt, 'date': d.toIso8601String(), 'currency': 'EUR'});
      }
    }
    add('Netflix.com', 13.99, 6, 15);
    add('Spotify', 10.99, 6, 8);
    add('Disney+', 89.90, 12, 20);
    add('Apple.com/bill iCloud', 2.99, 5, 1);
    add('Adobe Systems', 62.99, 8, 12);
    add('McFit Gym', 29.99, 10, 25);
    add('Amazon Prime', 8.99, 7, 3);
    add('YouTube Premium', 12.99, 6, 10);
    txs.addAll(List.generate(20, (i) => {
      'description': ['ALDI', 'REWE', 'Shell', 'Starbucks', 'Uber', 'Bolt Food'][i % 6],
      'amount': [45.23, 33.50, 62.00, 5.40, 12.80, 18.90][i % 6],
      'date': now.subtract(Duration(days: i * 3 + 1)).toIso8601String(),
      'currency': 'EUR',
    }));
    return txs;
  }

  @override
  void dispose() { _tink.dispose(); super.dispose(); }
}
