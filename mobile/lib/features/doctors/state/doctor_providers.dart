import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/providers.dart';
import '../data/doctor.dart';
import '../data/doctor_repository.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(dioProvider));
});

final doctorSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedSpecialtyProvider = StateProvider<String?>((ref) => null);

final specialtiesProvider = FutureProvider<List<Specialty>>((ref) {
  return ref.watch(doctorRepositoryProvider).listSpecialties();
});

final doctorsListProvider = FutureProvider.autoDispose<List<Doctor>>((ref) {
  final search = ref.watch(doctorSearchQueryProvider);
  final specialty = ref.watch(selectedSpecialtyProvider);
  return ref
      .watch(doctorRepositoryProvider)
      .listDoctors(search: search, specialization: specialty);
});

final doctorDetailProvider = FutureProvider.autoDispose.family<Doctor, String>((ref, id) {
  return ref.watch(doctorRepositoryProvider).getDoctor(id);
});
