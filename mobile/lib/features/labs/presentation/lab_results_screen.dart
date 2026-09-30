import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/lab_result.dart';

/// A patient's lab tests: ones a doctor has ordered, ones in progress, and
/// results a doctor has reviewed.
class LabResultsScreen extends ConsumerWidget {
  const LabResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(myLabResultsProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Lab Results')),
      body: results.when(
        loading: () => const SkeletonList(count: 4),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(myLabResultsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (list) => list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No lab tests yet. Tests your doctor orders appear here, '
                    'and results once a doctor has reviewed them.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(myLabResultsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => LabResultCard(result: list[i]),
                ),
              ),
      ),
    );
  }
}

/// One lab result: optional image, the doctor's notes and, for doctors, the
/// AI analysis.
class LabResultCard extends StatelessWidget {
  const LabResultCard({super.key, required this.result, this.showAi = false});

  final LabResult result;
  final bool showAi;

  /// Where a test that isn't reviewed yet stands. Patients are told to visit
  /// the lab; doctors see the pipeline stage.
  String? get _statusLabel {
    if (result.status == null || result.status == 'reviewed') return null;
    if (result.isRequested) {
      if (showAi) return 'Requested · awaiting the lab';
      final by = result.requestedBy;
      return by == null
          ? 'Requested · please visit the lab'
          : 'Requested by $by · please visit the lab';
    }
    if (result.status == 'analyzed') return 'Awaiting doctor review';
    return showAi ? 'Pending analysis' : 'At the lab · awaiting results';
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final image = result.imageUrl;
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (image != null)
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      title: Text(result.title),
                    ),
                    body: InteractiveViewer(
                      maxScale: 5,
                      child: Center(child: Image.network(image)),
                    ),
                  ),
                ),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 40),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      color: seedTeal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      DateFormat('d MMM yyyy').format(result.createdAt),
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
                if (_statusLabel case final label?) ...[
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFFA000),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (result.doctorNotes?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Doctor's notes",
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.doctorNotes!,
                    style: const TextStyle(height: 1.4),
                  ),
                ],
                if (showAi &&
                    !result.isRequested &&
                    result.aiAnalysis?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    'AI analysis (clinicians only)',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.aiAnalysis!,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.4, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
