import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/state/auth_controller.dart';
import '../../doctors/data/doctor.dart';
import '../../doctors/presentation/category_card.dart';
import '../../doctors/state/doctor_providers.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final categoriesAsync = ref.watch(categoriesWithCountsProvider);
    final featuredAsync = ref.watch(featuredDoctorsProvider);
    final firstName = (user?.name ?? '').trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesWithCountsProvider);
            ref.invalidate(featuredDoctorsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                            'Hi, ${firstName.isEmpty ? 'there' : firstName} 👋',
                            style: const TextStyle(fontSize: 15, color: Colors.black54),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Let's Find Your Doctor",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      backgroundImage:
                          user?.image != null ? NetworkImage(user!.image!) : null,
                      child: user?.image == null
                          ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  readOnly: true,
                  onTap: () => context.push('/search'),
                  decoration: InputDecoration(
                    hintText: 'Search doctor, symptoms...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          tooltip: 'AI symptom search',
                          onPressed: () => context.push('/ai-search'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _PromoSlider(),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Categories',
                onSeeAll: () => context.push('/categories'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
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
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Featured Doctors',
                onSeeAll: () => context.push('/search'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 210,
                child: featuredAsync.when(
                  data: (doctors) {
                    if (doctors.isEmpty) {
                      return const Center(child: Text('No doctors available yet'));
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: doctors.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _FeaturedDoctorCard(doctor: doctors[index]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(error.toString())),
                ),
              ),
              const SizedBox(height: 16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

/// Auto-advancing promo banner carousel. Banners are theme-aware gradient
/// cards for now — swap in marketing images later without changing layout.
class _PromoSlider extends StatefulWidget {
  const _PromoSlider();

  @override
  State<_PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<_PromoSlider> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  static const _banners = [
    (
      title: 'Talk to a doctor anytime',
      subtitle: 'Book video, voice or in-person consultations',
      icon: Icons.video_call,
      gradient: heroGradient,
    ),
    (
      title: 'Emergency? Get help fast',
      subtitle: 'Mark your booking as an emergency for immediate attention',
      icon: Icons.emergency,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF7A7A), Color(0xFFB33939)],
      ),
    ),
    (
      title: 'Your health, organised',
      subtitle: 'Prescriptions, documents and billing in one place',
      icon: Icons.folder_shared,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6C5DD3), Color(0xFF4834D4)],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
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
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: banner.gradient,
                  borderRadius: BorderRadius.circular(kCardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: seedPurple.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            banner.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(banner.icon, size: 48, color: Colors.white.withValues(alpha: 0.85)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final active = index == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: active ? 18 : 6,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FeaturedDoctorCard extends StatelessWidget {
  const _FeaturedDoctorCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final feeFormat = NumberFormat.decimalPattern();
    return SoftCard(
      onTap: () => context.push('/doctors/${doctor.id}'),
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 32,
                backgroundImage:
                    doctor.image != null ? NetworkImage(doctor.image!) : null,
                child: doctor.image == null ? const Icon(Icons.person, size: 30) : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doctor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            Text(
              doctor.specialization ?? doctor.department ?? 'General',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star, size: 15, color: Colors.amber),
                const SizedBox(width: 3),
                Text(
                  doctor.rating != null
                      ? '${doctor.rating!.toStringAsFixed(1)} (${doctor.reviewCount})'
                      : 'New',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (doctor.consultationFee != null) ...[
              const SizedBox(height: 3),
              Text(
                'UGX ${feeFormat.format(doctor.consultationFee)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
