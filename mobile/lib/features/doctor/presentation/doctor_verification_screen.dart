import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/realtime/socket_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/loading_dots.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/state/auth_controller.dart';
import '../../doctors/state/doctor_providers.dart';
import '../data/verification_repository.dart';

const _muted = Color(0xFF6B7A7A);

/// Where a doctor proves they're licensed before patients can find them:
/// Uganda Medical and Dental Practitioners Council licence number, the
/// licensed facility they practise at, and a photo or PDF of the licence.
///
/// The router keeps unverified doctors here (see app_router.dart). A new
/// account that chose "Doctor" on Register also lands here, still a
/// patient until it submits — [_submit] then applies and submits in one go.
class DoctorVerificationScreen extends ConsumerStatefulWidget {
  const DoctorVerificationScreen({super.key});

  @override
  ConsumerState<DoctorVerificationScreen> createState() =>
      _DoctorVerificationScreenState();
}

class _DoctorVerificationScreenState
    extends ConsumerState<DoctorVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _facilityController = TextEditingController();
  final _addressController = TextEditingController();
  final _yearsController = TextEditingController();
  String? _specialty;
  String? _documentUrl;
  bool _uploading = false;
  bool _submitting = false;
  bool _prefilled = false;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;

  @override
  void initState() {
    super.initState();
    // An admin's decision arrives as a live notification — pick it up
    // straight away so an approval opens the doctor dashboard by itself.
    _notificationSub = ref
        .read(socketServiceProvider)
        .notifications
        .listen((_) => _refresh());
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _licenseController.dispose();
    _facilityController.dispose();
    _addressController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(myVerificationProvider);
    await ref.read(authControllerProvider.notifier).refreshUser();
  }

  void _prefill(DoctorVerification v) {
    if (_prefilled) return;
    _prefilled = true;
    _licenseController.text = v.licenseNumber ?? '';
    _facilityController.text = v.hospitalName ?? '';
    _addressController.text = v.hospitalAddress ?? '';
    _yearsController.text = v.yearsOfExperience?.toString() ?? '';
    _specialty = v.specialization;
    _documentUrl = v.licenseDocumentUrl;
  }

  Future<void> _pickDocument() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose a photo'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Choose a PDF'),
              onTap: () => Navigator.of(context).pop('pdf'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    // Read as bytes rather than a file path so this works on every
    // platform (the web build has no file system).
    Uint8List? bytes;
    String? filename;
    if (choice == 'pdf') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      final file = result?.files.single;
      bytes = file?.bytes;
      filename = file?.name;
    } else {
      final picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      bytes = await picked?.readAsBytes();
      filename = picked?.name;
    }
    if (bytes == null || filename == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(uploadRepositoryProvider)
          .uploadBytes(bytes, filename: filename);
      if (mounted) setState(() => _documentUrl = url);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_documentUrl == null) {
      _showError('Add a photo or PDF of your practising licence.');
      return;
    }
    setState(() => _submitting = true);
    final repo = ref.read(verificationRepositoryProvider);
    try {
      final me = ref.read(authControllerProvider).value;
      if (me != null && !me.isDoctor) {
        await repo.apply(specialization: _specialty!);
      }
      await repo.submit(
        licenseNumber: _licenseController.text.trim(),
        licenseDocumentUrl: _documentUrl!,
        hospitalName: _facilityController.text.trim(),
        hospitalAddress: _addressController.text.trim(),
        specialization: _specialty,
        yearsOfExperience: int.tryParse(_yearsController.text.trim()),
      );
      ref.read(doctorSignupIntentProvider.notifier).set(false);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Submitted. We'll let you know once an admin has checked it.",
            ),
          ),
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _continueAsPatient() {
    ref.read(doctorSignupIntentProvider.notifier).set(false);
    context.go('/home');
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : error.toString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).value;
    final applying = me != null && !me.isDoctor;
    final verificationAsync = ref.watch(myVerificationProvider);

    return Scaffold(
      backgroundColor: tealBackground,
      appBar: AppBar(
        title: const Text('Verify your licence'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(doctorSignupIntentProvider.notifier).set(false);
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: verificationAsync.when(
        loading: () => const SkeletonForm(fieldCount: 5),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed: _refresh, child: const Text('Try again')),
              ],
            ),
          ),
        ),
        data: (verification) {
          _prefill(verification);
          final locked =
              verification.status == 'pending' && verification.isSubmitted;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _StatusCard(verification: verification, applying: applying),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: _fields(locked: locked),
                ),
                const SizedBox(height: 24),
                if (!locked)
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _submitting || _uploading ? null : _submit,
                      child: _submitting
                          ? const LoadingDots()
                          : Text(
                              verification.isSubmitted
                                  ? 'Resubmit for review'
                                  : 'Submit for review',
                            ),
                    ),
                  ),
                if (applying) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _submitting ? null : _continueAsPatient,
                    child: const Text('Continue as a patient instead'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fields({required bool locked}) {
    final specialties = ref.watch(categoriesProvider).value ?? const [];
    final names = [for (final c in specialties) c.name];
    // Keep a stored specialty selectable even if the category was renamed.
    if (_specialty != null && !names.contains(_specialty)) {
      names.insert(0, _specialty!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _specialty,
          decoration: const InputDecoration(labelText: 'Specialty'),
          items: [
            for (final name in names)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: locked ? null : (v) => setState(() => _specialty = v),
          validator: (v) => v == null ? 'Choose your specialty' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _licenseController,
          enabled: !locked,
          decoration: const InputDecoration(
            labelText: 'UMDPC licence number',
            helperText:
                'From your Uganda Medical and Dental Practitioners Council '
                'practising licence',
            helperMaxLines: 2,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _facilityController,
          enabled: !locked,
          decoration: const InputDecoration(
            labelText: 'Licensed facility you practise at',
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          enabled: !locked,
          decoration: const InputDecoration(labelText: 'Facility address'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _yearsController,
          enabled: !locked,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Years of experience'),
        ),
        const SizedBox(height: 20),
        Text(
          'Practising licence',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _DocumentTile(
          url: _documentUrl,
          uploading: _uploading,
          onTap: locked || _uploading ? null : _pickDocument,
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.verification, required this.applying});

  final DoctorVerification verification;
  final bool applying;

  @override
  Widget build(BuildContext context) {
    final submitted = verification.isSubmitted;
    final (
      IconData icon,
      Color color,
      String title,
      String body,
    ) = switch (verification.status) {
      'rejected' => (
        Icons.error_outline,
        const Color(0xFFD32F2F),
        'Licence not approved',
        '${verification.note ?? 'The admin needs more information.'} '
            'Update the details below and resubmit.',
      ),
      'pending' when submitted => (
        Icons.hourglass_top_rounded,
        const Color(0xFFFF9800),
        'Under review',
        'Submitted ${DateFormat('d MMM yyyy').format(verification.submittedAt!)}. '
            "We'll notify you as soon as an admin has checked your "
            'licence. Patients can find and book you once it is approved.',
      ),
      _ => (
        Icons.verified_user_outlined,
        seedTeal,
        applying ? 'Join as a doctor' : 'Verify your licence',
        'Every doctor on Ask Musawo is licensed to practise in Uganda. '
            'Send us your licence and the facility you practise at. An '
            'admin checks them before patients can book you.',
      ),
    };

    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: darkTealBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: _muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.url,
    required this.uploading,
    required this.onTap,
  });

  final String? url;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    final isPdf = url != null && url.toLowerCase().endsWith('.pdf');

    Widget content;
    if (uploading) {
      content = const SizedBox(
        height: 140,
        child: Center(child: LoadingDots(color: seedTeal)),
      );
    } else if (url == null) {
      content = const SizedBox(
        height: 140,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined, color: seedTeal, size: 32),
            SizedBox(height: 8),
            Text(
              'Add a photo or PDF',
              style: TextStyle(color: seedTeal, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    } else if (isPdf) {
      content = const SizedBox(
        height: 72,
        child: Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.picture_as_pdf_outlined, color: seedTeal, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Licence PDF attached')),
            Icon(Icons.swap_horiz, color: _muted),
            SizedBox(width: 16),
          ],
        ),
      );
    } else {
      content = SizedBox(height: 180, child: AppNetworkImage(url));
    }

    return SoftCard(padding: EdgeInsets.zero, onTap: onTap, child: content);
  }
}
