import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/loading_dots.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/state/auth_controller.dart';
import '../data/prescription_item_input.dart';
import '../state/doctor_providers.dart';
import '../../../core/widgets/user_avatar.dart';

final _dateFormat = DateFormat('MMM d, yyyy');

/// Doctor photographs (or types up) a prescription, checks the details the
/// AI read from it, signs, and sends it to the patient. Unsent work can be
/// kept as a draft on this device.
class NewPrescriptionScreen extends ConsumerStatefulWidget {
  const NewPrescriptionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.appointmentId,
  });

  final String patientId;
  final String patientName;
  final String? appointmentId;

  @override
  ConsumerState<NewPrescriptionScreen> createState() =>
      _NewPrescriptionScreenState();
}

class _MedicationRow {
  _MedicationRow([PrescriptionItemInput? item])
    : nameController = TextEditingController(text: item?.medicationName),
      dosageController = TextEditingController(text: item?.dosage),
      quantityController = TextEditingController(
        text: '${item?.quantity ?? 1}',
      ),
      instructionsController = TextEditingController(text: item?.instructions);

  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController quantityController;
  final TextEditingController instructionsController;

  bool get isEmpty => nameController.text.trim().isEmpty;

  PrescriptionItemInput toInput() => PrescriptionItemInput(
    medicationName: nameController.text.trim(),
    dosage: dosageController.text.trim(),
    quantity: int.tryParse(quantityController.text) ?? 1,
    instructions: instructionsController.text.trim().isEmpty
        ? null
        : instructionsController.text.trim(),
  );

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    quantityController.dispose();
    instructionsController.dispose();
  }
}

enum _PhotoState { none, uploading, reading, ready }

class _NewPrescriptionScreenState extends ConsumerState<NewPrescriptionScreen> {
  final _notesController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _patientNameController = TextEditingController();
  final List<_MedicationRow> _rows = [_MedicationRow()];
  final _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  File? _photo;
  String? _photoUrl;
  bool? _goodQuality;
  _PhotoState _photoState = _PhotoState.none;
  DateTime? _dateIssued;
  bool _confirmed = false;
  bool _submitting = false;

  String get _draftKey => 'rx_draft_${widget.patientId}';

