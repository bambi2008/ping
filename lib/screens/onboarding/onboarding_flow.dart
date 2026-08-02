import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/iap_provider.dart';
import 'welcome_screen.dart';
import 'money_counter_screen.dart';
import 'registration_screen.dart';
import 'paywall_screen.dart';
import 'feature_tour_screen.dart';

/// 完整新用户引导流程：
/// Welcome → 烧钱计数器 → Registration → Paywall → Feature Tour → Done
class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _OnboardingStep _step = _OnboardingStep.welcome;

  @override
  void initState() {
    super.initState();
    _restoreState();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = context.read<AuthProvider>();
    final iap = context.read<IAPProvider>();

    if (auth.isLoggedIn && iap.hasAccess) {
      widget.onComplete();
    } else if (auth.isLoggedIn && !iap.hasAccess) {
      setState(() => _step = _OnboardingStep.paywall);
    }
  }

  void _goToStep(_OnboardingStep step) {
    HapticFeedback.selectionClick();
    setState(() => _step = step);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _OnboardingStep.welcome:
        return WelcomeScreen(onNext: () => _goToStep(_OnboardingStep.counter));

      case _OnboardingStep.counter:
        return MoneyCounterScreen(
          onComplete: () => _goToStep(_OnboardingStep.registration),
          onEstimate: (monthly) {
            // 可以把估算金额存下来，后续 dashboard 里参考
          },
        );

      case _OnboardingStep.registration:
        return RegistrationScreen(onComplete: () => _goToStep(_OnboardingStep.paywall));

      case _OnboardingStep.paywall:
        return PaywallScreen(onComplete: () => _goToStep(_OnboardingStep.tour));

      case _OnboardingStep.tour:
        return FeatureTourScreen(onComplete: _completeOnboarding);
    }
  }
}

enum _OnboardingStep { welcome, counter, registration, paywall, tour }
