import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../data/doctor.dart';
import '../state/doctor_providers.dart';

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
              loading: () => const Center(child: CircularProgressIndicator()),
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

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final feeFormat = NumberFormat.decimalPattern();
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.push('/doctors/${doctor.id}'),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: doctor.image != null ? NetworkImage(doctor.image!) : null,
          child: doctor.image == null ? const Icon(Icons.person) : null,
        ),
        title: Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor.specialization ?? doctor.department ?? 'General'),
            if (doctor.hospitalName != null)
              Text(
                doctor.hospitalName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  doctor.rating != null
                      ? '${doctor.rating!.toStringAsFixed(1)} (${doctor.reviewCount})'
                      : 'New',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (doctor.consultationFee != null) ...[
                  const Text('  ·  ', style: TextStyle(fontSize: 12)),
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
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
