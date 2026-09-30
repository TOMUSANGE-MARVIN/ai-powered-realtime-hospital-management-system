import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/skeleton.dart';
import '../data/legal_repository.dart';
import 'legal_text.dart';

/// The Terms of Service or Privacy Policy, readable signed in or out.
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({super.key, required this.privacy});

  /// true → Privacy Policy, false → Terms of Service.
  final bool privacy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(legalDocumentsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(privacy ? 'Privacy Policy' : 'Terms of Service'),
      ),
      body: docs.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: SkeletonLines(count: 4),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(legalDocumentsProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            LegalUpdatedLine(
              'Last updated ${DateFormat('d MMM yyyy').format(d.updatedAt)}',
            ),
            const SizedBox(height: 12),
            LegalText(privacy ? d.privacy : d.terms),
          ],
        ),
      ),
    );
  }
}
