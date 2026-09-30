import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/lab_result.dart';

/// A patient's lab results that a doctor has reviewed.
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
                    'No lab results yet. Results appear here once a doctor '
                    'has reviewed them.',
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
                if (showAi &&
                    result.status != null &&
                    result.status != 'reviewed') ...[
                  const SizedBox(height: 6),
                  Text(
                    result.status == 'analyzed'
                        ? 'Awaiting doctor review'
                        : 'Pending analysis',
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
                if (showAi && result.aiAnalysis?.isNotEmpty == true) ...[
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
