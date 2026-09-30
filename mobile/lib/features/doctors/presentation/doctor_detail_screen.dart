import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../chat/data/chat_args.dart';
import '../data/doctor.dart';
import '../data/review.dart';
import '../state/doctor_providers.dart';
import 'review_help_tags.dart';
import 'doctor_card.dart';
import '../../../core/widgets/user_avatar.dart';

const _pageBg = Color(0xFFF1F7F7);
const _ink = Color(0xFF12263A);
const _muted = Color(0xFF5E7185);
const _body = Color(0xFF3B5670);
const _tealTint = Color(0xFFE3F2F1);
const _green = Color(0xFF1F9D55);
const _greenText = Color(0xFF16733F);
const _greenTint = Color(0xFFE4F6EA);
const _star = Color(0xFFF5A623);

class DoctorDetailScreen extends ConsumerStatefulWidget {
  const DoctorDetailScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  // Local only — there is no saved-doctors backend yet.
  bool _saved = false;

  void _toggleSaved() => setState(() => _saved = !_saved);

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        title: const Text('Doctor Profile'),
        titleTextStyle: const TextStyle(
          color: _ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: _ink),
        actions: [
          IconButton(
            icon: Icon(
              _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
            color: _saved ? Colors.redAccent : _ink,
            onPressed: _toggleSaved,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: doctorAsync.when(
        data: (doctor) => _DoctorDetailBody(
          doctor: doctor,
          saved: _saved,
          onToggleSaved: _toggleSaved,
        ),
        loading: () => const SkeletonForm(fieldCount: 3),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}

class _DoctorDetailBody extends StatelessWidget {
  const _DoctorDetailBody({
    required this.doctor,
    required this.saved,
    required this.onToggleSaved,
  });

  final Doctor doctor;
  final bool saved;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SoftCard(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _HeaderInfo(doctor: doctor),
                    const SizedBox(height: 16),
                    _ActionButtons(
                      doctor: doctor,
                      saved: saved,
                      onToggleSaved: onToggleSaved,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: const SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _AboutTab(doctor: doctor),
            _ReviewsTab(doctor: doctor),
            _TreatmentsTab(doctor: doctor),
            _ExperienceTab(doctor: doctor),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate();

  static const _height = 50.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: _pageBg,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const TabBar(
        labelColor: seedTeal,
        unselectedLabelColor: _muted,
        indicatorColor: seedTeal,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Color(0xFFDCE6E6),
        labelPadding: EdgeInsets.zero,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        tabs: [
          Tab(text: 'About'),
          Tab(text: 'Reviews'),
          Tab(text: 'Treatments'),
          Tab(text: 'Experience'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

/// One tab's scrollable content inside the [NestedScrollView]. The overlap
/// injector keeps content from sliding under the pinned tab bar.
class _TabPage extends StatelessWidget {
  const _TabPage({required this.storageKey, required this.children});

  final String storageKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: PageStorageKey<String>(storageKey),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          sliver: SliverList.list(children: children),
        ),
      ],
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final specialty = doctor.specialization ?? doctor.department;
    final hasQualifications =
        doctor.qualifications != null && doctor.qualifications!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(kCardRadius),
              child: SizedBox(
                width: 118,
                height: 150,
                child: DoctorImage(url: doctor.image, name: doctor.name),
              ),
            ),
            if (doctor.availableToday)
              const Positioned(
                top: 8,
                left: 8,
                child: _AvailableBadge(label: 'Available Today', dense: true),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  height: 1.15,
                ),
              ),
              if (specialty != null) ...[
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: const TextStyle(
                    fontSize: 16,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (hasQualifications) ...[
                const SizedBox(height: 4),
                Text(
                  doctor.qualifications!,
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              ],
              const SizedBox(height: 8),
              _RatingLine(doctor: doctor),
              const SizedBox(height: 12),
              if (doctor.hospitalName != null)
                _MiniInfo(
                  icon: Icons.location_on_outlined,
                  title: doctor.hospitalName!,
                  subtitle: doctor.hospitalAddress,
                ),
              if (doctor.hospitalName != null && specialty != null)
                const SizedBox(height: 8),
              if (specialty != null)
                _MiniInfo(
                  icon: Icons.medical_services_outlined,
                  title: 'Consults in: $specialty',
                  subtitle: doctor.treatments.isEmpty
                      ? null
                      : doctor.treatments.join(' • '),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final count = doctor.reviewCount;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 2,
      children: [
        const Icon(Icons.star_rounded, size: 20, color: _star),
        Text(
          doctor.rating != null ? doctor.rating!.toStringAsFixed(1) : 'New',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        Text(
          '($count review${count == 1 ? '' : 's'})',
          style: const TextStyle(fontSize: 13, color: _muted),
        ),
        if (doctor.yearsOfExperience != null) ...[
          const Text('•', style: TextStyle(fontSize: 13, color: _muted)),
          Text(
            '${doctor.yearsOfExperience}+ years experience',
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
        ],
        if ((doctor.patientCount ?? 0) > 0) ...[
          const Text('•', style: TextStyle(fontSize: 13, color: _muted)),
          Text(
            '${doctor.patientCount} patient${doctor.patientCount == 1 ? '' : 's'} seen',
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
        ],
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: _tealTint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: seedTeal),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _muted,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailableBadge extends StatelessWidget {
  const _AvailableBadge({required this.label, this.dense = false});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: _greenTint,
        borderRadius: BorderRadius.circular(kPillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 10.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: _greenText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.doctor,
    required this.saved,
    required this.onToggleSaved,
  });

  final Doctor doctor;
  final bool saved;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: seedTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kCardRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              prefetchDoctorDetail(ref, doctor.id);
              context.push('/book/${doctor.id}');
            },
            child: const Row(
              children: [
                // Balances the trailing chevron so the label stays centred.
                SizedBox(width: 22),
                Spacer(),
                Icon(Icons.calendar_month_outlined, size: 22),
                SizedBox(width: 10),
                Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Spacer(),
                Icon(Icons.chevron_right_rounded, size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OutlineAction(
                icon: Icons.sms_outlined,
                label: 'Send Message',
                onPressed: () => context.push(
                  '/chat/${doctor.id}',
                  extra: ChatArgs(name: doctor.name, image: doctor.image),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineAction(
                icon: saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: saved ? 'Saved' : 'Save Doctor',
                onPressed: onToggleSaved,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: const BorderSide(color: Color(0xFFCBD6DC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: _ink,
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: child,
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final specialty = doctor.specialization ?? doctor.department;
    final facts = [
      if (doctor.yearsOfExperience != null)
        _Fact(
          icon: Icons.work_outline_rounded,
          label: '${doctor.yearsOfExperience}+ years\nexperience',
        ),
      if (doctor.boardCertified)
        _Fact(
          icon: Icons.verified_user_outlined,
          label: specialty != null
              ? 'Board certified\n${specialty.toLowerCase()}'
              : 'Board\ncertified',
        ),
      _Fact(
        icon: Icons.person_outline_rounded,
        label: _patientGroup(specialty),
      ),
    ];

    return _TabPage(
      storageKey: 'about',
      children: [
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('About'),
              const SizedBox(height: 8),
              Text(
                doctor.bio != null && doctor.bio!.isNotEmpty
                    ? doctor.bio!
                    : 'No biography has been added for this doctor yet.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: _body,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < facts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: facts[i]),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _QuickInfoCard(doctor: doctor),
        const SizedBox(height: 14),
        _ReviewsPreviewCard(doctor: doctor),
      ],
    );
  }
}

/// Best-effort patient group from the specialty text, in the same spirit as
/// [iconForSpecialization] — there is no dedicated field for it.
String _patientGroup(String? specialty) {
  final text = (specialty ?? '').toLowerCase();
  if (text.contains('pediatric') || text.contains('paediatric'))
    return 'Treats\nchildren';
  if (text.contains('obstetric') || text.contains('gyn'))
    return 'Treats\nwomen';
  if (text.contains('internal medicine') || text.contains('cardio'))
    return 'Treats\nadults';
  return 'Treats all\nages';
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: _tealTint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: seedTeal),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _muted, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  const _QuickInfoCard({required this.doctor});

  final Doctor doctor;

  Future<void> _openMap() async {
    final query = Uri.encodeComponent(
      [
        doctor.hospitalName,
        doctor.hospitalAddress,
      ].whereType<String>().join(', '),
    );
    final uri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String? get _availability {
    final days = doctor.availabilityDays;
    final hours = doctor.availabilityHours;
    if (days != null && hours != null) return '$days: $hours';
    return days ?? hours;
  }

  @override
  Widget build(BuildContext context) {
    final feeFormat = NumberFormat.decimalPattern();
    final availability = _availability;
    final rows = [
      if (doctor.hospitalName != null)
        _InfoRow(
          icon: Icons.local_hospital_outlined,
          label: 'Hospital',
          value: doctor.hospitalName!,
        ),
      if (doctor.hospitalAddress != null)
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: doctor.hospitalAddress!,
          trailing: _DirectionsLink(onTap: _openMap),
        ),
      if (doctor.consultationFee != null)
        _InfoRow(
          icon: Icons.paid_outlined,
          label: 'Consultation Fee',
          value: 'UGX ${feeFormat.format(doctor.consultationFee)}',
        ),
      if (availability != null)
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Availability',
          value: availability,
          footer: doctor.availableToday
              ? const _AvailableBadge(label: 'Available today')
              : null,
        ),
    ];

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Quick Info'),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            const Text('No details added yet.', style: TextStyle(color: _muted))
          else
            ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.footer,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _tealTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: seedTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                ),
                if (footer != null) ...[const SizedBox(height: 6), footer!],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _DirectionsLink extends StatelessWidget {
  const _DirectionsLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Get directions',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: seedTeal,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.north_east_rounded, size: 16, color: seedTeal),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewsPreviewCard extends ConsumerWidget {
  const _ReviewsPreviewCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(doctorReviewsProvider(doctor.id));
    void openReviewsTab() => DefaultTabController.of(context).animateTo(1);

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CardTitle('Reviews'),
              const Spacer(),
              TextButton(
                onPressed: openReviewsTab,
                style: TextButton.styleFrom(
                  foregroundColor: seedTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          reviewsAsync.when(
            data: (data) {
              if (data.reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'No reviews yet.',
                    style: TextStyle(color: _muted),
                  ),
                );
              }
              return Column(
                children: [
                  for (final review in data.reviews.take(2))
                    _ReviewRow(
                      review: review,
                      compact: true,
                      onTap: openReviewsTab,
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => const Text(
              'Could not load reviews',
              style: TextStyle(color: _muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(doctorReviewsProvider(doctor.id));
    return _TabPage(
      storageKey: 'reviews',
      children: [
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('Reviews'),
              const SizedBox(height: 6),
              reviewsAsync.when(
                data: (data) {
                  if (data.reviews.isEmpty) {
                    return const Text(
                      'No reviews yet.',
                      style: TextStyle(color: _muted),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < data.reviews.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: Color(0xFFE6EEEE)),
                        _ReviewRow(review: data.reviews[i], compact: false),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const Text(
                  'Could not load reviews',
                  style: TextStyle(color: _muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review, required this.compact, this.onTap});

  final Review review;

  /// Compact rows (About tab preview) clamp the comment, hide the doctor's
  /// reply and show a chevron that opens the full Reviews tab.
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasComment = review.comment != null && review.comment!.isNotEmpty;
    final hasReply =
        review.doctorReply != null && review.doctorReply!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kCardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UserAvatar(url: null, radius: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.patientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: _star,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat(
                          compact ? 'MMM d' : 'MMM d, yyyy',
                        ).format(review.createdAt),
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                    ],
                  ),
                  if (hasComment) ...[
                    const SizedBox(height: 5),
                    Text(
                      review.comment!,
                      maxLines: compact ? 2 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _body,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (!compact && review.helpedWith.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ReviewHelpTags(labels: review.helpedWith),
                  ],
                  if (!compact && hasReply) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _pageBg,
                        borderRadius: BorderRadius.circular(kCardRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.reply_rounded,
                                size: 14,
                                color: seedTeal,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Doctor's reply",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: seedTeal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            review.doctorReply!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: _body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (compact)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(Icons.chevron_right_rounded, color: _muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _TreatmentsTab extends StatelessWidget {
  const _TreatmentsTab({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final specialty = doctor.specialization ?? doctor.department;
    return _TabPage(
      storageKey: 'treatments',
      children: [
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('Treatments'),
              if (specialty != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Consults in $specialty',
                  style: const TextStyle(fontSize: 14, color: _muted),
                ),
              ],
              const SizedBox(height: 12),
              if (doctor.treatments.isEmpty)
                const Text(
                  'No treatments have been listed for this doctor yet.',
                  style: TextStyle(color: _muted),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final treatment in doctor.treatments)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _tealTint,
                          borderRadius: BorderRadius.circular(kPillRadius),
                        ),
                        child: Text(
                          treatment,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: seedTeal,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExperienceTab extends StatelessWidget {
  const _ExperienceTab({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final specialty = doctor.specialization ?? doctor.department;
    final hasQualifications =
        doctor.qualifications != null && doctor.qualifications!.isNotEmpty;
    final rows = [
      if (doctor.yearsOfExperience != null)
        _InfoRow(
          icon: Icons.work_outline_rounded,
          label: 'Years of experience',
          value: '${doctor.yearsOfExperience}+ years',
        ),
      if (hasQualifications)
        _InfoRow(
          icon: Icons.school_outlined,
          label: 'Qualifications',
          value: doctor.qualifications!,
        ),
      if (doctor.boardCertified)
        _InfoRow(
          icon: Icons.verified_user_outlined,
          label: 'Certification',
          value: specialty != null
              ? 'Board certified in $specialty'
              : 'Board certified',
        ),
      if (doctor.hospitalName != null)
        _InfoRow(
          icon: Icons.local_hospital_outlined,
          label: 'Practices at',
          value: doctor.hospitalName!,
        ),
    ];

    return _TabPage(
      storageKey: 'experience',
      children: [
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('Experience'),
              const SizedBox(height: 6),
              if (rows.isEmpty)
                const Text(
                  'No experience details have been added for this doctor yet.',
                  style: TextStyle(color: _muted),
                )
              else
                ...rows,
            ],
          ),
        ),
      ],
    );
  }
}
