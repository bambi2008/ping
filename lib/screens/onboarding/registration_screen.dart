import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/press_scale.dart';

/// Registration screen — email, Apple Sign-In, Google Sign-In.
/// After registration, proceeds to paywall.
class RegistrationScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const RegistrationScreen({super.key, required this.onComplete});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _showEmailForm = false;
  bool _emailValid = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _validateEmail(String v) {
    setState(() {
      _emailValid = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v);
    });
  }

  Future<void> _signInWithEmail() async {
    if (!_emailValid) return;
    final auth = context.read<AuthProvider>();
    await auth.signInWithEmail(
      email: _emailCtrl.text.trim(),
      displayName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
    );
    widget.onComplete();
  }

  Future<void> _signInWithApple() async {
    final auth = context.read<AuthProvider>();
    // In production: use sign_in_with_apple package
    // For now, simulate with a dummy email
    HapticFeedback.mediumImpact();
    await auth.signInWithApple(
      email: 'user@privaterelay.appleid.com',
      displayName: 'Apple User',
    );
    widget.onComplete();
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthProvider>();
    // In production: use google_sign_in package
    HapticFeedback.mediumImpact();
    await auth.signInWithGoogle(
      email: 'user@gmail.com',
      displayName: 'Google User',
    );
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PingTheme.space2Xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: PingTheme.space2Xl),

              // Title
              Text('Create your account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PingTheme.spaceSm),
              Text('Takes 10 seconds. No password to remember\nif you use Apple or Google.',
                style: TextStyle(
                  color: PingTheme.subtleText(context),
                  fontSize: PingTheme.textBody,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: PingTheme.space4Xl),

              // ── Email form (collapsible) ──
              if (_showEmailForm) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name (optional)',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: PingTheme.spaceMd),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: _emailValid
                        ? const Icon(Icons.check_circle, color: PingTheme.success)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: PingTheme.spaceLg),
                PressScale(
                  onTap: (auth.isLoading || !_emailValid) ? null : _signInWithEmail,
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [PingTheme.primary, PingTheme.primaryLight]),
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                      boxShadow: [BoxShadow(color: PingTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: auth.isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Continue with Email', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                            ]),
                    ),
                  ),
                ),
                const SizedBox(height: PingTheme.spaceLg),
                TextButton(
                  onPressed: () => setState(() => _showEmailForm = false),
                  child: Text('Use Apple or Google instead',
                      style: TextStyle(color: PingTheme.subtleText(context))),
                ),
              ] else ...[
                // ── Apple Sign-In ──
                PressScale(
                  onTap: auth.isLoading ? null : _signInWithApple,
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                    ),
                    child: Center(
                      child: auth.isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.apple, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text('Continue with Apple', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                            ]),
                    ),
                  ),
                ),
                const SizedBox(height: PingTheme.spaceMd),

                // ── Google Sign-In ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                      ),
                      side: BorderSide(color: PingTheme.hairlineBorder(context)),
                    ),
                    icon: auth.isLoading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
                    label: const Text('Continue with Google',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                ),
                const SizedBox(height: PingTheme.spaceLg),

                // ── Divider ──
                Row(children: [
                  Expanded(child: Divider(color: PingTheme.hairlineBorder(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd),
                    child: Text('or',
                        style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textSmall)),
                  ),
                  Expanded(child: Divider(color: PingTheme.hairlineBorder(context))),
                ]),
                const SizedBox(height: PingTheme.spaceLg),

                // ── Email option ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : () => setState(() => _showEmailForm = true),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                      ),
                      side: BorderSide(color: PingTheme.hairlineBorder(context)),
                    ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Continue with Email',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],

              const SizedBox(height: PingTheme.space3Xl),

              // Privacy note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: PingTheme.subtleText(context)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(
                    'We never sell your data. Your subscriptions stay on your device.',
                    style: TextStyle(
                      color: PingTheme.subtleText(context),
                      fontSize: PingTheme.textCaption,
                    ),
                    textAlign: TextAlign.center,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
