import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../widgets/press_scale.dart';

/// Welcome screen — first thing user sees. Clean, brand-focused.
/// Animates from logo → tagline → CTA.
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onNext;
  const WelcomeScreen({super.key, required this.onNext});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.6, curve: Curves.easeOut)),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 0.8, curve: Curves.easeOut)),
    );
    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PingTheme.primary.withValues(alpha: 0.08),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(PingTheme.space3Xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [PingTheme.primary, PingTheme.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: PingTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: PingTheme.space3Xl),

                  // Title
                  FadeTransition(
                    opacity: _titleFade,
                    child: Column(children: [
                      Text('Ping',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: PingTheme.spaceSm),
                      Text('Stop bleeding money on\nsubscriptions you forgot about',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: PingTheme.textBody,
                          color: PingTheme.subtleText(context),
                          height: 1.5,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: PingTheme.space4Xl),

                  // CTA
                  FadeTransition(
                    opacity: _ctaFade,
                    child: Column(children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            widget.onNext();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: PingTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                            ),
                          ),
                          child: const Text('Get Started',
                            style: TextStyle(fontSize: PingTheme.textBody, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: PingTheme.spaceMd),
                      TextButton(
                        onPressed: widget.onNext,
                        child: Text('I already have an account',
                          style: TextStyle(
                            color: PingTheme.subtleText(context),
                            fontSize: PingTheme.textSmall,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
