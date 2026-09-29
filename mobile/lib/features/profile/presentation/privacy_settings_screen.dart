import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/soft_card.dart';
import '../../auth/state/auth_controller.dart';
import 'settings_screen.dart' show confirmDeleteAccount, supportEmail;

/// Explains who can see a user's health data and offers the data-rights
/// actions (export request, account deletion).
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Who can see your health records',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only doctors you have booked or chatted with can open your '
                  'uploaded documents and visit history. Ask Musawo staff '
                  'never share your records with anyone else.',
                  style: TextStyle(color: muted, height: 1.4),
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
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Two-Factor Authentication'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/two-factor'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Request a copy of my data'),
                  subtitle: const Text('We email it to you within 30 days'),
                  onTap: () => launchUrl(
                    Uri(
                      scheme: 'mailto',
                      path: supportEmail,
                      query:
                          'subject=Data export request&body=Please send me a '
                          'copy of the data held for ${user?.email ?? 'my account'}.',
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Delete my account',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => confirmDeleteAccount(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
