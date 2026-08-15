import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/doctor.dart';
import '../state/doctor_providers.dart';
import 'doctor_card.dart';

class DoctorsListScreen extends ConsumerStatefulWidget {
  const DoctorsListScreen({super.key, this.initialSpecialty});

  /// Pre-selects a specialty chip when opened from a dashboard category.
  final String? initialSpecialty;

  @override
  ConsumerState<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends ConsumerState<DoctorsListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Providers can't be written during build; defer to the next frame. Also
    // reset any stale filter left behind by a previous visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedSpecialtyProvider.notifier).state = widget.initialSpecialty;
      ref.read(doctorSearchQueryProvider.notifier).state = '';
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(doctorSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsListProvider);
    final specialtiesAsync = ref.watch(specialtiesProvider);
    final selectedSpecialty = ref.watch(selectedSpecialtyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search doctors by name',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          specialtiesAsync.when(
            data: (specialties) {
              if (specialties.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _SpecialtyChip(
                      label: 'All',
                      selected: selectedSpecialty == null,
                      accent: null,
                      onTap: () => ref.read(selectedSpecialtyProvider.notifier).state = null,
                    ),
                    ...specialties.map(
                      (s) => _SpecialtyChip(
                        label: '${s.name} (${s.count})',
                        selected: selectedSpecialty == s.name,
                        accent: specialtyAccent(s.name),
                        onTap: () => ref.read(selectedSpecialtyProvider.notifier).state = s.name,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          Expanded(
            child: doctorsAsync.when(
              data: (doctors) {
                if (doctors.isEmpty) {
                  return const Center(child: Text('No doctors match your search'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(doctorsListProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: doctors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _DoctorTile(doctor: doctors[index]),
                  ),
                );
              },
              loading: () => const _DoctorCardSkeleton(),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final SpecialtyAccent? accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = accent?.foreground ?? scheme.primary;
    final bg = accent?.background ?? scheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(kPillRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? fg : bg,
            borderRadius: BorderRadius.circular(kPillRadius),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : fg,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorTile extends ConsumerWidget {
  const _DoctorTile({required this.doctor});

  final Doctor doctor;

  void _openDetails(BuildContext context, WidgetRef ref) {
    prefetchDoctorDetail(ref, doctor.id);
    context.push('/doctors/${doctor.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final feeFormat = NumberFormat.decimalPattern();
    final specialtyLabel = doctor.specialization ?? doctor.department ?? 'General';
    final accent = specialtyAccent(doctor.specialization);

    return SoftCard(
      padding: EdgeInsets.zero,
      onTap: () => _openDetails(context, ref),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    doctor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    specialtyLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (doctor.hospitalName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      doctor.hospitalName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RatingChip(rating: doctor.rating, reviewCount: doctor.reviewCount),
                      if (doctor.consultationFee != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.sell_rounded, size: 13, color: scheme.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'UGX ${feeFormat.format(doctor.consultationFee)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 88,
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DoctorImage(url: doctor.image, name: doctor.name),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                          iconForSpecialization(doctor.specialization, doctor.department),
                          size: 13,
                          color: accent.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right_rounded, size: 20, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.reviewCount});

  final double? rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                ? '${rating!.toStringAsFixed(1)} ($reviewCount)'
                : 'New',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A00),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCardSkeleton extends StatelessWidget {
  const _DoctorCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          const SkeletonBox(width: double.infinity, height: 136, borderRadius: kCardRadius),
    );
  }
}
