import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageCtrl;
  int _currentPage = 0;

  // Entrance animation for each page
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.auto_awesome,
      title: 'Stop losing money to\nforgotten subscriptions',
      subtitle:
          'Track recurring payments locally and get a reminder before the next charge.',
      chips: [
        ('✍️ Simple tracking', PingTheme.primary),
        ('🔔 Alerts', PingTheme.secondary),
        ('📅 Renewal calendar', PingTheme.success),
        ('🔒 Private', PingTheme.warning),
      ],
      iconColors: [PingTheme.primary, Color(0xFFA29BFE)],
    ),
    _OnboardingPage(
      icon: Icons.receipt_long_rounded,
      title: 'All your subscriptions\nin one place',
      subtitle:
          'Add Netflix, Spotify, iCloud, gym, or anything else. We\'ll handle the rest.',
      chips: [
        ('🎬 Entertainment', Color(0xFFE50914)),
        ('🎵 Music', Color(0xFF1DB954)),
        ('☁️ Cloud', Color(0xFF3693F5)),
        ('📦 More', PingTheme.primary),
      ],
      iconColors: [Color(0xFF00D2D3), Color(0xFF48DBFB)],
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      title: 'Never miss\na renewal',
      subtitle:
          'Get reminded 3 days, 1 day, and on the day of each billing — so you can cancel in time.',
      chips: [
        ('⏰ 3-day early alert', PingTheme.warning),
        ('📅 Day-of reminder', PingTheme.danger),
        ('📊 MoM spend trend', PingTheme.success),
        ('💡 Smart insights', PingTheme.primary),
      ],
      iconColors: [Color(0xFFFECA57), Color(0xFFFF6B6B)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    HapticFeedback.lightImpact();
    if (page >= _pages.length) {
      _finish();
      return;
    }
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = page);
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: PingTheme.subtleText(context),
                      fontSize: PingTheme.textSmall,
                    ),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildPage(context, page, index),
                    ),
                  );
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(PingTheme.radiusXs),
                      color: active
                          ? PingTheme.primary
                          : PingTheme.hairlineBorder(context),
                    ),
                  );
                }),
              ),
            ),
            // CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _goToPage(_currentPage + 1),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isLast ? Icons.add : Icons.arrow_forward_rounded,
                      key: ValueKey(isLast),
                    ),
                  ),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isLast ? 'Add My First Subscription' : 'Continue',
                      key: ValueKey(isLast),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Your subscription data stays on this device.',
              style: TextStyle(color: PingTheme.subtleText(context), fontSize: 12),
            ),
            const SizedBox(height: PingTheme.spaceLg),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    _OnboardingPage page,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PingTheme.space3Xl),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Pulsing hero icon
          _PulsingIcon(
            icon: page.icon,
            colors: page.iconColors,
            animController: _fadeCtrl,
          ),
          const SizedBox(height: PingTheme.space4Xl),
          // Headline
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: PingTheme.spaceLg),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: PingTheme.textBody,
              color: PingTheme.subtleText(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: PingTheme.spaceXl),
          // Feature chips with staggered appearance
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: page.chips.asMap().entries.map((entry) {
              final chipIndex = entry.key;
              final (text, color) = entry.value;
              return _AnimatedChip(
                text: text,
                color: color,
                delay: Duration(milliseconds: 200 + chipIndex * 100),
                animController: _fadeCtrl,
              );
            }).toList(),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// Pulsing hero icon with scale animation.
class _PulsingIcon extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final AnimationController animController;

  const _PulsingIcon({
    required this.icon,
    required this.colors,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        final scale = 1.0 + (animController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + value * 0.2,
            child: child,
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: colors),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: 52, color: Colors.white),
        ),
      ),
    );
  }
}

/// Animated chip with fade-in slide-up.
class _AnimatedChip extends StatelessWidget {
  final String text;
  final Color color;
  final Duration delay;
  final AnimationController animController;

  const _AnimatedChip({
    required this.text,
    required this.color,
    required this.delay,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        // Stagger based on delay
        final start = delay.inMilliseconds / 600;
        final end = (start + 0.3).clamp(0.0, 1.0);
        final t = (animController.value - start) / (end - start);
        final clamped = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: clamped,
          child: Transform.translate(
            offset: Offset(0, (1 - clamped) * 8),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(PingTheme.radiusLg),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: PingTheme.textSmall,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Data model for an onboarding page.
class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<(String, Color)> chips;
  final List<Color> iconColors;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.iconColors,
  });
}
