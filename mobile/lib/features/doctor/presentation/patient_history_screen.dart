import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../labs/presentation/lab_results_screen.dart' show LabResultCard;
import '../../labs/presentation/order_lab_test_sheet.dart';
import '../../profile/data/medical_document.dart';
import '../data/patient_history.dart';
import '../state/doctor_providers.dart';
import '../../../core/widgets/user_avatar.dart';

final _dateFormat = DateFormat('d MMM yyyy');

/// Extensions that are definitely not pictures. Everything else is tried as
/// an image, since hosted uploads (UploadThing, Unsplash) have no extension;
/// a failed load falls back to a file tile.
const _documentExtensions = [
  '.pdf',
  '.doc',
  '.docx',
  '.xls',
  '.xlsx',
  '.ppt',
  '.pptx',
  '.txt',
  '.csv',
  '.zip',
];

bool _isImage(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return !_documentExtensions.any(path.endsWith);
}

/// A doctor's "Full History" of one patient: health facts, every document the
/// patient uploaded, and past visits with this doctor.
class PatientHistoryScreen extends ConsumerWidget {
  const PatientHistoryScreen({super.key, required this.patientId});

  final String patientId;

  void _share(PatientHistory history) {
    final lines = [
      'Patient: ${history.name}',
      if (history.age != null) 'Age: ${history.age}',
      if (history.gender != null) 'Gender: ${history.gender}',
      if (history.bloodGroup != null) 'Blood group: ${history.bloodGroup}',
      if (history.medicalHistory?.isNotEmpty == true)
        'Medical history: ${history.medicalHistory}',
      if (history.documents.isNotEmpty) '',
      for (final d in history.documents)
        '${d.title} (${_dateFormat.format(d.createdAt)}): ${d.url}',
    ];
    SharePlus.instance.share(
      ShareParams(text: lines.join('\n'), subject: '${history.name} — history'),
    );
  }

  Future<void> _orderLabTest(
    BuildContext context,
    WidgetRef ref,
    PatientHistory history,
  ) async {
    final ordered = await showOrderLabTestSheet(
      context,
      patientId: history.patientId,
      patientName: history.name,
    );
    if (!ordered) return;
    ref.invalidate(patientHistoryProvider(patientId));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lab test ordered')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(patientHistoryProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share',
            onPressed: historyAsync.hasValue
                ? () => _share(historyAsync.value!)
                : null,
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const SkeletonList(count: 5),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(patientHistoryProvider(patientId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (history) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(patientHistoryProvider(patientId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _PatientHeader(history: history),
              const SizedBox(height: 24),
              _SectionTitle('Documents', count: history.documents.length),
              const SizedBox(height: 8),
              if (history.documents.isEmpty)
                const _Empty('No documents uploaded yet.')
              else
                for (final document in history.documents) ...[
                  _DocumentCard(document: document),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SectionTitle(
                      'Lab results',
                      count: history.labResults.length,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _orderLabTest(context, ref, history),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Order test'),
                  ),
                ],
              ),
              if (history.labResults.isEmpty)
                const _Empty('No lab tests yet.')
              else
                for (final r in history.labResults) ...[
                  LabResultCard(result: r, showAi: true),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              _SectionTitle('Visits with you', count: history.visits.length),
              const SizedBox(height: 8),
              if (history.visits.isEmpty)
                const _Empty('No appointments yet.')
              else
                for (final visit in history.visits) ...[
                  _VisitTile(visit: visit),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.history});

  final PatientHistory history;

  @override
  Widget build(BuildContext context) {
    final facts = [
      if (history.age != null) '${history.age} yrs',
      if (history.gender != null) history.gender!,
      if (history.bloodGroup != null) history.bloodGroup!,
    ];
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                url: history.image,
                gender: history.gender,
                radius: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final fact in facts)
                            Chip(
                              label: Text(fact),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (history.medicalHistory?.isNotEmpty == true) ...[
            const Divider(height: 24),
            Text(
              'Medical history',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(history.medicalHistory!),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      count > 0 ? '$title ($count)' : title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final MedicalDocument document;

  void _open(BuildContext context) {
    if (_isImage(document.url)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _ImageViewer(document: document),
        ),
      );
    } else {
      launchUrl(Uri.parse(document.url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = _isImage(document.url);
    return SoftCard(
      padding: EdgeInsets.zero,
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isImage)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: AppNetworkImage(document.url),
            ),
          ListTile(
            leading: Icon(
              isImage ? Icons.image_outlined : Icons.description_outlined,
              color: seedTeal,
            ),
            title: Text(document.title),
            subtitle: Text(_dateFormat.format(document.createdAt)),
            trailing: Icon(isImage ? Icons.fullscreen : Icons.open_in_new),
          ),
        ],
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.document});

  final MedicalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(document.title),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: AppNetworkImage(document.url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit});

  final PatientVisit visit;

  @override
  Widget build(BuildContext context) {
    final type = switch (visit.consultationType) {
      'physical' => 'In-person',
      'voice' => 'Voice call',
      'video' => 'Video call',
      _ => 'Consultation',
    };
    final details = [
      visit.reason,
      visit.notes,
    ].whereType<String>().where((t) => t.isNotEmpty).join('\n');
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_dateFormat.format(visit.date)}'
                  '${visit.time != null ? ' · ${visit.time}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                visit.status.replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(type, style: const TextStyle(color: seedTeal, fontSize: 13)),
          if (details.isNotEmpty) ...[const SizedBox(height: 6), Text(details)],
        ],
      ),
    );
  }
}
