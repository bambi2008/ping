import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/subscription.dart';
import '../models/subscription_provider.dart';
import '../services/subscription_templates.dart';

/// 邮件扫描界面 — 连接 Gmail，扫描订阅收据，自动发现订阅
/// 流程: 授权 → 扫描动画 → 结果列表 → 一键添加
class EmailScanScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool isFromOnboarding;

  const EmailScanScreen({
    super.key,
    this.onComplete,
    this.isFromOnboarding = false,
  });

  @override
  State<EmailScanScreen> createState() => _EmailScanScreenState();
}

class _EmailScanScreenState extends State<EmailScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  _ScanPhase _phase = _ScanPhase.idle;
  List<DetectedSub> _detected = [];
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    HapticFeedback.mediumImpact();
    setState(() => _phase = _ScanPhase.scanning);
    _scanCtrl.repeat();

    // 调用后端扫描 API
    // 这里先模拟，真实环境会通过 Gmail connector 获取邮件后传给后端
    await Future.delayed(const Duration(seconds: 2));

    // 模拟扫描结果（真实环境调用 scanSubscriptionEmails backend function）
    _detected = _mockDetectedSubs();

    _scanCtrl.stop();
    setState(() => _phase = _ScanPhase.results);
    HapticFeedback.heavyImpact();
  }

  void _addSelected() {
    HapticFeedback.mediumImpact();
    final provider = context.read<SubscriptionProvider>();
    final existingNames = provider.subscriptions.map((s) => s.name.toLowerCase()).toSet();

    for (final idx in _selected) {
      final sub = _detected[idx];
      if (existingNames.contains(sub.name.toLowerCase())) continue;

      provider.add(Subscription(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}_${sub.name}',
        name: sub.name,
        amount: sub.amount,
        currency: sub.currency,
        billingCycle: sub.billingCycle,
        category: sub.category,
        nextBillingDate: sub.nextBillingDate ?? DateTime.now().add(const Duration(days: 30)),
        paymentMethod: 'Email scan',
        isActive: true,
        createdAt: DateTime.now(),
      ));
    }

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航
            _buildTopBar(context),
            // 主内容
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PingTheme.spaceLg),
      child: Row(
        children: [
          if (!widget.isFromOnboarding)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          const Spacer(),
          Text(
            _phase == _ScanPhase.results ? 'Found ${_detected.length} subscriptions' : 'Email Scan',
            style: TextStyle(
              fontSize: PingTheme.textTitle,
              fontWeight: FontWeight.w700,
              color: PingTheme.subtleText(context),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_phase) {
      case _ScanPhase.idle:
        return _buildIdleView(context);
      case _ScanPhase.scanning:
        return _buildScanningView(context);
      case _ScanPhase.results:
        return _buildResultsView(context);
    }
  }

  // ── 待扫描 ──
  Widget _buildIdleView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PingTheme.space2Xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [PingTheme.primary, PingTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: PingTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.mail_outline_rounded, size: 52, color: Colors.white),
          ),
          const SizedBox(height: PingTheme.space3Xl),

          Text(
            'Auto-detect your subscriptions',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PingTheme.spaceMd),
          Text(
            'Connect your email and Ping will scan\nyour receipts to find subscriptions you\nforgot about.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PingTheme.subtleText(context),
              fontSize: PingTheme.textBody,
              height: 1.5,
            ),
          ),
          const SizedBox(height: PingTheme.space3Xl),

          // Gmail 按钮
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _startScan,
              icon: Image.network(
                'https://logo.clearbit.com/google.com',
                width: 22, height: 22,
                errorBuilder: (_, __, ___) => const Icon(Icons.mail, size: 22),
              ),
              label: const Text('Connect Gmail'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3C4043),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                  side: const BorderSide(color: Color(0xFFDADCE0)),
                ),
              ),
            ),
          ),
          const SizedBox(height: PingTheme.spaceMd),

          // 其他邮箱
          OutlinedButton(
            onPressed: _startScan,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PingTheme.radiusMd),
              ),
            ),
            child: const Text('Use another email'),
          ),

          const SizedBox(height: PingTheme.space2Xl),
          // 隐私
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: PingTheme.subtleText(context)),
              const SizedBox(width: 4),
              Text('We only scan receipts — never read your emails',
                style: TextStyle(
                  fontSize: PingTheme.textCaption,
                  color: PingTheme.subtleText(context),
                )),
            ],
          ),
        ],
      ),
    );
  }

  // ── 扫描中 ──
  Widget _buildScanningView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // 扫描动画 — 雷达
        AnimatedBuilder(
          animation: _scanCtrl,
          builder: (context, child) {
            return SizedBox(
              width: 200, height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 雷达圆环
                  for (int i = 0; i < 3; i++)
                    Transform.scale(
                      scale: 0.3 + ((_scanCtrl.value + i * 0.33) % 1.0) * 0.7,
                      child: Opacity(
                        opacity: 1 - ((_scanCtrl.value + i * 0.33) % 1.0),
                        child: Container(
                          width: 200, height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: PingTheme.primary.withValues(alpha: 0.5), width: 2),
                          ),
                        ),
                      ),
                    ),
                  // 中心图标
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PingTheme.primary,
                      boxShadow: [
                        BoxShadow(color: PingTheme.primary.withValues(alpha: 0.4), blurRadius: 20),
                      ],
                    ),
                    child: const Icon(Icons.mail_rounded, color: Colors.white, size: 32),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: PingTheme.space3Xl),

        Text('Scanning your emails…',
          style: TextStyle(
            fontSize: PingTheme.textHeadline,
            fontWeight: FontWeight.w700,
          )),
        const SizedBox(height: PingTheme.spaceSm),
        // 动态状态文字
        _AnimatedScanText(),
        const Spacer(flex: 2),
      ],
    );
  }

  // ── 结果列表 ──
  Widget _buildResultsView(BuildContext context) {
    return Column(
      children: [
        // 统计
        Container(
          margin: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg),
          padding: const EdgeInsets.all(PingTheme.spaceLg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PingTheme.success.withValues(alpha: 0.08), PingTheme.primary.withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(PingTheme.radiusLg),
            border: Border.all(color: PingTheme.success.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PingTheme.success.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.check, color: PingTheme.success, size: 24),
              ),
              const SizedBox(width: PingTheme.spaceMd),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Found ${_detected.length} subscription${_detected.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: PingTheme.textBody, fontWeight: FontWeight.w700)),
                  Text(
                    _selected.isEmpty
                        ? 'Select the ones you want to track'
                        : '${_selected.length} selected · ${CurrencyProvider.getSymbol('EUR')}${_selectedTotal.toStringAsFixed(2)}/mo',
                    style: TextStyle(fontSize: PingTheme.textSmall, color: PingTheme.subtleText(context)),
                  ),
                ],
              )),
            ],
          ),
        ),

        // 列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(PingTheme.spaceLg),
            itemCount: _detected.length,
            itemBuilder: (context, index) => _buildResultCard(index),
          ),
        ),

        // 底部 CTA
        Container(
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
            child: Row(
              children: [
                if (_selected.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      _selected.clear();
                      _selected.addAll(List.generate(_detected.length, (i) => i));
                    }),
                    child: Text(_selected.length == _detected.length ? 'Deselect all' : 'Select all',
                        style: const TextStyle(color: PingTheme.primary)),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _selected.isEmpty ? null : _addSelected,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PingTheme.radiusMd)),
                  ),
                  child: Text(
                    _selected.isEmpty ? 'Select above' : 'Add ${_selected.length} →',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(int index) {
    final sub = _detected[index];
    final isSelected = _selected.contains(index);
    final template = SubscriptionTemplates.findTemplate(sub.name);
    final color = template?.brandColor ?? PingTheme.primary;
    final logoText = template?.logoText ?? sub.name.substring(0, 2).toUpperCase();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selected.remove(index);
          } else {
            _selected.add(index);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: PingTheme.spaceSm),
        padding: const EdgeInsets.all(PingTheme.spaceLg),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
          border: Border.all(
            color: isSelected ? color : PingTheme.hairlineBorder(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(logoText,
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: PingTheme.spaceMd),
            // 信息
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.name, style: const TextStyle(fontSize: PingTheme.textBody, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyProvider.getSymbol(sub.currency)}${sub.amount.toStringAsFixed(2)}/${sub.billingCycle == 'yearly' ? 'yr' : 'mo'}'
                  '${sub.nextBillingDate != null ? ' · renews ${_formatDate(sub.nextBillingDate!)}' : ''}',
                  style: TextStyle(fontSize: PingTheme.textCaption, color: PingTheme.subtleText(context)),
                ),
              ],
            )),
            // 置信度 + 选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (sub.confidence >= 0.9)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: PingTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('high', style: TextStyle(fontSize: 9, color: PingTheme.success, fontWeight: FontWeight.w600)),
                  )
                else if (sub.confidence >= 0.6)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: PingTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('medium', style: TextStyle(fontSize: 9, color: PingTheme.warning, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: isSelected
                      ? Icon(Icons.check_circle, key: const ValueKey('checked'), color: color, size: 24)
                      : Icon(Icons.circle_outlined, key: const ValueKey('unchecked'), color: PingTheme.hairlineBorder(context), size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  double get _selectedTotal => _selected
      .map((i) => _detected[i].billingCycle == 'yearly' ? _detected[i].amount / 12 : _detected[i].amount)
      .fold(0.0, (a, b) => a + b);
}

enum _ScanPhase { idle, scanning, results }

class DetectedSub {
  final String name;
  final double amount;
  final String currency;
  final String billingCycle;
  final String category;
  final DateTime? nextBillingDate;
  final double confidence;
  final String source;

  DetectedSub({
    required this.name,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    this.category = 'Entertainment',
    this.nextBillingDate,
    this.confidence = 0.9,
    this.source = '',
  });
}

// ── 扫描中文案动画 ──
class _AnimatedScanText extends StatefulWidget {
  @override
  State<_AnimatedScanText> createState() => _AnimatedScanTextState();
}

class _AnimatedScanTextState extends State<_AnimatedScanText> {
  int _step = 0;
  final _texts = [
    'Searching for Netflix receipts…',
    'Looking for Spotify charges…',
    'Scanning Adobe billing emails…',
    'Checking iCloud subscriptions…',
    'Finding forgotten subscriptions…',
  ];

  @override
  void initState() {
    super.initState();
    _cycle();
  }

  void _cycle() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) break;
      setState(() => _step = (_step + 1) % _texts.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(_texts[_step],
        key: ValueKey(_step),
        style: TextStyle(
          color: PingTheme.subtleText(context),
          fontSize: PingTheme.textSmall,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── 模拟数据（真实环境调用后端 API）──
List<DetectedSub> _mockDetectedSubs() {
  return [
    DetectedSub(name: 'Netflix', amount: 13.99, currency: 'EUR', billingCycle: 'monthly', category: 'Entertainment', nextBillingDate: DateTime.now().add(const Duration(days: 12)), confidence: 1.0, source: 'Netflix subscription receipt'),
    DetectedSub(name: 'Spotify', amount: 10.99, currency: 'EUR', billingCycle: 'monthly', category: 'Music', nextBillingDate: DateTime.now().add(const Duration(days: 5)), confidence: 1.0, source: 'Spotify Premium payment'),
    DetectedSub(name: 'iCloud+', amount: 2.99, currency: 'EUR', billingCycle: 'monthly', category: 'Cloud', nextBillingDate: DateTime.now().add(const Duration(days: 20)), confidence: 0.9, source: 'iCloud+ monthly receipt'),
    DetectedSub(name: 'Adobe Creative Cloud', amount: 59.99, currency: 'EUR', billingCycle: 'monthly', category: 'Software', nextBillingDate: DateTime.now().add(const Duration(days: 3)), confidence: 1.0, source: 'Adobe CC billing'),
    DetectedSub(name: 'Duolingo Plus', amount: 6.99, currency: 'EUR', billingCycle: 'monthly', category: 'Education', confidence: 0.7, source: 'Duolingo subscription email'),
  ];
}
