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
      backgroundColor: const Color(0xFFF6FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAFA),
        title: const Text('Doctor Profile'),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: const [_SaveDoctorButton()],
      ),
      body: doctorAsync.when(
        data: (doctor) => _DoctorDetailBody(doctor: doctor),
        loading: () => const SkeletonForm(fieldCount: 3),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

/// Heart/favorite toggle in the AppBar. Visual only — there is no
/// saved-doctors backend yet, so this doesn't persist across sessions.
class _SaveDoctorButton extends StatefulWidget {
  const _SaveDoctorButton();

  @override
  State<_SaveDoctorButton> createState() => _SaveDoctorButtonState();
}

class _SaveDoctorButtonState extends State<_SaveDoctorButton> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_saved ? Icons.favorite_rounded : Icons.favorite_border_rounded),
      color: _saved ? Colors.redAccent : Colors.black87,
      onPressed: () => setState(() => _saved = !_saved),
    );
  }
}

class _DoctorDetailBody extends StatelessWidget {
  const _DoctorDetailBody({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(doctor: doctor),
                const SizedBox(height: 16),
                _ActionRow(doctor: doctor),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: seedTeal,
            unselectedLabelColor: Colors.black54,
            indicatorColor: seedTeal,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: EdgeInsets.symmetric(horizontal: 16),
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.5),
            tabs: [
              Tab(text: 'About'),
              Tab(text: 'Reviews'),
              Tab(text: 'Treatments'),
              Tab(text: 'Experience'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _AboutSection(doctor: doctor),
                _ReviewsSection(doctor: doctor),
                _TreatmentsSection(doctor: doctor),
                _ExperienceSection(doctor: doctor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final specialtyLabel = doctor.specialization ?? doctor.department ?? 'General';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 110,
                height: 130,
                child: DoctorImage(url: doctor.image, name: doctor.name),
              ),
            ),
            if (doctor.availableToday)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Available Today',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                specialtyLabel,
                style: const TextStyle(fontSize: 14.5, color: seedTeal, fontWeight: FontWeight.w600),
              ),
              if (doctor.qualifications != null && doctor.qualifications!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  doctor.qualifications!,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    doctor.rating != null ? doctor.rating!.toStringAsFixed(1) : 'New',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    ' (${doctor.reviewCount} reviews)',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (doctor.yearsOfExperience != null) ...[
                    const Text(' · ', style: TextStyle(color: Colors.black38)),
                    Expanded(
                      child: Text(
                        '${doctor.yearsOfExperience}+ years experience',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (doctor.hospitalName != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 15, color: seedTeal),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.hospitalName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          if (doctor.hospitalAddress != null)
                            Text(
                              doctor.hospitalAddress!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (doctor.treatments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 15, color: seedTeal),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consults in: $specialtyLabel',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            doctor.treatments.join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: seedTeal, foregroundColor: Colors.white),
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Book Appointment'),
            onPressed: () {
              prefetchDoctorDetail(ref, doctor.id);
              context.push('/book/${doctor.id}');
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Send Message'),
                onPressed: () => context.push(
                  '/chat/${doctor.id}',
                  extra: ChatArgs(name: doctor.name, image: doctor.image),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bookmark_border_rounded, size: 16),
                label: const Text('Save Doctor'),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.doctor});

  final Doctor doctor;

  Future<void> _openMap(Doctor doctor) async {
    final query = Uri.encodeComponent(
      [doctor.hospitalName, doctor.hospitalAddress].whereType<String>().join(', '),
    );
    final uri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final specialtyLabel = doctor.specialization ?? doctor.department ?? 'General';
    final feeFormat = NumberFormat.decimalPattern();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                doctor.bio != null && doctor.bio!.isNotEmpty
                    ? doctor.bio!
                    : 'No biography has been added for this doctor yet.',
                style: const TextStyle(height: 1.5, color: seedTeal, fontSize: 13.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (doctor.yearsOfExperience != null)
                    Expanded(
                      child: _FactPill(
                        icon: Icons.work_history_outlined,
                        label: '${doctor.yearsOfExperience}+ years\nexperience',
                      ),
                    ),
                  if (doctor.yearsOfExperience != null) const SizedBox(width: 8),
                  if (doctor.boardCertified)
                    Expanded(
                      child: _FactPill(
                        icon: Icons.verified_outlined,
                        label: 'Board certified\n$specialtyLabel',
                      ),
                    ),
                  if (doctor.boardCertified) const SizedBox(width: 8),
                  const Expanded(
                    child: _FactPill(icon: Icons.person_outline, label: 'Treats\nadults'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Quick Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SoftCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              if (doctor.hospitalName != null)
                _QuickInfoRow(
                  icon: Icons.local_hospital_outlined,
                  label: 'Hospital',
                  value: doctor.hospitalName!,
                ),
              if (doctor.hospitalAddress != null)
                _QuickInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: doctor.hospitalAddress!,
                  trailing: TextButton.icon(
                    onPressed: () => _openMap(doctor),
                    icon: const Icon(Icons.north_east_rounded, size: 14),
                    label: const Text('Get directions'),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              if (doctor.consultationFee != null)
                _QuickInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Consultation Fee',
                  value: 'UGX ${feeFormat.format(doctor.consultationFee)}',
                ),
              if (doctor.availabilityDays != null || doctor.availabilityHours != null)
                _QuickInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Availability',
                  value: [doctor.availabilityDays, doctor.availabilityHours]
                      .whereType<String>()
                      .join(' · '),
                  badge: doctor.availableToday ? 'Available today' : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FactPill extends StatelessWidget {
  const _FactPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: seedTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: seedTeal),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoRow extends StatelessWidget {
  const _QuickInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: seedTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: seedTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 7, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        badge!,
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(doctorReviewsProvider(doctor.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        reviewsAsync.when(
          data: (data) {
            if (data.reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No reviews yet.'),
              );
            }
            return Column(
              children: data.reviews.map((r) => _ReviewTile(review: r)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Text('Could not load reviews'),
        ),
      ],
    );
  }
}

class _TreatmentsSection extends StatelessWidget {
  const _TreatmentsSection({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Treatments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (doctor.treatments.isEmpty)
          const Text('No treatments have been listed for this doctor yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: doctor.treatments
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: seedTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: seedTeal),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final hasExperience = doctor.yearsOfExperience != null;
    final hasQualifications = doctor.qualifications != null && doctor.qualifications!.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Experience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (!hasExperience && !hasQualifications)
          const Text('No experience details have been added for this doctor yet.')
        else ...[
          if (hasExperience)
            _QuickInfoRow(
              icon: Icons.work_history_outlined,
              label: 'Years of experience',
              value: '${doctor.yearsOfExperience} years',
            ),
          if (hasQualifications)
            _QuickInfoRow(
              icon: Icons.school_outlined,
              label: 'Qualifications',
              value: doctor.qualifications!,
            ),
        ],
      ],
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
