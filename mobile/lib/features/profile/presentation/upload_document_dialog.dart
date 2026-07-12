import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../state/profile_providers.dart';

Future<void> showUploadDocumentDialog(BuildContext context, WidgetRef ref) async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
  if (picked == null || !context.mounted) return;

  final titleController = TextEditingController(text: 'Medical document');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Upload document'),
      content: TextField(
        controller: titleController,
        decoration: const InputDecoration(labelText: 'Title'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Upload')),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    final url = await ref.read(uploadRepositoryProvider).uploadFile(picked.path);
    await ref.read(profileRepositoryProvider).uploadDocument(
          title: titleController.text.trim().isEmpty ? 'Medical document' : titleController.text.trim(),
          url: url,
        );
    ref.invalidate(myMedicalDocumentsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded')));
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
