import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../state/auth_controller.dart';

/// Six separate digit boxes backed by one invisible text field, so paste,
/// backspace and the OS "fill code" suggestion all behave normally.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  static const _length = 6;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final code = _controller.text;
    return GestureDetector(
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: Stack(
        children: [
          // Kept in the tree (not Offstage) so it can hold focus and receive
          // keyboard input; the boxes below are what the user sees.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_length),
                ],
                showCursor: false,
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged(value);
                  if (value.length == _length) widget.onCompleted?.call(value);
                },
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < _length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(kCardRadius),
                      border: Border.all(
                        color: _focusNode.hasFocus && i == code.length
                            ? seedTeal
                            : i < code.length
                                ? seedTeal.withValues(alpha: 0.5)
                                : scheme.outlineVariant,
                        width: _focusNode.hasFocus && i == code.length ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      i < code.length ? code[i] : '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet shown after a correct password on a 2FA-protected account.
/// Returns true once the second factor is accepted and the user is signed in.
Future<bool> showTwoFactorChallenge(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _TwoFactorChallengeSheet(),
  );
  return result ?? false;
}

class _TwoFactorChallengeSheet extends ConsumerStatefulWidget {
  const _TwoFactorChallengeSheet();

  @override
  ConsumerState<_TwoFactorChallengeSheet> createState() =>
      _TwoFactorChallengeSheetState();
}

class _TwoFactorChallengeSheetState
    extends ConsumerState<_TwoFactorChallengeSheet> {
  bool _useBackupCode = false;
  bool _submitting = false;
  String _code = '';
  String? _error;
  final _backupController = TextEditingController();

  @override
  void dispose() {
    _backupController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _useBackupCode ? _backupController.text.trim() : _code;
    if (code.isEmpty || (!_useBackupCode && code.length < 6)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifySecondFactor(code, isBackupCode: _useBackupCode);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_user_outlined, size: 40, color: seedTeal),
          const SizedBox(height: 12),
          const Text(
            'Two-Factor Authentication',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _useBackupCode
                ? 'Enter one of the recovery codes you saved when you set up 2FA.'
                : 'Enter the 6-digit code from your authenticator app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 20),
          if (_useBackupCode)
            TextField(
              controller: _backupController,
              autofocus: true,
              enabled: !_submitting,
              decoration: const InputDecoration(labelText: 'Recovery code'),
              onSubmitted: (_) => _submit(),
            )
          else
            OtpCodeField(
              autofocus: true,
              enabled: !_submitting,
              onChanged: (value) => _code = value,
              onCompleted: (_) => _submit(),
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
          TextButton(
            onPressed: _submitting
                ? null
                : () => setState(() {
                      _useBackupCode = !_useBackupCode;
                      _error = null;
                    }),
            child: Text(
              _useBackupCode
                  ? 'Use authenticator code instead'
                  : 'Lost your phone? Use a recovery code',
            ),
          ),
        ],
      ),
    );
  }
}