  @override
  void initState() {
    super.initState();
    _doctorNameController.text =
        ref.read(authControllerProvider).value?.name ?? '';
    _patientNameController.text = widget.patientName;
    _dateIssued = DateUtils.dateOnly(DateTime.now());
    _restoreDraft();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _doctorNameController.dispose();
    _licenseController.dispose();
    _patientNameController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    _signatureController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Drafts (kept on this device only) ---

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || !mounted) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _notesController.text = data['notes'] as String? ?? '';
      _doctorNameController.text =
          data['doctorName'] as String? ?? _doctorNameController.text;
      _licenseController.text = data['licenseNo'] as String? ?? '';
      _patientNameController.text =
          data['patientName'] as String? ?? widget.patientName;
      _dateIssued =
          DateTime.tryParse(data['dateIssued'] as String? ?? '') ?? _dateIssued;
      _photoUrl = data['photoUrl'] as String?;
      if (_photoUrl != null) _photoState = _PhotoState.ready;
      final meds = (data['medications'] as List? ?? const [])
          .map(
            (m) => PrescriptionItemInput(
              medicationName: m['medicationName'] as String? ?? '',
              dosage: m['dosage'] as String? ?? '',
              quantity: (m['quantity'] as num?)?.toInt() ?? 1,
              instructions: m['instructions'] as String?,
            ),
          )
          .toList();
      if (meds.isNotEmpty) _replaceRows(meds);
    });
    _toast('Draft restored');
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftKey,
      jsonEncode({
        'notes': _notesController.text,
        'doctorName': _doctorNameController.text,
        'licenseNo': _licenseController.text,
        'patientName': _patientNameController.text,
        'dateIssued': _dateIssued?.toIso8601String(),
        'photoUrl': _photoUrl,
        'medications': [
          for (final row in _rows)
            if (!row.isEmpty) row.toInput().toJson(),
        ],
      }),
    );
    if (mounted) _toast('Draft saved on this device');
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  // --- Photo ---

  void _replaceRows(List<PrescriptionItemInput> items) {
    for (final row in _rows) {
      row.dispose();
    }
    _rows
      ..clear()
      ..addAll(items.map(_MedicationRow.new));
    if (_rows.isEmpty) _rows.add(_MedicationRow());
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _usePhoto(File(picked.path));
  }

  /// Uploads [file] and asks the server to read it, filling in any field
  /// the doctor hasn't typed yet.
  Future<void> _usePhoto(File file) async {
    setState(() {
      _photo = file;
      _photoUrl = null;
      _goodQuality = null;
      _photoState = _PhotoState.uploading;
    });
    try {
      final url = await ref
          .read(uploadRepositoryProvider)
          .uploadFile(file.path);
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _photoState = _PhotoState.reading;
      });
      final extracted = await ref
          .read(doctorPrescriptionRepositoryProvider)
          .extract(url);
      if (!mounted) return;
      setState(() {
        _goodQuality = extracted.goodQuality;
        if (extracted.dateIssued != null) _dateIssued = extracted.dateIssued;
        if (extracted.doctorName != null) {
          _doctorNameController.text = extracted.doctorName!;
        }
        if (extracted.licenseNo != null) {
          _licenseController.text = extracted.licenseNo!;
        }
        if (extracted.patientName != null) {
          _patientNameController.text = extracted.patientName!;
        }
        if (extracted.medications.isNotEmpty && _rows.every((r) => r.isEmpty)) {
          _replaceRows(extracted.medications);
        }
        _photoState = _PhotoState.ready;
      });
      if (!extracted.goodQuality) {
        _toast('The photo is hard to read — consider retaking it');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _photoState = _photoUrl == null
            ? _PhotoState.none
            : _PhotoState.ready,
      );
      if (_photoUrl == null) _photo = null;
      _toast(e.message);
    }
  }

  Future<void> _rotatePhoto() async {
    final photo = _photo;
    if (photo == null) return;
    final decoded = img.decodeImage(await photo.readAsBytes());
    if (decoded == null) return;
    final rotated = img.copyRotate(decoded, angle: 90);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/rx_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(img.encodeJpg(rotated, quality: 90));
    await _usePhoto(file);
  }

  void _removePhoto() {
    setState(() {
      _photo = null;
      _photoUrl = null;
      _goodQuality = null;
      _photoState = _PhotoState.none;
    });
  }

  Future<void> _pickDateIssued() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateIssued ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateIssued = picked);
  }

  // --- Send ---

  Future<void> _submit() async {
    final items = [
      for (final row in _rows)
        if (!row.isEmpty) row.toInput(),
    ];
    if (items.isEmpty) {
      _toast('Add at least one medication');
      return;
    }
    if (_photoState == _PhotoState.uploading ||
        _photoState == _PhotoState.reading) {
      _toast('Wait for the photo to finish processing');
      return;
    }

    setState(() => _submitting = true);
    try {
      String? signatureUrl;
      if (_signatureController.isNotEmpty) {
        final bytes = await _signatureController.toPngBytes();
        if (bytes != null) {
          signatureUrl = await ref
              .read(uploadRepositoryProvider)
              .uploadBytes(bytes, filename: 'signature.png');
        }
      }

      final notes = _notesController.text.trim();
      final license = _licenseController.text.trim();
      await ref
          .read(doctorPrescriptionRepositoryProvider)
          .create(
            patientId: widget.patientId,
            patientName: _patientNameController.text.trim().isEmpty
                ? widget.patientName
                : _patientNameController.text.trim(),
            items: items,
            notes: notes.isEmpty ? null : notes,
            imageUrl: _photoUrl,
            signatureUrl: signatureUrl,
            appointmentId: widget.appointmentId,
            licenseNo: license.isEmpty ? null : license,
            dateIssued: _dateIssued == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_dateIssued!),
          );
      await _clearDraft();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (context) => const _ReadySheet(),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final appointmentId = widget.appointmentId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Prescription'),
            if (appointmentId != null)
              Text(
                'Consultation ID: #${appointmentId.length > 8 ? appointmentId.substring(appointmentId.length - 8).toUpperCase() : appointmentId.toUpperCase()}',
                style: TextStyle(fontSize: 12, color: muted),
              ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const UserAvatar(url: null, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Patient',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(kPillRadius),
                  ),
                  child: const Text(
                    'Required Action',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B1A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: _SectionTitle('Document Preview')),
              if (_goodQuality != null) _QualityBadge(good: _goodQuality!),
            ],
          ),
          const SizedBox(height: 8),
          _buildPreview(),
          const SizedBox(height: 20),
          const _SectionTitle('Extracted Information'),
          const SizedBox(height: 4),
          Text(
            _photoUrl == null
                ? 'Add a photo to fill these in automatically, or type them.'
                : 'Check each field against the photo.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SoftCard(
            child: Column(
              children: [
                InkWell(
                  onTap: _pickDateIssued,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Issued',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _dateIssued == null
                          ? 'Select date'
                          : _dateFormat.format(_dateIssued!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _doctorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'License No.',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _patientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Medications'),
          const SizedBox(height: 8),
          ..._rows.asMap().entries.map(
            (entry) => _buildMedicationRow(entry.key, entry.value),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add medication'),
              onPressed: () => setState(() => _rows.add(_MedicationRow())),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Verification & Signature'),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _confirmed,
                  onChanged: (value) =>
                      setState(() => _confirmed = value ?? false),
                  title: const Text(
                    'I confirm this prescription was issued by me and the '
                    'information extracted is accurate.',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Digital Signature',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(kCardRadius),
                  ),
                  child: Signature(
                    controller: _signatureController,
                    height: 140,
                    backgroundColor: Colors.white,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _signatureController.clear,
                    child: const Text('Clear signature'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 16, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Photos and signatures are sent over an encrypted '
                  'connection and only shared with this patient.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _submitting ? null : _saveDraft,
                  child: const Text('Save Draft'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _submitting || !_confirmed ? null : _submit,
                  child: _submitting
                      ? const LoadingDots()
                      : const Text('Send to Patient'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final busy =
        _photoState == _PhotoState.uploading ||
        _photoState == _PhotoState.reading;
    final photo = _photo;
    final url = _photoUrl;

    if (photo == null && url == null) {
      return SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            const Icon(Icons.document_scanner_outlined, size: 40),
            const SizedBox(height: 8),
            Text(
              'Photograph a paper prescription (optional)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Open Camera'),
                    onPressed: () => _pickPhoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SoftCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: photo != null
                ? Image.file(photo, fit: BoxFit.cover)
                : AppNetworkImage(url!),
          ),
          if (busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoadingDots(color: Colors.white, size: 9),
                      const SizedBox(height: 12),
                      Text(
                        _photoState == _PhotoState.uploading
                            ? 'Uploading…'
                            : 'Reading prescription…',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!busy)
            Positioned(
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  if (photo != null)
                    _PreviewAction(
                      icon: Icons.rotate_right,
                      tooltip: 'Rotate',
                      onPressed: _rotatePhoto,
                    ),
                  _PreviewAction(
                    icon: Icons.photo_camera_outlined,
                    tooltip: 'Retake',
                    onPressed: () => _pickPhoto(ImageSource.camera),
                  ),
                  _PreviewAction(
                    icon: Icons.delete_outline,
                    tooltip: 'Remove',
                    danger: true,
                    onPressed: _removePhoto,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationRow(int index, _MedicationRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication',
                      isDense: true,
                    ),
                  ),
                ),
                if (_rows.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _rows.removeAt(index).dispose();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: row.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: row.instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions (optional)',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.good});

  final bool good;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: good ? seedTeal : const Color(0xFFFF9800),
        borderRadius: BorderRadius.circular(kPillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            good ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 14,
            color: good ? Colors.white : const Color(0xFF2B1A00),
          ),
          const SizedBox(width: 4),
          Text(
            good ? 'Good Quality' : 'Hard to read',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: good ? Colors.white : const Color(0xFF2B1A00),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  const _PreviewAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: danger ? const Color(0xFFD32F2F) : context.palette.card,
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: danger ? Colors.white : context.palette.ink),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _ReadySheet extends StatelessWidget {
  const _ReadySheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: seedTeal,
              child: Icon(Icons.check, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prescription Ready',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'The prescription has been sent to the patient and appears in '
              'their Prescriptions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
