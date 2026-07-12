import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/data/app_user.dart';
import '../../auth/state/auth_controller.dart';
import '../state/profile_providers.dart';
import 'upload_document_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);

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
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Header(user: user),
              const SizedBox(height: 24),
              if (user.role == 'doctor') ..._doctorSections(context, user) else ..._patientSections(context, ref),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  List<Widget> _doctorSections(BuildContext context, AppUser user) {
    return [
      _SectionCard(
        title: 'About',
        child: Text(user.bio?.isNotEmpty == true ? user.bio! : 'No bio added yet.'),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Hospital',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.hospitalName ?? 'Not set'),
            if (user.hospitalAddress != null) Text(user.hospitalAddress!, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Consultation Fee',
        child: Text(user.consultationFee != null ? 'UGX ${user.consultationFee}' : 'Not set'),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Reviews & Ratings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('See what patients are saying and reply to their reviews.'),
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
      _ConsultationHistorySection(),
      const SizedBox(height: 16),
      _PrescriptionsSection(),
      const SizedBox(height: 16),
      _BillingSection(),
      const SizedBox(height: 16),
      _MedicalDocumentsSection(),
      const SizedBox(height: 16),
      _EmergencyContactSection(),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user.image != null ? NetworkImage(user.image!) : null,
          child: user.image == null ? const Icon(Icons.person, size: 36) : null,
        ),
        const SizedBox(height: 12),
        Text(user.name, style: Theme.of(context).textTheme.titleLarge),
        Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit Profile'),
          onPressed: () => context.push('/edit-profile'),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    return _SectionCard(
      title: 'Health Snapshot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _snapshotItem('Blood Group', user?.bloodgroup ?? '—')),
              Expanded(child: _snapshotItem('Age', user?.age ?? '—')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _snapshotItem('Gender', user?.gender ?? '—')),
              Expanded(child: _snapshotItem('Marital Status', user?.maritalStatus ?? '—')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _snapshotItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
                        Text(dateFormat.format(a.date), style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const LinearProgressIndicator(),
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
                              p.items.isNotEmpty ? p.items.first.medicationName : 'Prescription',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Chip(
                              label: Text(p.status, style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: p.isActive ? Colors.green.shade100 : null,
                            ),
                          ],
                        ),
                        if (p.items.isNotEmpty)
                          Text(p.items.first.dosage, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const LinearProgressIndicator(),
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
        loading: () => const LinearProgressIndicator(),
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
          if (documents.isEmpty) return const Text('No documents uploaded yet.');
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
        loading: () => const LinearProgressIndicator(),
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
        child: Text('Not set. Add one from Edit Profile.', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return _SectionCard(
      title: 'Emergency Contact',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user!.emergencyContactName!, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (user.emergencyContactRelation != null) Text(user.emergencyContactRelation!),
          if (user.emergencyContactPhone != null) Text(user.emergencyContactPhone!),
        ],
      ),
    );
  }
}
