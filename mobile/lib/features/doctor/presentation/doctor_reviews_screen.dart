import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../doctors/data/review.dart';
import '../../doctors/state/doctor_providers.dart';

final myReviewsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(reviewRepositoryProvider).listMine();
});

class DoctorReviewsScreen extends ConsumerWidget {
  const DoctorReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: reviewsAsync.when(
        data: (data) {
          if (data.reviews.isEmpty) {
            return const Center(child: Text('No reviews yet.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myReviewsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          data.averageRating?.toStringAsFixed(1) ?? '—',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text('(${data.totalReviews} reviews)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...data.reviews.map((r) => _DoctorReviewCard(review: r)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _DoctorReviewCard extends ConsumerWidget {
  const _DoctorReviewCard({required this.review});

  final Review review;

  Future<void> _reply(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: review.doctorReply ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(review.doctorReply == null ? 'Reply to review' : 'Edit reply'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Thank the patient or address their feedback…',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    try {
      await ref.read(reviewRepositoryProvider).reply(reviewId: review.id, reply: text);
      ref.invalidate(myReviewsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send reply. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(review.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            Text(
              DateFormat('MMM d, yyyy').format(review.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment!),
            ],
            if (review.doctorReply != null && review.doctorReply!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your reply',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(review.doctorReply!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(review.doctorReply == null ? Icons.reply : Icons.edit, size: 16),
                label: Text(review.doctorReply == null ? 'Reply' : 'Edit reply'),
                onPressed: () => _reply(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
