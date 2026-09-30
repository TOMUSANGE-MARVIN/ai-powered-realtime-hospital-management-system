import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_gate.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../appointments/data/appointment.dart';
import '../../appointments/state/appointment_providers.dart';
import '../../auth/state/auth_controller.dart';
import '../../doctors/data/doctor.dart';
import '../../doctors/presentation/category_card.dart';
import '../../doctors/presentation/doctor_card.dart';
import '../../notifications/presentation/notifications_screen.dart'
    show NotificationBell;
import '../../doctors/state/doctor_providers.dart';
import '../../../core/widgets/user_avatar.dart';

String _greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final categoriesAsync = ref.watch(categoriesWithCountsProvider);
    final featuredAsync = ref.watch(featuredDoctorsProvider);
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    final firstName = (user?.name ?? '').trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: tealBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: seedTeal,
          onRefresh: () async {
            ref.invalidate(categoriesWithCountsProvider);
            ref.invalidate(featuredDoctorsProvider);
            ref.invalidate(myAppointmentsProvider);
          },
          child: DashboardGate(
            values: [categoriesAsync, featuredAsync, appointmentsAsync],
            loadingBuilder: (context) => const _PatientHomeSkeleton(),
            builder: (context) => ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 96),
              children: [
                _HeroHeader(
                  greeting: _greetingFor(DateTime.now()),
                  firstName: firstName.isEmpty ? 'there' : firstName,
                  image: user?.image,
                ),
                const SizedBox(height: 26),
                _SectionHeader(
                  title: 'Next appointment',
                  onSeeAll: () => context.push('/home/appointments'),
                ),
                const SizedBox(height: 10),
                _NextAppointmentCard(appointmentsAsync: appointmentsAsync),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Quick actions'),
                const SizedBox(height: 12),
                const _QuickActions(),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Browse specialties',
                  subtitle: 'Find the right doctor for your health needs',
                  onSeeAll: () => context.push('/categories'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 212,
                  child: categoriesAsync.when(
                    data: (categories) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => CategoryCard(
                        category: categories[index].category,
                        count: categories[index].count,
                        width: 150,
                        tinted: true,
                      ),
                    ),
                    loading: () => const SkeletonCarousel(itemWidth: 150),
                    error: (_, _) =>
                        const Center(child: Text('Could not load categories')),
                  ),
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Featured doctors',
                  onSeeAll: () => context.push('/search'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 316,
                  child: featuredAsync.when(
                    data: (doctors) {
                      if (doctors.isEmpty) {
                        return const Center(
                          child: Text('No doctors available yet'),
                        );
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: doctors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) =>
                            _FeaturedDoctorCard(doctor: doctors[index]),
                      );
                    },
                    loading: () =>
                        const SkeletonCarousel(itemWidth: 196, spacing: 14),
                    error: (error, _) => Center(child: Text(error.toString())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mirrors [PatientHomeScreen]'s real layout — hero header, next-appointment
/// card, quick actions, a categories row, a featured-doctors row — so the
/// first-load wait reads as "this page is here, filling in" rather than a
/// generic spinner.
class _PatientHomeSkeleton extends StatelessWidget {
  const _PatientHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 96),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SkeletonBox(
            width: double.infinity,
            height: 168,
            borderRadius: kCardRadius,
          ),
        ),
        const SizedBox(height: 26),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SkeletonBox(width: 140, height: 18),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SkeletonBox(
            width: double.infinity,
            height: 88,
            borderRadius: kCardRadius,
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 3 ? 0 : 12),
                  child: const SkeletonBox(
                    width: double.infinity,
                    height: 56,
                    borderRadius: kCardRadius,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SkeletonBox(width: 160, height: 18),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => const SkeletonBox(
              width: 108,
              height: 140,
              borderRadius: kCardRadius,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SkeletonBox(width: 160, height: 18),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 316,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => const SkeletonBox(
              width: 196,
              height: 316,
              borderRadius: kCardRadius,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.onSeeAll});

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(kCardRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _mutedInk = Color(0xFF6B7A7A);

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greeting,
    required this.firstName,
    this.image,
  });

  final String greeting;
  final String firstName;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: const TextStyle(
                        color: _mutedInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkTealBackground,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: _mutedInk,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const NotificationBell(color: darkTealBackground),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: 'Your profile',
                child: GestureDetector(
                  onTap: () => context.go('/home/profile'),
                  child: UserAvatar(
                    url: image,
                    kind: AvatarKind.patient,
                    radius: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _PromoCarousel(),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _HeroSearchBar(),
        ),
      ],
    );
  }
}

class _Promo {
  const _Promo({
    required this.image,
    required this.tagIcon,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.route,
  });

