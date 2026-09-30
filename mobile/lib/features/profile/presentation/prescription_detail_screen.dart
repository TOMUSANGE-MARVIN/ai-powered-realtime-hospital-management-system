import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/loading_dots.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/state/auth_controller.dart';
import '../data/patient_prescription.dart';
import '../data/prescription_pdf.dart';
import '../state/profile_providers.dart';

final _date = DateFormat('d MMM yyyy');

/// Status fill colours from the app's palette (see mobile-ui-style rules).
Color _statusColor(String status) => switch (status) {
  'dispensed' => const Color(0xFF0B5F60),
  'cancelled' => const Color(0xFFD32F2F),
  _ => seedTeal,
};

/// All of the patient's prescriptions, newest first.
class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptions = ref.watch(myPrescriptionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Prescriptions')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myPrescriptionsProvider.future),
        child: prescriptions.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonCardList(count: 4, cardHeight: 84),
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [Text(error.toString(), textAlign: TextAlign.center)],
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    Text(
                      'No prescriptions yet. When a doctor sends you one it '
                      'will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => PrescriptionTile(rx: list[i]),
                ),
        ),
      ),
    );
  }
}

/// One prescription as a card row — used on Profile and the full list.
class PrescriptionTile extends StatelessWidget {
  const PrescriptionTile({super.key, required this.rx, this.card = true});

  final PatientPrescription rx;

  /// false when shown inside another card (Profile section).
  final bool card;

  @override
  Widget build(BuildContext context) {
    final title = rx.items.isEmpty
        ? 'Prescription'
        : rx.items.length == 1
        ? rx.items.first.medicationName
        : '${rx.items.first.medicationName} +${rx.items.length - 1} more';
    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                '${rx.doctorName} · ${_date.format(rx.issuedOn)}',
                style: TextStyle(color: context.palette.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        _StatusBadge(status: rx.status, label: rx.statusLabel),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: context.palette.muted),
      ],
    );
    void open() => context.push('/prescriptions/${rx.id}');
    if (!card) {
      return InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: row,
        ),
      );
    }
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      onTap: open,
      child: row,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _statusColor(status),
      borderRadius: BorderRadius.circular(kCardRadius),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// One prescription in full: prescriber, date, diagnosis / notes, every
/// medicine, signature — and a PDF to take or send to a pharmacy.
class PrescriptionDetailScreen extends ConsumerStatefulWidget {
  const PrescriptionDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState
    extends ConsumerState<PrescriptionDetailScreen> {
  bool _sharing = false;

  Future<void> _sharePdf(PatientPrescription rx) async {
    setState(() => _sharing = true);
    try {
      final bytes = await buildPrescriptionPdf(
        rx: rx,
        patient: ref.read(authControllerProvider).value,
        dio: ref.read(dioProvider),
      );
      final name =
          'Prescription-${DateFormat('yyyy-MM-dd').format(rx.issuedOn)}.pdf';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
          fileNameOverrides: [name],
          subject: 'Prescription from ${rx.doctorName}',
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't create the PDF: $error")),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prescriptions = ref.watch(myPrescriptionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: prescriptions.when(
        loading: () => const SkeletonForm(fieldCount: 4),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (list) {
          final rx = list.where((p) => p.id == widget.id).firstOrNull;
          if (rx == null) {
            return const Center(child: Text('Prescription not found.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(rx: rx),
              const SizedBox(height: 12),
              if (rx.notes != null && rx.notes!.trim().isNotEmpty) ...[
                _Section(
                  title: 'Diagnosis / notes',
                  child: Text(
                    rx.notes!.trim(),
                    style: const TextStyle(height: 1.45),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _Section(
                title: 'Medicines',
                child: rx.items.isEmpty
                    ? const Text('See the prescription image below.')
                    : Column(
                        children: [
                          for (var i = 0; i < rx.items.length; i++) ...[
                            if (i > 0) const Divider(height: 20),
                            _MedicineRow(item: rx.items[i]),
                          ],
                        ],
                      ),
              ),
              if (rx.imageUrl != null) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Prescription image',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    child: AppNetworkImage(rx.imageUrl!, fit: BoxFit.contain),
                  ),
                ),
              ],
              if (rx.signatureUrl != null) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Signed by',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 64,
                        child: AppNetworkImage(
                          rx.signatureUrl!,
                          fit: BoxFit.contain,
                          error: const SizedBox.shrink(),
                        ),
                      ),
                      Text(rx.doctorName),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: prescriptions.value
          ?.where((p) => p.id == widget.id)
          .map(
            (rx) => SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : () => _sharePdf(rx),
                  icon: _sharing
                      ? const LoadingDots()
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Download or share PDF'),
                ),
              ),
            ),
          )
          .firstOrNull,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.rx});

  final PatientPrescription rx;

  @override
  Widget build(BuildContext context) {
    final facility = [
      rx.doctorFacility,
      rx.doctorFacilityAddress,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rx.doctorName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.palette.ink,
                  ),
                ),
              ),
              _StatusBadge(status: rx.status, label: rx.statusLabel),
            ],
          ),
          if (rx.doctorSpecialization != null)
            Text(
              rx.doctorSpecialization!,
              style: TextStyle(color: context.palette.muted),
            ),
          const SizedBox(height: 12),
          _Fact(
            icon: Icons.event_outlined,
            text: 'Issued ${_date.format(rx.issuedOn)}',
          ),
          if (rx.status == 'dispensed' && rx.dispensedAt != null)
            _Fact(
              icon: Icons.local_pharmacy_outlined,
              text: 'Dispensed ${_date.format(rx.dispensedAt!)}',
            ),
          if (rx.licenseNo != null)
            _Fact(
              icon: Icons.verified_outlined,
              text: 'UMDPC licence ${rx.licenseNo}',
            ),
          if (facility.isNotEmpty)
            _Fact(icon: Icons.local_hospital_outlined, text: facility),
          _Fact(icon: Icons.tag, text: rx.id),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: seedTeal),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.palette.ink,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.item});

  final PatientPrescriptionItem item;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.palette.tint,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.medication_outlined, color: seedTeal, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.medicationName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.dosage} · Qty ${item.quantity}',
              style: TextStyle(color: context.palette.muted, fontSize: 13),
            ),
            if (item.instructions != null && item.instructions!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.instructions!, style: const TextStyle(fontSize: 13.5)),
            ],
          ],
        ),
      ),
    ],
  );
}
