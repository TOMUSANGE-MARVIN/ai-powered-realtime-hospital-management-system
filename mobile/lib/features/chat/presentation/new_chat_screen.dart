import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../appointments/state/appointment_providers.dart';
import '../../auth/state/auth_controller.dart';
import '../../doctors/data/doctor.dart';
import '../../doctors/state/doctor_providers.dart';
import '../data/chat_args.dart';

/// Who you can start a new chat with:
/// - Patients pick from the doctor directory (same search as booking).
/// - Doctors pick from patients who've actually booked with them — a doctor
///   shouldn't be able to message an arbitrary stranger.
class NewChatScreen extends ConsumerWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDoctor = ref.watch(authControllerProvider).value?.role == 'doctor';
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: isDoctor ? const _PatientPicker() : const _DoctorPicker(),
    );
  }
}

class _DoctorPicker extends ConsumerStatefulWidget {
  const _DoctorPicker();

  @override
  ConsumerState<_DoctorPicker> createState() => _DoctorPickerState();
}

class _DoctorPickerState extends ConsumerState<_DoctorPicker> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(_searchedDoctorsProvider(_query));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              hintText: 'Search doctors by name',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: doctorsAsync.when(
            data: (doctors) {
              if (doctors.isEmpty) {
                return const Center(child: Text('No doctors found'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: doctor.image != null ? NetworkImage(doctor.image!) : null,
                      child: doctor.image == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(doctor.name),
                    subtitle: Text(doctor.specialization ?? doctor.department ?? 'General'),
                    onTap: () => context.pushReplacement(
                      '/chat/${doctor.id}',
                      extra: ChatArgs(name: doctor.name, image: doctor.image),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
        ),
      ],
    );
  }
}

final _searchedDoctorsProvider =
    FutureProvider.autoDispose.family<List<Doctor>, String>((ref, query) {
  return ref.watch(doctorRepositoryProvider).listDoctors(search: query);
});

class _PatientPicker extends ConsumerWidget {
  const _PatientPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(allAssignedAppointmentsProvider);
    return appointmentsAsync.when(
      data: (appointments) {
        final seen = <String>{};
        final patients = <({String id, String name})>[];
        for (final a in appointments) {
          if (a.patientId == null || !seen.add(a.patientId!)) continue;
          patients.add((id: a.patientId!, name: a.patientName ?? 'Patient'));
        }
        if (patients.isEmpty) {
          return const Center(child: Text('No patients to message yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(patient.name),
              onTap: () => context.pushReplacement(
                '/chat/${patient.id}',
                extra: ChatArgs(name: patient.name),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}
