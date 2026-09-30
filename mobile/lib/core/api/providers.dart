import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/network_status.dart';
import '../offline/offline_cache.dart';
import 'api_client.dart';
import 'upload_repository.dart';

/// Overridden in `main.dart` once `ApiClient.create()` resolves, so the rest
/// of the app can depend on a plain, synchronously-readable Dio instance.
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('apiClientProvider must be overridden in main()');
});

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

final offlineCacheProvider = Provider<OfflineCache>(
  (ref) => ref.watch(apiClientProvider).cache,
);

final networkStatusProvider = Provider<NetworkStatus>(
  (ref) => ref.watch(apiClientProvider).network,
);

/// True while the API can't be reached — drives the offline banner and
/// lets screens explain why an action needs a connection.
final isOfflineProvider = Provider<bool>((ref) {
  final network = ref.watch(networkStatusProvider);
  void listener() => ref.invalidateSelf();
  network.addListener(listener);
  ref.onDispose(() => network.removeListener(listener));
  return network.isOffline;
});

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(dioProvider));
});
