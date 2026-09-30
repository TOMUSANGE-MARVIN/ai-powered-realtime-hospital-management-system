import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_interceptor.dart';

/// Runs a provider's fetch so its GET requests work offline-first:
///
/// - on first build (screen mounting, app launch) the saved copy is shown
///   instantly and quietly refreshed in the background — no skeleton at all
///   once a screen has been seen before;
/// - on an explicit refresh (pull-to-refresh, `ref.invalidate` after a
///   change, socket events) the server is asked first, falling back to the
///   saved copy when offline;
/// - whenever newer data arrives later (background refresh finishing, or the
///   connection coming back) the provider rebuilds itself, keeping the old
///   data on screen meanwhile (a refresh, not a reload, so `.when` keeps
///   showing data rather than the loading skeleton).
///
/// ```dart
/// final myThingsProvider = FutureProvider((ref) =>
///     offlineFirst(ref, () => ref.watch(thingRepositoryProvider).list()));
/// ```
Future<T> offlineFirst<T>(Ref ref, Future<T> Function() fetch) {
  final watcher = OfflineWatcher(
    ref.isRefresh ? CachePolicy.networkFirst : CachePolicy.cacheFirst,
    () {
      if (ref.mounted) ref.invalidateSelf();
    },
  );
  ref.onDispose(watcher.dispose);
  return runZoned(fetch, zoneValues: {offlineWatcherZoneKey: watcher});
}
