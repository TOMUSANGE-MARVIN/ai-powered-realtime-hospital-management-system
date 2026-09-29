import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/two_factor_widgets.dart';
import '../../auth/state/auth_controller.dart';

/// Turns authenticator-app (TOTP) two-factor authentication on or off.
///
/// Enrolling is two steps: the password unlocks a fresh secret (shown as a QR
/// code), then the first code from the app confirms it — 2FA is only switched
/// on by the server once that code checks out.
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  TotpEnrollment? _enrollment;
  String _code = '';
  bool _busy = false;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onToggle(bool enable, bool isEnabled) async {
    if (enable && _enrollment != null) return;
    if (!enable && _enrollment != null) {
      setState(() => _enrollment = null);
      return;
    }
    final password = await _askPassword(
      isEnabled ? 'Turn off 2FA' : 'Turn on 2FA',
    );
    if (password == null) return;
    await _run(() async {
      if (isEnabled) {
        await _repo.disableTwoFactor(password);
        await ref.read(authControllerProvider.notifier).refreshUser();
        if (mounted) _showError('Two-factor authentication turned off');
      } else {
        final enrollment = await _repo.enableTwoFactor(password);
        setState(() => _enrollment = enrollment);
      }
    });
  }

  Future<void> _completeSetup() async {
    final enrollment = _enrollment;
    if (enrollment == null || _code.length < 6) return;
    await _run(() async {
      await _repo.confirmTotp(_code);
      await ref.read(authControllerProvider.notifier).refreshUser();
      setState(() => _enrollment = null);
      if (mounted) {
        await _showRecoveryCodes(enrollment.backupCodes, justEnabled: true);
      }
    });
  }

  Future<void> _viewRecoveryCodes() async {
    final password = await _askPassword('New recovery codes');
    if (password == null) return;
    await _run(() async {
      final codes = await _repo.regenerateBackupCodes(password);
      if (mounted) await _showRecoveryCodes(codes);
    });
  }

  Future<String?> _askPassword(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm your password'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _showRecoveryCodes(
    List<String> codes, {
    bool justEnabled = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(justEnabled ? '2FA is on' : 'Recovery codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save these codes somewhere safe. Each one signs you in once if '
              'you lose access to your authenticator app. Any older codes no '
              'longer work.',
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                codes.join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: codes.join('\n'))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I saved them'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final isEnabled = user?.twoFactorEnabled ?? false;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final enrollment = _enrollment;

    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: seedTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: seedTeal,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Secure Your Account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Protect your Ask Musawo account with an extra layer of '
              'security. Once configured, you\'ll be required to enter both '
              'your password and an authentication code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enable 2FA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEnabled
                              ? 'On — codes required at sign-in.'
                              : 'Required for certain health records.',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled || enrollment != null,
                    onChanged: (value) => _onToggle(value, isEnabled),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AUTHENTICATION METHOD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: muted,
              ),
            ),
            const SizedBox(height: 10),
            const _MethodCard(
              icon: Icons.smartphone,
              title: 'Text Message (SMS)',
              subtitle:
                  'Receive a 6-digit code via SMS to your registered '
                  'mobile number. Coming soon.',
              selected: false,
              enabled: false,
            ),
            const SizedBox(height: 10),
            const _MethodCard(
              icon: Icons.lock_outline,
              title: 'Authenticator App',
              subtitle:
                  'Use an app like Google Authenticator or Authy to '
                  'generate codes.',
              selected: true,
            ),
            if (enrollment != null) ...[
              const SizedBox(height: 20),
              _EnrollmentCard(
                enrollment: enrollment,
                onCodeChanged: (value) => setState(() => _code = value),
              ),
            ],
            if (isEnabled) ...[
              const SizedBox(height: 20),
              SoftCard(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.key_outlined, color: muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recovery Codes',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'If you lose access to your phone, you can use '
                            'recovery codes to sign in.',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _viewRecoveryCodes,
                            child: const Text('Get new codes'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: enrollment == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton.icon(
                onPressed: _busy || _code.length < 6 ? null : _completeSetup,
                iconAlignment: IconAlignment.end,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: const Text('Complete Setup'),
              ),
            ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SoftCard(
        borderSide: BorderSide(
          color: selected ? seedTeal : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: selected
                  ? seedTeal.withValues(alpha: 0.12)
                  : scheme.surfaceContainerHigh,
              child: Icon(
                icon,
                size: 18,
                color: selected ? seedTeal : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? seedTeal : scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({
    required this.enrollment,
    required this.onCodeChanged,
  });

  final TotpEnrollment enrollment;
  final ValueChanged<String> onCodeChanged;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SoftCard(
      child: Column(
        children: [
          const Text(
            'Scan with your authenticator app',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(data: enrollment.totpUri, size: 180),
          ),
          const SizedBox(height: 10),
          Text(
            'Or enter this key manually',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: SelectableText(
                  enrollment.secret,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy key',
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: enrollment.secret)),
              ),
            ],
          ),
          const Divider(height: 28),
          const Text(
            'Enter Verification Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'The 6-digit code shown in the app',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OtpCodeField(onChanged: onCodeChanged),
        ],
      ),
    );
  }
}
