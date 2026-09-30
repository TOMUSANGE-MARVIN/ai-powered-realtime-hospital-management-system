import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../../core/offline/offline_first.dart';
import '../data/call_repository.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(ref.watch(dioProvider));
});

final myCallsProvider = FutureProvider.autoDispose((ref) {
  return offlineFirst(ref, () => ref.watch(callRepositoryProvider).listMine());
});
