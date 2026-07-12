import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'upload_repository.dart';

/// Overridden in `main.dart` once `ApiClient.create()` resolves, so the rest
/// of the app can depend on a plain, synchronously-readable Dio instance.
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('apiClientProvider must be overridden in main()');
});

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(dioProvider));
});
