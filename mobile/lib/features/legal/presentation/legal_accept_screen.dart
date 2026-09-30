import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_dots.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/state/auth_controller.dart';
import '../data/legal_repository.dart';

/// Shown instead of the app when the signed-in user hasn't accepted the
/// current Terms and Privacy Policy — accounts from before consent existed,
/// and everyone after an admin publishes a new version (see app_router.dart).
class LegalAcceptScreen extends ConsumerStatefulWidget {
  const LegalAcceptScreen({super.key});

  @override
  ConsumerState<LegalAcceptScreen> createState() => _LegalAcceptScreenState();
}

class _LegalAcceptScreenState extends ConsumerState<LegalAcceptScreen> {
  bool _agreed = false;
  bool _saving = false;

  Future<void> _accept(LegalDocuments docs) async {
    setState(() => _saving = true);
    try {
      await ref.read(legalRepositoryProvider).accept(docs.version);
      await ref.read(authControllerProvider.notifier).refreshUser();
    } on ApiException catch (e) {
      // Most likely a newer version was published meanwhile — reload it.
      ref.invalidate(legalDocumentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final firstTime = user?.legalAcceptedVersion == null;
    final docs = ref.watch(legalDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          firstTime ? 'Before you continue' : 'We’ve updated our terms',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: docs.when(
        loading: () => const SkeletonForm(fieldCount: 2),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: seedTeal, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    firstTime
                        ? 'Your health information is sensitive'
                        : 'Please review the changes',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    firstTime
                        ? 'Under Uganda’s Data Protection and Privacy Act we '
                              'need your consent before we store your health '
                              'information and share it with the doctors you '
                              'consult. Please read how we handle it.'
                        : 'We’ve changed our Terms of Service or Privacy '
                              'Policy. Please read them and accept to keep '
                              'using Ask Musawo.',
                    style: TextStyle(
                      color: context.palette.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/terms'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/privacy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I have read and agree to the Terms of Service and Privacy '
                'Policy, and consent to Ask Musawo processing my health '
                'information as described.',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: !_agreed || _saving ? null : () => _accept(d),
                child: _saving
                    ? const LoadingDots()
                    : const Text('Accept and continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "I agree to the Terms of Service and Privacy Policy" with both names as
/// links — for the Register screen's checkbox.
class LegalAgreementText extends StatelessWidget {
  const LegalAgreementText({super.key});

  @override
  Widget build(BuildContext context) {
    const link = TextStyle(
      color: seedTeal,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13.5, height: 1.4),
        children: [
          const TextSpan(text: 'I agree to the '),
          TextSpan(
            text: 'Terms of Service',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/legal/terms'),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/legal/privacy'),
          ),
          const TextSpan(
            text:
                ', and consent to my health information being processed '
                'as described.',
          ),
        ],
      ),
    );
  }
}
