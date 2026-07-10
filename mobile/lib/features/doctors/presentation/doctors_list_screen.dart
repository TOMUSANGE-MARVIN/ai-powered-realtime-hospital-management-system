import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/doctor.dart';
import '../state/doctor_providers.dart';

class DoctorsListScreen extends ConsumerStatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  ConsumerState<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends ConsumerState<DoctorsListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

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
      appBar: AppBar(title: const Text('Find a doctor')),
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
                border: OutlineInputBorder(),
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
                      onTap: () => ref.read(selectedSpecialtyProvider.notifier).state = null,
                    ),
                    ...specialties.map(
                      (s) => _SpecialtyChip(
                        label: '${s.name} (${s.count})',
                        selected: selectedSpecialty == s.name,
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
  const _SpecialtyChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.push('/doctors/${doctor.id}'),
        leading: CircleAvatar(
          backgroundImage: doctor.image != null ? NetworkImage(doctor.image!) : null,
          child: doctor.image == null ? const Icon(Icons.person) : null,
        ),
        title: Text(doctor.name),
        subtitle: Text(doctor.specialization ?? doctor.department ?? 'General'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
