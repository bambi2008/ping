import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../services/subscription_templates.dart';
import '../../widgets/fire_particles.dart';

/// 烧钱计数器 — 用户点亮自己用的订阅，看着数字飙升，最后给年度震撼数字。
/// 替代传统问卷，用视觉冲击做"洗脑"。
class MoneyCounterScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final void Function(double monthlyEstimate, List<String> selectedIds)? onEstimate;

  const MoneyCounterScreen({
    super.key,
    required this.onComplete,
    this.onEstimate,
  });

  @override
  State<MoneyCounterScreen> createState() => _MoneyCounterScreenState();
}

class _MoneyCounterScreenState extends State<MoneyCounterScreen>
    with TickerProviderStateMixin {
  // 动画控制器
  late AnimationController _counterCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _revealCtrl;

  // 当前显示金额（动画驱动）
  double _displayAmount = 0.0;
  double _targetAmount = 0.0;

  // 阶段
  _CounterPhase _phase = _CounterPhase.selecting;

  // 选中的订阅
  final Set<String> _selected = {};

  // 常见订阅库（logo name, 显示名, 月费 €, 颜色）
  static const _subs = [
    ('netflix', 'Netflix', 13.99, Color(0xFFE50914)),
    ('spotify', 'Spotify', 10.99, Color(0xFF1DB954)),
    ('disneyplus', 'Disney+', 8.99, Color(0xFF0C39A7)),
    ('youtube', 'YT Premium', 11.99, Color(0xFFFF0000)),
    ('icloud', 'iCloud+', 2.99, Color(0xFF3693F2)),
    ('amazon', 'Prime', 8.99, Color(0xFFFF9900)),
    ('adobe', 'Photoshop', 23.99, Color(0xFFED2228)),
    ('chatgpt', 'ChatGPT+', 22.00, Color(0xFF10A37F)),
    ('apple-music', 'Apple Music', 10.99, Color(0xFFFA243D)),
    ('github', 'GitHub', 4.00, Color(0xFF8B5CF6)),
    ('notion', 'Notion', 9.50, Color(0xFF555555)),
    ('dropbox', 'Dropbox', 11.99, Color(0xFF0061FF)),
    ('hbo', 'HBO Max', 9.99, Color(0xFF8B0000)),
    ('duolingo', 'Duolingo', 6.99, Color(0xFF58CC02)),
    ('figma', 'Figma', 12.00, Color(0xFFF24E1E)),
    ('1password', '1Password', 2.99, Color(0xFF0572EC)),
    ('heartspace', 'Headspace', 12.99, Color(0xFFF47B20)),
    ('gym', 'Gym', 29.99, Color(0xFF6C5CE7)),
  ];

  @override
  void initState() {
    super.initState();
    _counterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _counterCtrl.addListener(() {
      setState(() {
        _displayAmount = _targetAmount * _counterCtrl.value;
      });
    });
  }

  @override
  void dispose() {
    _counterCtrl.dispose();
    _particleCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  void _toggleSub(String key, double price) {
    HapticFeedback.mediumImpact();

    if (_selected.contains(key)) {
      _selected.remove(key);
      _targetAmount -= price;
    } else {
      _selected.add(key);
      _targetAmount += price;
      // 粒子动画
      _particleCtrl.reset();
      _particleCtrl.forward();
    }

    // 数字滚动动画
    _counterCtrl.reset();
    _counterCtrl.forward();
  }

  void _showReveal() {
    HapticFeedback.heavyImpact();
    setState(() => _phase = _CounterPhase.revealing);
    _revealCtrl.forward();
  }

  double get _yearlyAmount => _targetAmount * 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _phase == _CounterPhase.selecting
            ? _buildSelectingView(context)
            : _buildRevealView(context),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  阶段 1: 选择订阅
  // ══════════════════════════════════════════════════
  Widget _buildSelectingView(BuildContext context) {
    return Column(
      children: [
        // 顶部
        Padding(
          padding: const EdgeInsets.fromLTRB(
              PingTheme.spaceLg, PingTheme.spaceLg, PingTheme.spaceLg, PingTheme.spaceSm),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Tap what you use',
                      style: TextStyle(
                        color: PingTheme.subtleText(context),
                        fontSize: PingTheme.textSmall,
                        fontWeight: FontWeight.w500,
                      )),
                  const Spacer(),
                  const SizedBox(width: 48), // 平衡
                ],
              ),

              const SizedBox(height: PingTheme.spaceLg),

              // 💰 中央计数器
              _buildBigCounter(),

              const SizedBox(height: PingTheme.spaceXs),

              // 副标题
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _selected.isEmpty
                      ? 'Tap every subscription you pay for 👇'
                      : '${_selected.length} subscription${_selected.length == 1 ? '' : 's'} · €${_targetAmount.toStringAsFixed(2)}/mo',
                  key: ValueKey(_selected.length),
                  style: TextStyle(
                    color: PingTheme.subtleText(context),
                    fontSize: PingTheme.textSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: PingTheme.spaceMd),

        // 订阅网格
        Expanded(
          child: Stack(
            children: [
              // 粒子层 — RepaintBoundary 隔离
              if (_particleCtrl.isAnimating)
                Positioned.fill(
                  child: RepaintBoundary(child: IgnorePointer(child: CustomPaint(
                    painter: _CoinParticlePainter(_particleCtrl),
                  ))),
                ),

              // 网格
              GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                    PingTheme.spaceLg, 0, PingTheme.spaceLg, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _subs.length,
                itemBuilder: (context, index) {
                  final sub = _subs[index];
                  return _buildSubCard(sub);
                },
              ),
            ],
          ),
        ),

        // 底部 CTA
        _buildBottomCTA(),
      ],
    );
  }

  Widget _buildBigCounter() {
    final isHot = _targetAmount > 50;
    final color = _targetAmount == 0
        ? PingTheme.subtleText(context)
        : isHot
            ? PingTheme.danger
            : PingTheme.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 光晕
        if (_targetAmount > 0)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: isHot ? 1.0 : 0.6),
            duration: const Duration(milliseconds: 600),
            builder: (context, glow, child) => Container(
              width: 160 + glow * 20,
              height: 160 + glow * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.15 * glow),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        // 数字
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 52 + (_targetAmount > 0 ? 4 : 0),
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -2,
            height: 1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          child: Text('€${_displayAmount.toStringAsFixed(2)}'),
        ),

        // /mo 标签
        Positioned(
          bottom: 0,
          child: Text('/ month',
              style: TextStyle(
                color: PingTheme.subtleText(context),
                fontSize: PingTheme.textCaption,
                fontWeight: FontWeight.w500,
              )),
        ),
      ],
    );
  }

  Widget _buildSubCard((String, String, double, Color) sub) {
    final (key, name, price, color) = sub;
    final isSelected = _selected.contains(key);

    return GestureDetector(
      onTap: () => _toggleSub(key, price),
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(PingTheme.radiusMd),
            border: Border.all(
              color: isSelected ? color : PingTheme.hairlineBorder(context),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo 圆
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    name.length > 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // 名称
              Text(name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : PingTheme.subtleText(context),
                  )),
              const SizedBox(height: 2),
              // 价格
              Text('€$price',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? color : PingTheme.subtleText(context),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCTA() {
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
                  '还有更多？直接进来全部追踪',
                  style: TextStyle(
                    color: PingTheme.subtleText(context),
                    fontSize: PingTheme.textCaption,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _selected.isEmpty ? null : _showReveal,
                style: FilledButton.styleFrom(
                  backgroundColor: _selected.isEmpty
                      ? PingTheme.subtleText(context)
                      : PingTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                  ),
                ),
                child: Text(
                  _selected.isEmpty ? 'Tap subscriptions above' : 'See my yearly total →',
                  style: const TextStyle(
                    fontSize: PingTheme.textBody,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  阶段 2: 震撼揭示
  // ══════════════════════════════════════════════════
  Widget _buildRevealView(BuildContext context) {
    return AnimatedBuilder(
      animation: _revealCtrl,
      builder: (context, child) {
        final progress = _revealCtrl.value;
        // 年度金额滚动动画
        final yearlyShown = _yearlyAmount * progress;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PingTheme.danger.withValues(alpha: 0.08 * progress),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 🔥 火焰粒子效果
              if (progress > 0.1)
                Opacity(
                  opacity: ((progress - 0.1) / 0.3).clamp(0.0, 1.0),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.3, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _revealCtrl,
                        curve: const Interval(0.1, 0.4, curve: Curves.elasticOut),
                      ),
                    ),
                    child: SizedBox(
                      width: 120, height: 100,
                      child: FireParticles(intensity: 0.8, baseColor: PingTheme.danger),
                    ),
                  ),
                ),

              const SizedBox(height: PingTheme.space2Xl),

              // "你每年烧掉"
              if (progress > 0.2)
                Opacity(
                  opacity: ((progress - 0.2) / 0.2).clamp(0.0, 1.0),
                  child: Text('You\'re burning through',
                    style: TextStyle(
                      color: PingTheme.subtleText(context),
                      fontSize: PingTheme.textBody,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: PingTheme.spaceMd),

              // 💀 大数字
              if (progress > 0.3)
                Opacity(
                  opacity: ((progress - 0.3) / 0.3).clamp(0.0, 1.0),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _revealCtrl,
                      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
                    )),
                    child: Text(
                      '€${yearlyShown.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: PingTheme.danger,
                        letterSpacing: -3,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: PingTheme.spaceXs),

              if (progress > 0.5)
                Opacity(
                  opacity: ((progress - 0.5) / 0.2).clamp(0.0, 1.0),
                  child: Text('every single year',
                    style: TextStyle(
                      color: PingTheme.danger.withValues(alpha: 0.7),
                      fontSize: PingTheme.textBody,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: PingTheme.space3Xl),

              // 选中列表
              if (progress > 0.6)
                Opacity(
                  opacity: ((progress - 0.6) / 0.3).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: PingTheme.space2Xl),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _selected.map((key) {
                        final sub = _subs.firstWhere((s) => s.$1 == key);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: sub.$4.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sub.$4.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${sub.$2} €${sub.$3}',
                            style: TextStyle(
                              fontSize: PingTheme.textSmall,
                              color: sub.$4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const Spacer(flex: 1),

              // CTA
              if (progress > 0.8)
                Opacity(
                  opacity: ((progress - 0.8) / 0.2).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.all(PingTheme.space2Xl),
                    child: Column(
                      children: [
                        Text(
                          'Want to stop the bleeding?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: PingTheme.spaceSm),
                        Text(
                          'Ping tracks every renewal, alerts you before\ncharges, and helps you cancel in seconds.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PingTheme.subtleText(context),
                            fontSize: PingTheme.textSmall,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: PingTheme.space2Xl),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              if (widget.onEstimate != null) {
                                widget.onEstimate!(_targetAmount, _selected.toList());
                              }
                              widget.onComplete();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: PingTheme.danger,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                              ),
                            ),
                            child: const Text(
                              'Stop wasting money →',
                              style: TextStyle(
                                fontSize: PingTheme.textBody,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: PingTheme.spaceMd),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _phase = _CounterPhase.selecting;
                              _revealCtrl.reset();
                            });
                          },
                          child: Text('I probably missed some',
                              style: TextStyle(
                                  color: PingTheme.subtleText(context),
                                  fontSize: PingTheme.textSmall)),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: PingTheme.space2Xl),
            ],
          ),
        );
      },
    );
  }
}

enum _CounterPhase { selecting, revealing }

/// 金币粒子动画 — 每次点击订阅时从卡片位置飞向中央计数器
class _CoinParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Random _rng = Random();

  _CoinParticlePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height * 0.15); // 计数器位置

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * pi * 2 + progress * pi;
      final radius = (1 - progress) * 120;
      final dx = center.dx + cos(angle) * radius;
      final dy = center.dy + sin(angle) * radius + progress * 80;

      final paint = Paint()
        ..color = const Color(0xFFFFB800).withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), (1 - progress) * 4 + 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
