import 'package:flutter/material.dart';

/// Asks why an appointment is being rejected or cancelled. Returns the reason
/// (possibly empty), or null if the doctor backed out.
Future<String?> askCancellationReason(
  BuildContext context, {
  required String patientName,
  required bool isReject,
}) {
  const presets = [
    'Not available at this time',
    'Outside my specialty — please book a different doctor',
    'Needs an in-person visit instead',
    'Emergency — please go to the nearest hospital',
  ];
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
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
            Text(
              isReject ? 'Decline request?' : 'Cancel appointment?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Tell $patientName why. They see this in their notification.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in presets)
                  ActionChip(
                    label: Text(p),
                    onPressed: () => setState(() => controller.text = p),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
              ),
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(isReject ? 'Decline request' : 'Cancel appointment'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep it'),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(controller.dispose);
}

/// Visit summary written when ending (or after) a consultation. Returns the
/// text, or null if dismissed.
Future<String?> askVisitSummary(
  BuildContext context, {
  required String patientName,
  String? initial,
  required String action,
}) {
  final controller = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
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
            'Visit summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$patientName can read this in their appointments. Keep it in plain '
            'language: findings, diagnosis, advice and follow-up.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 5,
            maxLines: 10,
            maxLength: 3000,
            decoration: const InputDecoration(
              hintText:
                  'e.g. Mild chest infection. Take the prescribed antibiotics '
                  'for 7 days, drink plenty of water, and book a follow-up if '
                  'the fever lasts more than 3 days.',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(action),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}
