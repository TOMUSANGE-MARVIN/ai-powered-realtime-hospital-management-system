import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../../appointments/data/appointment.dart';
import '../../appointments/state/appointment_providers.dart';
import '../../auth/state/auth_controller.dart';
import '../../doctors/data/doctor.dart';
import '../../doctors/presentation/category_card.dart';
import '../../doctors/state/doctor_providers.dart';

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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesWithCountsProvider);
            ref.invalidate(featuredDoctorsProvider);
            ref.invalidate(myAppointmentsProvider);
          },
          child: ListView(
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
              const _QuickActions(),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Browse specialties',
                onSeeAll: () => context.push('/categories'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 108,
                child: categoriesAsync.when(
                  data: (categories) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => CategoryCard(
                      category: categories[index].category,
                      count: categories[index].count,
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('Could not load categories')),
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
                      return const Center(child: Text('No doctors available yet'));
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(error.toString())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
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
            child: Text(
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
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(12),
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
                    Icon(Icons.arrow_forward_rounded, size: 16, color: scheme.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: seedTeal,
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _DecorativeBlob(size: 160),
            ),
            Positioned(
              bottom: -70,
              left: -30,
              child: _DecorativeBlob(size: 180),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              firstName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _HeroAvatar(image: image),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HeroSearchBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeBlob extends StatelessWidget {
  const _DecorativeBlob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 27.5,
      backgroundColor: Colors.white,
      backgroundImage: image != null ? NetworkImage(image!) : null,
      child: image == null
          ? const Icon(Icons.person_rounded, size: 30, color: seedTeal)
          : null,
    );
  }
}

class _HeroSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                borderRadius: BorderRadius.circular(10),
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
    final active = appointments
        .where((a) => a.status == 'confirmed' || a.status == 'scheduled' || a.status == 'requested')
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
        child: SizedBox(height: 118, child: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _NoAppointmentCard(),
      ),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard({required this.appointment});

  final Appointment appointment;

  String get _statusLabel {
    switch (appointment.status) {
      case 'requested':
        return 'Pending approval';
      case 'confirmed':
      case 'scheduled':
        return 'Confirmed';
      default:
        return appointment.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEE, MMM d').format(appointment.date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _FlatCard(
        padding: const EdgeInsets.all(18),
        onTap: () => context.push('/home/appointments'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: seedTeal,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                appointment.isVirtual
                    ? Icons.videocam_rounded
                    : Icons.medical_services_rounded,
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
                    appointment.doctorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${appointment.time ?? 'Time to be confirmed'} · $dateLabel',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusChip(label: _statusLabel),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPending = label == 'Pending approval';
    final bg = isPending
        ? Colors.amber.withValues(alpha: 0.18)
        : scheme.primary.withValues(alpha: 0.12);
    final fg = isPending ? const Color(0xFFB26A00) : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: fg,
        ),
      ),
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
                borderRadius: BorderRadius.circular(18),
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
              child: Icon(Icons.arrow_forward_rounded, size: 18, color: scheme.primary),
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
        borderRadius: BorderRadius.circular(24),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _QuickActionTile(
            label: 'Book visit',
            icon: Icons.calendar_month_rounded,
            accent: accentForColorKey('teal'),
            onTap: () => context.push('/search'),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            label: 'AI assistant',
            icon: Icons.auto_awesome_rounded,
            accent: accentForColorKey('pink'),
            onTap: () => context.push('/ai-search'),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            label: 'Messages',
            icon: Icons.chat_bubble_rounded,
            accent: accentForColorKey('blue'),
            onTap: () => context.push('/home/chats'),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            label: 'Appointments',
            icon: Icons.fact_check_rounded,
            accent: accentForColorKey('purple'),
            onTap: () => context.push('/home/appointments'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final SpecialtyAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: accent.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent.foreground, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps a doctor's specialization/department text to a representative icon
/// for the small badge on their featured card. Best-effort keyword match
/// against real doctor data — falls back to a generic medical icon rather
/// than inventing a specialty.
IconData _iconForSpecialization(String? specialization, String? department) {
  final text = (specialization ?? department ?? '').toLowerCase();
  if (text.contains('cardio')) return Icons.favorite_rounded;
  if (text.contains('pediatric') || text.contains('paediatric')) {
    return Icons.child_care_rounded;
  }
  if (text.contains('orthop')) return Icons.accessibility_new_rounded;
  if (text.contains('obstetric') || text.contains('gynec') || text.contains('gynaec')) {
    return Icons.pregnant_woman_rounded;
  }
  if (text.contains('emergency')) return Icons.emergency_rounded;
  if (text.contains('neuro')) return Icons.psychology_rounded;
  if (text.contains('derma')) return Icons.face_retouching_natural_rounded;
  if (text.contains('dental') || text.contains('dentist')) {
    return Icons.sentiment_satisfied_alt_rounded;
  }
  if (text.contains('internal medicine') || text.contains('general')) {
    return Icons.monitor_heart_rounded;
  }
  return Icons.local_hospital_rounded;
}

class _FeaturedDoctorCard extends StatelessWidget {
  const _FeaturedDoctorCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final feeFormat = NumberFormat.decimalPattern();
    final rating = doctor.rating;
    final specialtyLabel = doctor.specialization ?? doctor.department ?? 'General';
    final accent = specialtyAccent(doctor.specialization);

    return SizedBox(
      width: 196,
      child: SoftCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/doctors/${doctor.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(kCardRadius)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _DoctorImage(url: doctor.image, name: doctor.name),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.background,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconForSpecialization(doctor.specialization, doctor.department),
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
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
                        Icon(Icons.sell_rounded, size: 14, color: scheme.primary),
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
                      onPressed: () => context.push('/doctors/${doctor.id}'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
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

/// Renders a doctor's uploaded profile photo, or a neutral initials avatar
/// when no image has been set (or it fails to load) — never a stock photo.
class _DoctorImage extends StatelessWidget {
  const _DoctorImage({required this.url, required this.name});

  final String? url;
  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: seedTeal.withValues(alpha: 0.08),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: seedTeal),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: seedTeal.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: seedTeal,
        ),
      ),
    );
  }
}
