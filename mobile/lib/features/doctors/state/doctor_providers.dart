import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/providers.dart';
import '../data/ai_search_repository.dart';
import '../data/doctor.dart';
import '../data/doctor_repository.dart';
import '../data/review.dart';
import '../data/review_repository.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(dioProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(dioProvider));
});

final aiSearchRepositoryProvider = Provider<AiSearchRepository>((ref) {
  return AiSearchRepository(ref.watch(dioProvider));
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

/// Top-rated doctors for the home dashboard's featured carousel.
final featuredDoctorsProvider = FutureProvider.autoDispose<List<Doctor>>((ref) {
  return ref.watch(doctorRepositoryProvider).listDoctors(featured: true, limit: 10);
});

final doctorReviewsProvider =
    FutureProvider.autoDispose.family<DoctorReviews, String>((ref, doctorId) {
  return ref.watch(reviewRepositoryProvider).listForDoctor(doctorId);
});
