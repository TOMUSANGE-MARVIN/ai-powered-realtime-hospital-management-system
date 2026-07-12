import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/soft_card.dart';
import '../../chat/data/chat_args.dart';
import '../data/doctor.dart';
import '../data/review.dart';
import '../state/doctor_providers.dart';

class DoctorDetailScreen extends ConsumerWidget {
  const DoctorDetailScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor profile')),
      body: doctorAsync.when(
        data: (doctor) => _DoctorDetailBody(doctor: doctor),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _DoctorDetailBody extends ConsumerWidget {
  const _DoctorDetailBody({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(doctorReviewsProvider(doctor.id));
    final feeFormat = NumberFormat.decimalPattern();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage:
                          doctor.image != null ? NetworkImage(doctor.image!) : null,
                      child: doctor.image == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(doctor.name, style: Theme.of(context).textTheme.titleLarge),
                    if (doctor.specialization != null)
                      Text(
                        doctor.specialization!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                    if (doctor.hospitalName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 15, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              doctor.hospitalName!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatCard(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    value: doctor.rating != null
                        ? doctor.rating!.toStringAsFixed(1)
                        : '—',
                    label: 'Rating',
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.reviews_outlined,
                    value: '${doctor.reviewCount}',
                    label: 'Reviews',
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.payments_outlined,
                    value: doctor.consultationFee != null
                        ? 'UGX ${feeFormat.format(doctor.consultationFee)}'
                        : 'Free',
                    label: 'Fee',
                  ),
                ],
              ),
              if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('About',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(doctor.bio!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              Text('Reviews',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              reviewsAsync.when(
                data: (data) {
                  if (data.reviews.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No reviews yet.'),
                    );
                  }
                  final visible = data.reviews.take(3).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...visible.map((r) => _ReviewTile(review: r)),
                      if (data.totalReviews > visible.length)
                        TextButton(
                          onPressed: () =>
                              _showAllReviews(context, doctor.name, data),
                          child: Text('See all ${data.totalReviews} reviews'),
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => const Text('Could not load reviews'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Instant Chat'),
                    onPressed: () => context.push(
                      '/chat/${doctor.id}',
                      extra: ChatArgs(name: doctor.name, image: doctor.image),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Book'),
                    onPressed: () => context.push('/book/${doctor.id}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAllReviews(BuildContext context, String doctorName, DoctorReviews data) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Reviews for $doctorName',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...data.reviews.map((r) => _ReviewTile(review: r)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ...List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  size: 15,
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
            const SizedBox(height: 4),
            Text(review.comment!),
          ],
          if (review.doctorReply != null && review.doctorReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        "Doctor's reply",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(review.doctorReply!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
