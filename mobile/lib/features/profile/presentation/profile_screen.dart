import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_gate.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/data/app_user.dart';
import '../../auth/state/auth_controller.dart';
import '../state/profile_providers.dart';
import 'upload_document_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final isDoctor = userAsync.value?.role == 'doctor';

    // The patient-only sections each have their own provider; only wait on
    // them when they'll actually be shown, so a doctor's profile doesn't
    // block on providers it never queries.
    final patientOnlyAsyncs = isDoctor
        ? const <AsyncValue<Object?>>[]
        : [
            ref.watch(myConsultationHistoryProvider),
            ref.watch(myPrescriptionsProvider),
            ref.watch(myActiveInvoiceProvider),
            ref.watch(myMedicalDocumentsProvider),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: DashboardGate(
        values: [userAsync, ...patientOnlyAsyncs],
        loadingBuilder: (context) => const _ProfileSkeleton(),
        builder: (context) {
          final user = userAsync.value;
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Header(user: user),
              const SizedBox(height: 24),
              if (user.role == 'doctor')
                ..._doctorSections(context, user)
              else
                ..._patientSections(context, ref),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          );
        },
        errorBuilder: (context, error) => Center(child: Text(error.toString())),
      ),
    );
  }

  List<Widget> _doctorSections(BuildContext context, AppUser user) {
    return [
      _SectionCard(
        title: 'About',
        child: Text(
          user.bio?.isNotEmpty == true ? user.bio! : 'No bio added yet.',
        ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Hospital',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.hospitalName ?? 'Not set'),
            if (user.hospitalAddress != null)
              Text(
                user.hospitalAddress!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Consultation Fee',
        child: Text(
          user.consultationFee != null
              ? 'UGX ${user.consultationFee}'
              : 'Not set',
        ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Reviews & Ratings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'See what patients are saying and reply to their reviews.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.reviews_outlined),
              label: const Text('Manage Reviews'),
              onPressed: () => context.push('/doctor-home/reviews'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _patientSections(BuildContext context, WidgetRef ref) {
    return [
      _HealthSnapshotSection(),
      const SizedBox(height: 16),
      _PersonalInfoSection(),
      const SizedBox(height: 16),
      _ConsultationHistorySection(),
      const SizedBox(height: 16),
      _PrescriptionsSection(),
      const SizedBox(height: 16),
      _BillingSection(),
      const SizedBox(height: 16),
      _MedicalDocumentsSection(),
      const SizedBox(height: 16),
      _EmergencyContactSection(),
      const SizedBox(height: 16),
      const _PreferencesSection(),
    ];
  }
}

/// Mirrors [ProfileScreen]'s real layout — avatar header, then a stack of
/// section cards — so the first-load wait reads as "this page is here,
/// filling in" rather than a generic spinner.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Center(
          child: Column(
            children: [
              const SkeletonBox.circle(size: 80),
              const SizedBox(height: 12),
              const SkeletonBox(width: 140, height: 18),
              const SizedBox(height: 6),
              const SkeletonBox(width: 180, height: 13),
              const SizedBox(height: 12),
              const SkeletonBox(
                width: 120,
                height: 34,
                borderRadius: kCardRadius,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonBox(
              width: double.infinity,
              height: 90,
              borderRadius: kCardRadius,
            ),
          ),
        ),
      ],
    );
  }
}

/// Short, stable, human-readable member ID derived from the user id.
String memberIdFor(AppUser user) {
  final year = (user.createdAt ?? DateTime.now()).year;
  final tail = user.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  final code = tail.length > 5 ? tail.substring(tail.length - 5) : tail;
  return 'AM-$year-${code.toUpperCase()}';
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  void _share() {
    final lines = [
      user.name,
      'Ask Musawo ID: ${memberIdFor(user)}',
      if (user.bloodgroup != null) 'Blood group: ${user.bloodgroup}',
      if (user.age != null) 'Age: ${user.age}',
      if (user.gender != null) 'Gender: ${user.gender}',
      if (user.hasInsurance)
        'Insurance: ${user.insuranceProvider}'
            '${user.insuranceMemberNo?.isNotEmpty == true ? ' (${user.insuranceMemberNo})' : ''}',
      if (user.emergencyContactName != null)
        'Emergency contact: ${user.emergencyContactName}'
            '${user.emergencyContactPhone != null ? ', ${user.emergencyContactPhone}' : ''}',
    ];
    SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final idLine = [
      if (user.role != 'doctor') 'ID: ${memberIdFor(user)}',
      if (user.createdAt != null)
        'Joined ${DateFormat('MMM yyyy').format(user.createdAt!)}',
    ].join('  •  ');
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user.image != null
              ? NetworkImage(user.image!)
              : null,
          child: user.image == null ? const Icon(Icons.person, size: 36) : null,
        ),
        const SizedBox(height: 12),
        Text(user.name, style: Theme.of(context).textTheme.titleLarge),
        if (idLine.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(idLine, style: TextStyle(color: muted, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Profile'),
                onPressed: () => context.push('/edit-profile'),
              ),
            ),
            if (user.role != 'doctor') ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text('Share Profile'),
                  onPressed: _share,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _HealthSnapshotSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final user = userAsync.value;
    // Primary doctor = the doctor seen most often in completed visits.
    final history = ref.watch(myConsultationHistoryProvider).value ?? const [];
    final counts = <String, int>{};
    for (final a in history) {
      counts[a.doctorName] = (counts[a.doctorName] ?? 0) + 1;
    }
    final primaryName = counts.isEmpty
        ? null
        : (counts.entries.toList()..sort((a, b) => b.value - a.value))
              .first
              .key;
    final primary = primaryName == null
        ? null
        : history.firstWhere((a) => a.doctorName == primaryName);
    return _SectionCard(
      title: 'Health Snapshot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _snapshotItem('Blood Group', user?.bloodgroup ?? '—'),
              ),
              Expanded(child: _snapshotItem('Age', user?.age ?? '—')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _snapshotItem('Gender', user?.gender ?? '—')),
              Expanded(
                child: _snapshotItem(
                  'Insurance',
                  user?.hasInsurance == true
                      ? user!.insuranceProvider!
                      : 'None',
                ),
              ),
            ],
          ),
          if (primary != null) ...[
            const Divider(height: 24),
            InkWell(
              onTap: primary.doctorId == null
                  ? null
                  : () => context.push('/doctors/${primary.doctorId}'),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: seedTeal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _snapshotItem('Primary Doctor', primary.doctorName),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _snapshotItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ConsultationHistorySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(myConsultationHistoryProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return _SectionCard(
      title: 'Consultation History',
      child: historyAsync.when(
        data: (history) {
          if (history.isEmpty) return const Text('No past consultations yet.');
          return Column(
            children: history
                .take(3)
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(a.doctorName),
                        Text(
                          dateFormat.format(a.date),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (error, _) => Text(error.toString()),
      ),
    );
  }
}

class _PrescriptionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(myPrescriptionsProvider);

    return _SectionCard(
      title: 'Prescriptions',
      child: prescriptionsAsync.when(
        data: (prescriptions) {
          if (prescriptions.isEmpty) return const Text('No prescriptions yet.');
          return Column(
            children: prescriptions
                .take(5)
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p.items.isNotEmpty
                                  ? p.items.first.medicationName
                                  : 'Prescription',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Chip(
                              label: Text(
                                p.status,
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: p.isActive
                                  ? Colors.green.shade100
                                  : null,
                            ),
                          ],
                        ),
                        if (p.items.isNotEmpty)
                          Text(
                            p.items.first.dosage,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (error, _) => Text(error.toString()),
      ),
    );
  }
}

class _BillingSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(myActiveInvoiceProvider);

    return _SectionCard(
      title: 'Payment & Billing',
      child: invoiceAsync.when(
        data: (invoice) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Outstanding Balance'),
            Text(
              invoice != null ? 'UGX ${invoice.totalAmount}' : 'UGX 0',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const Text('UGX 0'),
      ),
    );
  }
}

class _MedicalDocumentsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(myMedicalDocumentsProvider);

    return _SectionCard(
      title: 'Health Documents',
      trailing: TextButton.icon(
        icon: const Icon(Icons.upload_outlined, size: 16),
        label: const Text('Upload'),
        onPressed: () => showUploadDocumentDialog(context, ref),
      ),
      child: documentsAsync.when(
        data: (documents) {
          if (documents.isEmpty)
            return const Text('No documents uploaded yet.');
          return Column(
            children: documents
                .map(
                  (d) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(d.title),
                    onTap: () => launchUrl(Uri.parse(d.url)),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (error, _) => Text(error.toString()),
      ),
    );
  }
}

class _EmergencyContactSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user?.emergencyContactName == null) {
      return _SectionCard(
        title: 'Emergency Contact',
        child: Text(
          'Not set. Add one from Edit Profile.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    return _SectionCard(
      title: 'Emergency Contact',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user!.emergencyContactName!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (user.emergencyContactRelation != null)
            Text(user.emergencyContactRelation!),
          if (user.emergencyContactPhone != null)
            Text(user.emergencyContactPhone!),
        ],
      ),
    );
  }
}

class _PersonalInfoSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();
    Widget row(String label, String? value) => InkWell(
      onTap: () => context.push('/edit-profile'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value?.isNotEmpty == true ? value! : 'Not set',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
    return _SectionCard(
      title: 'Personal Information',
      child: Column(
        children: [
          row('Email Address', user.email),
          row('Phone Number', user.phoneNumber),
          row('Location', user.address),
        ],
      ),
    );
  }
}

/// Keys shared with the Settings screen so both toggles stay in sync.
const pushNotificationsPrefKey = 'notif_push';
const healthTipsPrefKey = 'notif_health_tips';

class _PreferencesSection extends StatefulWidget {
  const _PreferencesSection();

  @override
  State<_PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<_PreferencesSection> {
  bool? _push;
  bool? _tips;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _push = prefs.getBool(pushNotificationsPrefKey) ?? true;
        _tips = prefs.getBool(healthTipsPrefKey) ?? false;
      });
    });
  }

  Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_push == null) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Preferences',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            value: _push!,
            onChanged: (value) {
              setState(() => _push = value);
              _set(pushNotificationsPrefKey, value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.monitor_heart_outlined),
            title: const Text('Health Insights & Tips'),
            value: _tips!,
            onChanged: (value) {
              setState(() => _tips = value);
              _set(healthTipsPrefKey, value);
            },
          ),
        ],
      ),
    );
  }
}
