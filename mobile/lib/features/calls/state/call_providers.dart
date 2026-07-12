import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/call_repository.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(ref.watch(dioProvider));
});

final myCallsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(callRepositoryProvider).listMine();
});
