import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Interactive survey — "brainwashing" through engagement.
/// Asks questions that make users realize how much they're losing on subscriptions.
class SurveyScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SurveyScreen({super.key, required this.onComplete});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  // Survey answers
  String? _spendEstimate;
  String? _subCount;
  bool? _forgotToCancel;
  String? _topCategory;

  static const _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    HapticFeedback.selectionClick();
    _animCtrl.reset();
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    ).then((_) => _animCtrl.forward());
    setState(() => _currentPage = page);
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0: return _spendEstimate != null;
      case 1: return _subCount != null;
      case 2: return _forgotToCancel != null;
      case 3: return _topCategory != null;
      default: return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Progress bar
          _buildProgressBar(),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPage(
                  icon: Icons.euro,
                  emoji: '💸',
                  title: 'How much do you think\nyou spend on subscriptions\nper month?',
                  subtitle: 'Be honest — most people underestimate by 40%.',
                  options: [
                    _Option('Less than €20', 'I keep it tight'),
                    _Option('€20 – €50', 'A few essentials'),
                    _Option('€50 – €100', 'Getting up there'),
                    _Option('€100+', 'I might have a problem'),
                    _Option("I honestly don't know", 'And that scares me'),
                  ],
                  selected: _spendEstimate,
                  onSelect: (v) => setState(() => _spendEstimate = v),
                ),
                _buildPage(
                  icon: Icons.apps,
                  emoji: '📱',
                  title: 'How many subscriptions\nare you actively paying for?',
                  subtitle: 'Streaming, cloud, software, gym, apps… all of them.',
                  options: [
                    _Option('1 – 3', 'Minimalist'),
                    _Option('4 – 7', 'Average user'),
                    _Option('8 – 15', 'Power user'),
                    _Option('15+', 'I lost count'),
                    _Option('Not sure', 'Probably too many'),
                  ],
                  selected: _subCount,
                  onSelect: (v) => setState(() => _subCount = v),
                ),
                _buildPage(
                  icon: Icons.warning_amber,
                  emoji: '🫠',
                  title: 'Have you ever paid for\na subscription you forgot\nto cancel?',
                  subtitle: 'The average person wastes €240/year on forgotten subs.',
                  options: [
                    _Option('Yes, multiple times', 'Gym memberships are the worst'),
                    _Option('Yes, once or twice', 'Learned my lesson'),
                    _Option('Not that I know of', 'Key phrase: "that I know of"'),
                    _Option('Never', 'You\'re either lucky or lying 😄'),
                  ],
                  selected: _forgotToCancel,
                  onSelect: (v) => setState(() => _forgotToCancel = v),
                  isYesNo: true,
                ),
                _buildPage(
                  icon: Icons.category,
                  emoji: '🎯',
                  title: 'What type of subscription\ndo you want to track\nthe most?',
                  subtitle: 'We\'ll prioritize these in your dashboard.',
                  options: [
                    _Option('Streaming', 'Netflix, Disney+, HBO…', category: 'Entertainment'),
                    _Option('Music & Audio', 'Spotify, Deezer, Audible…', category: 'Music'),
                    _Option('Cloud & Software', 'iCloud, Adobe, GitHub…', category: 'Cloud'),
                    _Option('Health & Fitness', 'Gym, Strava, Headspace…', category: 'Health'),
                    _Option('Everything', 'I want full control', category: 'Other'),
                  ],
                  selected: _topCategory,
                  onSelect: (v) => setState(() => _topCategory = v),
                ),
              ],
            ),
          ),

          // Bottom nav
          _buildBottomNav(),
        ]),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          PingTheme.spaceLg, PingTheme.spaceLg, PingTheme.spaceLg, PingTheme.spaceSm),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: _currentPage > 0
              ? () => _goToPage(_currentPage - 1)
              : null,
        ),
        const SizedBox(width: PingTheme.spaceSm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              minHeight: 6,
              backgroundColor: PingTheme.hairlineBorder(context),
              color: PingTheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: PingTheme.spaceMd),
        Text('${_currentPage + 1}/$_totalPages',
            style: TextStyle(
              fontSize: PingTheme.textSmall,
              color: PingTheme.subtleText(context),
              fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required List<_Option> options,
    required String? selected,
    required ValueChanged<String> onSelect,
    bool isYesNo = false,
  }) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: PingTheme.space2Xl, vertical: PingTheme.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: PingTheme.spaceLg),

              // Title
              Text(title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: PingTheme.spaceSm),

              // Subtitle
              Text(subtitle,
                style: TextStyle(
                  color: PingTheme.subtleText(context),
                  fontSize: PingTheme.textBody,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: PingTheme.space2Xl),

              // Options
              ...options.map((opt) => _optionCard(opt, selected, onSelect, isYesNo)),

              // Insight card for question 2 (forgot to cancel)
              if (_currentPage == 2 && _forgotToCancel != null && _forgotToCancel!.contains('Yes')) ...[
                const SizedBox(height: PingTheme.spaceLg),
                Container(
                  padding: const EdgeInsets.all(PingTheme.spaceLg),
                  decoration: BoxDecoration(
                    color: PingTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                    border: Border.all(color: PingTheme.danger.withValues(alpha: 0.15)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.lightbulb_outline, color: PingTheme.danger, size: 20),
                    const SizedBox(width: PingTheme.spaceSm),
                    Expanded(child: Text(
                      'You\'re not alone. 78% of people have paid for at least one subscription they don\'t use. Ping fixes this.',
                      style: TextStyle(
                        fontSize: PingTheme.textSmall,
                        color: PingTheme.danger,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    )),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard(_Option opt, String? selected, ValueChanged<String> onSelect, bool isYesNo) {
    final isSelected = selected == opt.label;
    return Container(
      margin: const EdgeInsets.only(bottom: PingTheme.spaceSm),
      child: Material(
        color: isSelected
            ? PingTheme.primary.withValues(alpha: 0.08)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(opt.label);
            // Auto-advance after short delay
            Future.delayed(const Duration(milliseconds: 350), () {
              if (_currentPage < _totalPages - 1) {
                _goToPage(_currentPage + 1);
              }
            });
          },
          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: PingTheme.spaceLg, vertical: PingTheme.spaceMd + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PingTheme.radiusMd),
              border: Border.all(
                color: isSelected ? PingTheme.primary : PingTheme.hairlineBorder(context),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.label,
                      style: TextStyle(
                        fontSize: PingTheme.textBody,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? PingTheme.primary : null,
                      )),
                    if (opt.hint != null) ...[
                      const SizedBox(height: 2),
                      Text(opt.hint!,
                        style: TextStyle(
                          fontSize: PingTheme.textCaption,
                          color: PingTheme.subtleText(context),
                        )),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: PingTheme.primary, size: 22)
              else
                Icon(Icons.radio_button_unchecked,
                    color: PingTheme.hairlineBorder(context), size: 22),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(PingTheme.spaceXl),
      child: Row(children: [
        if (_currentPage > 0)
          TextButton(
            onPressed: () => _goToPage(_currentPage - 1),
            child: const Text('Back'),
          ),
        const Spacer(),
        if (_currentPage < _totalPages - 1)
          TextButton(
            onPressed: _canProceed ? () => _goToPage(_currentPage + 1) : null,
            child: Text('Skip',
                style: TextStyle(color: PingTheme.subtleText(context))),
          )
        else
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _canProceed
                  ? () {
                      HapticFeedback.mediumImpact();
                      widget.onComplete();
                    }
                  : null,
              child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

class _Option {
  final String label;
  final String? hint;
  final String? category;
  _Option(this.label, [this.hint, {this.category}]);
}
