import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../data/prescription_item_input.dart';
import '../state/doctor_providers.dart';

class NewPrescriptionScreen extends ConsumerStatefulWidget {
  const NewPrescriptionScreen({super.key, required this.patientId, required this.patientName});

  final String patientId;
  final String patientName;

  @override
  ConsumerState<NewPrescriptionScreen> createState() => _NewPrescriptionScreenState();
}

class _MedicationRow {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final instructionsController = TextEditingController();

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    quantityController.dispose();
    instructionsController.dispose();
  }
}

class _NewPrescriptionScreenState extends ConsumerState<NewPrescriptionScreen> {
  final _notesController = TextEditingController();
  final List<_MedicationRow> _rows = [_MedicationRow()];
  final _signatureController = SignatureController(penStrokeWidth: 2, penColor: Colors.black);
  XFile? _attachedPhoto;
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _attachedPhoto = picked);
  }

  Future<void> _submit() async {
    final items = _rows
        .where((r) => r.nameController.text.trim().isNotEmpty)
        .map(
          (r) => PrescriptionItemInput(
            medicationName: r.nameController.text.trim(),
            dosage: r.dosageController.text.trim(),
            quantity: int.tryParse(r.quantityController.text) ?? 1,
            instructions: r.instructionsController.text.trim().isEmpty
                ? null
                : r.instructionsController.text.trim(),
          ),
        )
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medication')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final uploadRepo = ref.read(uploadRepositoryProvider);

      String? imageUrl;
      if (_attachedPhoto != null) {
        imageUrl = await uploadRepo.uploadFile(_attachedPhoto!.path);
      }

      String? signatureUrl;
      if (_signatureController.isNotEmpty) {
        final bytes = await _signatureController.toPngBytes();
        if (bytes != null) {
          signatureUrl = await uploadRepo.uploadBytes(bytes, filename: 'signature.png');
        }
      }

      await ref.read(doctorPrescriptionRepositoryProvider).create(
            patientId: widget.patientId,
            patientName: widget.patientName,
            items: items,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            imageUrl: imageUrl,
            signatureUrl: signatureUrl,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription sent to patient')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prescription for ${widget.patientName}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Medications', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._rows.asMap().entries.map((entry) => _buildMedicationRow(entry.key, entry.value)),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add medication'),
            onPressed: () => setState(() => _rows.add(_MedicationRow())),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          const Text('Attach a photo (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_attachedPhoto != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_attachedPhoto!.name, style: TextStyle(color: Colors.grey.shade600)),
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_attachedPhoto == null ? 'Take photo' : 'Retake photo'),
            onPressed: _pickPhoto,
          ),
          const SizedBox(height: 20),
          const Text('Digital signature', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Signature(controller: _signatureController, height: 150),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _signatureController.clear(),
              child: const Text('Clear signature'),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send to Patient'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationRow(int index, _MedicationRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.nameController,
                    decoration: const InputDecoration(labelText: 'Medication', isDense: true),
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
                    decoration: const InputDecoration(labelText: 'Dosage', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: row.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: row.instructionsController,
              decoration: const InputDecoration(labelText: 'Instructions (optional)', isDense: true),
            ),
          ],
        ),
      ),
    );
  }
}
