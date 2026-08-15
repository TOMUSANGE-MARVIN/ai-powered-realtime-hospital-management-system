import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../chat/data/chat_args.dart';
import '../data/doctor.dart';
import '../data/review.dart';
import '../state/doctor_providers.dart';
import 'doctor_card.dart';

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
        loading: () => const SkeletonForm(fieldCount: 3),
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SoftCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 96,
                        height: 116,
                        child: DoctorImage(url: doctor.image, name: doctor.name),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (doctor.specialization != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              doctor.specialization!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatPill(
                                  label: 'Rating',
                                  value: doctor.rating != null
                                      ? doctor.rating!.toStringAsFixed(1)
                                      : '—',
                                  child: _StarRow(rating: doctor.rating),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatPill(
                                  label: 'Reviews',
                                  value: '${doctor.reviewCount}',
                                  child: Icon(
                                    Icons.people_alt_rounded,
                                    size: 16,
                                    color: seedTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'About',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  doctor.bio!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reviews',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  reviewsAsync.maybeWhen(
                    data: (data) => data.totalReviews > 2
                        ? TextButton.icon(
                            onPressed: () => _showAllReviews(context, doctor.name, data),
                            label: const Text('See all'),
                            icon: const Icon(Icons.chevron_right_rounded, size: 18),
                            iconAlignment: IconAlignment.end,
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              reviewsAsync.when(
                data: (data) {
                  if (data.reviews.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No reviews yet.'),
                    );
                  }
                  return SizedBox(
                    height: 128,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.reviews.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) =>
                          _ReviewCard(review: data.reviews[index]),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 128,
                  child: Row(
                    children: [
                      Expanded(child: SkeletonBox(width: double.infinity, height: 128, borderRadius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(width: double.infinity, height: 128, borderRadius: 16)),
                    ],
                  ),
                ),
                error: (_, _) => const Text('Could not load reviews'),
              ),
              if (doctor.hospitalName != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Hospital',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _HospitalTile(doctor: doctor),
              ],
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
                    onPressed: () {
                      prefetchDoctorDetail(ref, doctor.id);
                      context.push('/book/${doctor.id}');
                    },
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

/// A small stat pill (e.g. "Rating 4.5" / "Reviews 128") — an icon/star row,
/// the value, and a caption label, matching the doctor profile's header
/// card.
class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.child});

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: seedTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 3),
          child,
        ],
      ),
    );
  }
}

/// Five small stars reflecting a doctor's average rating (rounded to the
/// nearest whole star) — used inside the Rating stat pill.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double? rating;

  @override
  Widget build(BuildContext context) {
    final filled = rating != null ? rating!.round().clamp(0, 5) : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13,
          color: Colors.amber,
        ),
      ),
    );
  }
}

/// A compact horizontally-scrolled review card — reviewer initials avatar,
/// name, star rating, and comment snippet.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  String get _initials {
    final parts =
        review.patientName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        showShadow: false,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: seedTeal.withValues(alpha: 0.15),
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: seedTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 13,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM d').format(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  review.comment!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The doctor's hospital name + address as a tappable row — opens the
/// address in a maps app when tapped.
class _HospitalTile extends StatelessWidget {
  const _HospitalTile({required this.doctor});

  final Doctor doctor;

  Future<void> _openMap() async {
    final query = Uri.encodeComponent(
      [doctor.hospitalName, doctor.hospitalAddress].whereType<String>().join(', '),
    );
    final uri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      onTap: doctor.hospitalAddress != null ? _openMap : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: seedTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded, size: 20, color: seedTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.hospitalName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                if (doctor.hospitalAddress != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    doctor.hospitalAddress!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (doctor.hospitalAddress != null)
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.outline),
        ],
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