  final String image;
  final IconData tagIcon;
  final String tag;
  final String title;
  final String subtitle;
  final String cta;
  final String route;
}

const _promos = [
  _Promo(
    image: 'assets/images/home_slides/slide-app.webp',
    tagIcon: Icons.monitor_heart_outlined,
    tag: 'Ask Musawo',
    title: 'Ask Musawo',
    subtitle: 'Healthcare, simplified',
    cta: 'Explore now',
    route: '/search',
  ),
  _Promo(
    image: 'assets/images/home_slides/slide-doctor.webp',
    tagIcon: Icons.verified_outlined,
    tag: 'Verified doctors',
    title: 'See a doctor today',
    subtitle: 'Licensed specialists near you',
    cta: 'Book a visit',
    route: '/search',
  ),
  _Promo(
    image: 'assets/images/home_slides/slide-ai.webp',
    tagIcon: Icons.auto_awesome,
    tag: 'AI assistant',
    title: 'Not sure who to see?',
    subtitle: 'Describe how you feel',
    cta: 'Ask AI',
    route: '/ai-search',
  ),
];

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final promo in _promos) {
      precacheImage(AssetImage(promo.image), context);
    }
  }

  void _startAutoplay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _promos.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth - 40;
            return SizedBox(
              height: cardWidth * 0.64,
              child: NotificationListener<ScrollStartNotification>(
                // A manual swipe restarts the countdown so autoplay doesn't
                // yank the page away right after the patient chose it.
                onNotification: (n) {
                  if (n.dragDetails != null) _startAutoplay();
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _promos.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _PromoSlide(promo: _promos[i], width: cardWidth),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _promos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page
                      ? seedTeal
                      : seedTeal.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(kCardRadius),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({required this.promo, required this.width});

  final _Promo promo;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textWidth = width * 0.56 - 20;
    return ClipRRect(
      borderRadius: BorderRadius.circular(kCardRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0E6E6F)),
          Image.asset(
            promo.image,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.35),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              // Scales the text block down on narrow phones instead of
              // overflowing the fixed-ratio card.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: textWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(kCardRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(promo.tagIcon, size: 15, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              promo.tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        promo.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: () => context.push(promo.route),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: darkTealBackground,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kCardRadius),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                promo.cta,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSearchBar extends StatelessWidget {
  const _HeroSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: seedTeal.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: seedTeal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: const Text(
                'Search doctors, symptoms...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black45, fontSize: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/ai-search'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: seedTeal,
                borderRadius: BorderRadius.circular(kCardRadius),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.appointmentsAsync});

  final AsyncValue<List<Appointment>> appointmentsAsync;

  Appointment? _nextUpcoming(List<Appointment> appointments) {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final active =
        appointments
            .where(
              (a) =>
                  a.status == 'confirmed' ||
                  a.status == 'scheduled' ||
                  a.status == 'requested',
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    if (active.isEmpty) return null;
    return active.firstWhere(
      (a) => !a.date.isBefore(dayStart),
      orElse: () => active.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return appointmentsAsync.when(
      data: (appointments) {
        final next = _nextUpcoming(appointments);
        return next == null
            ? const _NoAppointmentCard()
            : _UpcomingAppointmentCard(appointment: next);
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SkeletonBox(
          width: double.infinity,
          height: 118,
          borderRadius: kCardRadius,
        ),
      ),
      error: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _NoAppointmentCard(),
      ),
    );
  }
}

class _UpcomingAppointmentCard extends ConsumerWidget {
  const _UpcomingAppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = appointment.status == 'requested';
    final dateLabel = DateFormat('EEE, MMM d, yyyy').format(appointment.date);
    final doctor = appointment.doctorId == null
        ? null
        : ref.watch(doctorDetailProvider(appointment.doctorId!)).asData?.value;
    final specialty =
        doctor?.specialization ?? doctor?.department ?? appointment.department;

    final pillBg = isPending ? const Color(0xFFFF9800) : seedTeal;
    final pillFg = isPending ? const Color(0xFF2B1A00) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/home/appointments'),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  height: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    child: DoctorImage(
                      url: doctor?.image,
                      name: appointment.doctorName,
                      gender: doctor?.gender,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(kCardRadius),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPending
                                    ? Icons.schedule_rounded
                                    : Icons.event_available_rounded,
                                size: 13,
                                color: pillFg,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPending ? 'Pending approval' : 'Confirmed',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: pillFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appointment.doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: darkTealBackground,
                        ),
                      ),
                      if (specialty != null)
                        Text(
                          specialty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF6B7A7A),
                          ),
                        ),
                      const SizedBox(height: 8),
                      _InfoLine(
                        icon: Icons.calendar_month_outlined,
                        text: dateLabel,
                        bold: true,
                      ),
                      const SizedBox(height: 4),
                      _InfoLine(
                        icon: Icons.schedule_rounded,
                        text: appointment.time ?? 'Time to be confirmed',
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 44),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: darkTealBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F5F4),
                borderRadius: BorderRadius.circular(kCardRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: seedTeal, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPending
                              ? 'Your appointment is awaiting confirmation.'
                              : 'Your appointment is confirmed.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B5F60),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPending
                              ? "We'll notify you once it's approved."
                              : 'See you on $dateLabel.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF4A5A5A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.bold = false});

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: seedTeal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? darkTealBackground : const Color(0xFF55605F),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoAppointmentCard extends StatelessWidget {
  const _NoAppointmentCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _FlatCard(
        padding: const EdgeInsets.all(18),
        onTap: () => context.push('/search'),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: seedTeal,
                borderRadius: BorderRadius.circular(kCardRadius),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book your next visit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Consult a trusted doctor in minutes',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatCard extends StatelessWidget {
  const _FlatCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _QuickActionTile(
        label: 'Book visit',
        subtitle: 'Find and book a doctor',
        icon: Icons.calendar_month_rounded,
        artwork: 'calendar',
        accent: brandAccent,
        onTap: () => context.push('/search'),
      ),
      _QuickActionTile(
        label: 'AI assistant',
        subtitle: 'Get health advice instantly',
        icon: Icons.auto_awesome_rounded,
        artwork: 'sparkles',
        accent: brandAccent,
        onTap: () => context.push('/ai-search'),
      ),
      _QuickActionTile(
        label: 'Messages',
        subtitle: 'Chat with your doctor',
        icon: Icons.chat_bubble_rounded,
        artwork: 'chat',
        accent: brandAccent,
        onTap: () => context.push('/home/chats'),
      ),
      _QuickActionTile(
        label: 'Appointments',
        subtitle: 'View and manage your visits',
        icon: Icons.fact_check_rounded,
        artwork: 'calendar_check',
        accent: brandAccent,
        onTap: () => context.push('/home/appointments'),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (var row = 0; row < tiles.length; row += 2) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: tiles[row]),
                const SizedBox(width: 12),
                Expanded(child: tiles[row + 1]),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A 2×2 quick-action card: pastel accent surface, a solid icon badge, and a
/// faint tinted illustration (assets/images/quick_actions/) in the corner.
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.artwork,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String artwork;
  final SpecialtyAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark
        ? accent.foreground.withValues(alpha: 0.14)
        : accent.background;
    return Semantics(
      button: true,
      label: '$label. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 148,
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: 104,
                  child: Opacity(
                    opacity: dark ? 0.22 : 0.3,
                    child: Image.asset(
                      'assets/images/quick_actions/$artwork.webp',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent.foreground,
                              borderRadius: BorderRadius.circular(kCardRadius),
                            ),
                            child: Icon(icon, color: Colors.white, size: 24),
                          ),
                          const Spacer(),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: accent.foreground.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: dark
                                  ? accent.foreground
                                  : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps a doctor's specialization/department text to a representative icon
/// for the small badge on their featured card. Best-effort keyword match
/// against real doctor data — falls back to a generic medical icon rather
/// than inventing a specialty.
class _FeaturedDoctorCard extends ConsumerWidget {
  const _FeaturedDoctorCard({required this.doctor});

  final Doctor doctor;

  void _openDoctor(BuildContext context, WidgetRef ref) {
    prefetchDoctorDetail(ref, doctor.id);
    context.push('/doctors/${doctor.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final feeFormat = NumberFormat.decimalPattern();
    final rating = doctor.rating;
    final specialtyLabel =
        doctor.specialization ?? doctor.department ?? 'General';
    final accent = specialtyAccent(doctor.specialization);

    return SizedBox(
      width: 196,
      child: SoftCard(
        padding: EdgeInsets.zero,
        onTap: () => _openDoctor(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kCardRadius),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DoctorImage(
                      url: doctor.image,
                      name: doctor.name,
                      gender: doctor.gender,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          iconForSpecialization(
                            doctor.specialization,
                            doctor.department,
                          ),
                          size: 16,
                          color: accent.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                letterSpacing: -0.2,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              specialtyLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(kCardRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating != null
                                  ? '${rating.toStringAsFixed(1)} (${doctor.reviewCount})'
                                  : 'New',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8A5A00),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (doctor.consultationFee != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.sell_rounded,
                          size: 14,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'UGX ${feeFormat.format(doctor.consultationFee)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: FilledButton.icon(
                      onPressed: () => _openDoctor(context, ref),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kCardRadius),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: const Text('Book Appointment'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
