import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../widgets/press_scale.dart';

/// Feature tour — shown after registration + trial activation.
/// Quick swipeable cards showing what user can do in Ping.
class FeatureTourScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const FeatureTourScreen({super.key, required this.onComplete});

  @override
  State<FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends State<FeatureTourScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _animCtrl;

  static const _pages = [
    _TourPage(
      emoji: '📊',
      title: 'See your total spend',
      subtitle: 'One number tells the whole story.\nKnow exactly how much leaves your\naccount every month.',
      icon: Icons.dashboard_rounded,
      color: PingTheme.primary,
    ),
    _TourPage(
      emoji: '⏰',
      title: 'Get reminded before\nevery renewal',
      subtitle: '3-day, 1-day, and day-of alerts.\nNever get surprised by a charge again.',
      icon: Icons.notifications_active_rounded,
      color: PingTheme.warning,
    ),
    _TourPage(
      emoji: '📅',
      title: 'Calendar that shows\nyour bills',
      subtitle: 'See every upcoming charge on a calendar.\nPlan your month without surprises.',
      icon: Icons.calendar_month_rounded,
      color: PingTheme.secondary,
    ),
    _TourPage(
      emoji: '📈',
      title: 'Track spending\ntrends',
      subtitle: 'Watch your monthly costs go up or down.\nCatch price hikes before they add up.',
      icon: Icons.trending_up_rounded,
      color: PingTheme.success,
    ),
    _TourPage(
      emoji: '✂️',
      title: 'Cancel with confidence',
      subtitle: 'Built-in cancellation guides for every service.\nStop paying for things you don\'t use.',
      icon: Icons.content_cut_rounded,
      color: PingTheme.danger,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = page);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(PingTheme.spaceMd),
              child: TextButton(
                onPressed: widget.onComplete,
                child: Text('Skip',
                    style: TextStyle(color: PingTheme.subtleText(context))),
              ),
            ),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return FadeTransition(
                  opacity: CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
                  child: _buildPage(page),
                );
              },
            ),
          ),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? PingTheme.primary : PingTheme.hairlineBorder(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: PingTheme.space2Xl),

          // CTA
          Padding(
            padding: const EdgeInsets.all(PingTheme.space2Xl),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: _currentPage < _pages.length - 1
                  ? PressScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [PingTheme.primary, PingTheme.primaryLight]),
                          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                          boxShadow: [BoxShadow(color: PingTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Center(child: Text('Next',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                    )
                  : PressScale(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onComplete();
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [PingTheme.success, PingTheme.success.withValues(alpha: 0.85)]),
                          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                          boxShadow: [BoxShadow(color: PingTheme.success.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: const Center(child: Text('Let\'s go! 🎉',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
                      ),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPage(_TourPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PingTheme.space3Xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji
          Text(page.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: PingTheme.space2Xl),

          // Icon badge
          ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
            ),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [page.color, page.color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: page.color.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(page.icon, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: PingTheme.space2Xl),

          // Title
          Text(page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: PingTheme.spaceMd),

          // Subtitle
          Text(page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PingTheme.subtleText(context),
              fontSize: PingTheme.textBody,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourPage {
  final String emoji;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _TourPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
