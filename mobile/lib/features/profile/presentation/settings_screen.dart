import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../doctor/data/verification_repository.dart';
import '../../auth/data/app_user.dart';
import '../../auth/state/auth_controller.dart';
import '../state/profile_providers.dart';
import 'profile_screen.dart' show pushNotificationsPrefKey;
import '../../../core/widgets/user_avatar.dart';

const _emailPrefKey = 'notif_email';
const _smsPrefKey = 'notif_sms';
const supportEmail = 'care@askmusawo.co.ug';

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _push = true;
  bool _email = false;
  bool _sms = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _push = prefs.getBool(pushNotificationsPrefKey) ?? true;
      _email = prefs.getBool(_emailPrefKey) ?? false;
      _sms = prefs.getBool(_smsPrefKey) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _showHelp() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email support'),
              subtitle: const Text(supportEmail),
              onTap: () => launchUrl(Uri.parse('mailto:$supportEmail')),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authControllerProvider).value;
    final isDoctor = user?.role == 'doctor';
    final version = ref.watch(_appVersionProvider).value ?? '';

    if (!_loaded || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings'), centerTitle: true),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonCardList(count: 6, cardHeight: 56),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProfileCard(user: user),
          _Group(
            title: isDoctor ? 'Account' : 'Profile & Health',
            children: [
              _NavRow(
                icon: Icons.person_outline,
                label: 'Account Settings',
                onTap: () => context.push('/edit-profile'),
              ),
              if (!isDoctor)
                _NavRow(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Health Profile',
                  onTap: () => context.push('/settings/health-profile'),
                ),
              if (!isDoctor)
                _NavRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Are you a doctor? Apply',
                  onTap: () =>
                      ref.read(doctorSignupIntentProvider.notifier).set(true),
                ),
            ],
          ),
          _Group(
            title: 'Notifications',
            children: [
              _SwitchRow(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                value: _push,
                onChanged: (value) {
                  setState(() => _push = value);
                  _setPref(pushNotificationsPrefKey, value);
                },
              ),
              _SwitchRow(
                icon: Icons.email_outlined,
                label: 'Email Updates',
                value: _email,
                onChanged: (value) {
                  setState(() => _email = value);
                  _setPref(_emailPrefKey, value);
                },
              ),
              _SwitchRow(
                icon: Icons.smartphone,
                label: 'SMS Alerts',
                value: _sms,
                onChanged: (value) {
                  setState(() => _sms = value);
                  _setPref(_smsPrefKey, value);
                },
              ),
            ],
          ),
          _Group(
            title: 'Privacy & Security',
            children: [
              _NavRow(
                icon: Icons.lock_outline,
                label: 'Privacy Settings',
                onTap: () => context.push('/settings/privacy'),
              ),
              _NavRow(
                icon: Icons.verified_user_outlined,
                label: 'Two-Factor Authentication',
                value: user.twoFactorEnabled ? 'Enabled' : 'Disabled',
                onTap: () => context.push('/settings/two-factor'),
              ),
            ],
          ),
          _Group(
            title: isDoctor ? 'Practice & Financial' : 'Medical & Financial',
            children: [
              _NavRow(
                icon: Icons.calendar_today_outlined,
                label: 'Appointments History',
                onTap: () => context.go(
                  isDoctor ? '/doctor-home/appointments' : '/home/appointments',
                ),
              ),
              _NavRow(
                icon: Icons.credit_card_outlined,
                label: isDoctor ? 'Earnings & Payouts' : 'Payments & Billing',
                onTap: () => isDoctor
                    ? context.go('/doctor-home/earnings')
                    : context.push('/payments/history'),
              ),
            ],
          ),
          _Group(
            title: 'Preferences',
            children: [
              _SwitchRow(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: themeMode == ThemeMode.dark,
                onChanged: (value) =>
                    ref.read(themeModeProvider.notifier).setDarkMode(value),
              ),
            ],
          ),
          _Group(
            title: 'More',
            children: [
              _NavRow(
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: _showHelp,
              ),
              _NavRow(
                icon: Icons.info_outline,
                label: 'About Ask Musawo',
                value: version,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Ask Musawo',
                  applicationVersion: version,
                  applicationLegalese:
                      'Connecting patients with trusted doctors.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.dangerTint,
              foregroundColor: const Color(0xFFD32F2F),
              side: const BorderSide(color: Color(0xFFD32F2F)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => confirmDeleteAccount(context, ref),
              child: Text(
                'Delete Account',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}

/// Shared by Settings and Privacy Settings.
Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This permanently deletes your account and all associated data. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(profileRepositoryProvider).deleteMe();
    if (context.mounted) context.go('/login');
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final chips = <(IconData, String, bool)>[
      if (user.role == 'doctor') (Icons.verified_outlined, 'Verified', false),
      if (user.twoFactorEnabled) (Icons.shield_outlined, '2FA on', false),
      if (user.hasInsurance)
        (Icons.health_and_safety_outlined, user.insuranceProvider!, false),
      if (user.bloodgroup != null)
        (Icons.bloodtype_outlined, '${user.bloodgroup} Blood', true),
    ];
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(url: user.image, kind: AvatarKind.self, radius: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phoneNumber?.isNotEmpty == true
                          ? user.phoneNumber!
                          : user.email,
                      style: TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.push('/edit-profile'),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (icon, label, alert) in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: alert ? const Color(0xFFD32F2F) : null,
                      border: alert
                          ? null
                          : Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                      borderRadius: BorderRadius.circular(kPillRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: alert ? Colors.white : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: alert ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 52),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      leading: Icon(icon, color: muted),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null && value!.isNotEmpty)
            Text(value!, style: TextStyle(color: muted, fontSize: 13)),
          Icon(Icons.chevron_right, color: muted),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
