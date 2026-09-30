import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/widgets/loading_dots.dart';
import '../data/lab_result.dart';

/// Lets a doctor order a lab test for a patient. Returns true once the
/// request is filed; the lab picks it up from the web Test Requests page.
Future<bool> showOrderLabTestSheet(
  BuildContext context, {
  required String patientId,
  required String patientName,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _OrderLabTestSheet(patientId: patientId, patientName: patientName),
  );
  return result ?? false;
}

class _OrderLabTestSheet extends ConsumerStatefulWidget {
  const _OrderLabTestSheet({
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  @override
  ConsumerState<_OrderLabTestSheet> createState() => _OrderLabTestSheetState();
}

class _OrderLabTestSheetState extends ConsumerState<_OrderLabTestSheet> {
  final _notesController = TextEditingController();
  String _testType = labTestTypes.first;
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await requestLabTest(
        ref.read(dioProvider),
        patientId: widget.patientId,
        testType: _testType,
        notes: _notesController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final imaging = const ['X-Ray', 'MRI', 'CT Scan'].contains(_testType);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Order Lab Test',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('For ${widget.patientName}', style: TextStyle(color: muted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in labTestTypes)
                ChoiceChip(
                  label: Text(type),
                  selected: _testType == type,
                  onSelected: (_) => setState(() => _testType = type),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: imaging ? 'Body part' : 'Notes for the lab',
              hintText: imaging ? 'e.g. Left knee' : 'e.g. Full blood count',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const LoadingDots()
                  : const Text('Order test'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The patient is notified and the lab sees it under Test Requests.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}
