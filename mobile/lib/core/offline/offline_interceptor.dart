import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'network_status.dart';
import 'offline_cache.dart';

/// How a GET should use the [OfflineCache], set per provider build by
/// `offlineFirst()` through a zone value (see offline_first.dart).
enum CachePolicy {
  /// Show the saved copy immediately and refresh it in the background.
  /// Used when a screen first mounts, so it renders instantly.
  cacheFirst,

  /// Ask the server, and fall back to the saved copy only if it can't be
  /// reached. Used for explicit refreshes (pull-to-refresh, invalidation
  /// after a change) and for any request made outside a provider.
  networkFirst,
}

/// Registered by `offlineFirst()` for the duration of one provider build;
/// the interceptor calls [refresh] when it has newer data than what the
/// provider was given.
class OfflineWatcher {
  OfflineWatcher(this.policy, this._refresh);

  final CachePolicy policy;
  final void Function() _refresh;
  bool _disposed = false;

  void refresh() {
    if (!_disposed) _refresh();
  }

  void dispose() => _disposed = true;
}

const offlineWatcherZoneKey = #askMusawoOfflineWatcher;

/// True when [error] means the server couldn't be reached at all (no
/// network, DNS failure, timeout) — as opposed to the server answering
/// with an error.
bool isUnreachableError(Object error) {
  if (error is! DioException) return false;
  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    DioExceptionType.unknown => !kIsWeb && error.error is SocketException,
    _ => false,
  };
}

/// GET requests whose answer must be live — never served from the cache.
final _neverCache = [
  RegExp(r'^/api/auth/'),
  RegExp(r'^/api/payments/quote'),
  RegExp(r'^/api/payments/[^/]+/status'),
  RegExp(r'^/api/users/[^/]+/online'),
];

/// Makes every GET work offline:
///
/// - successful JSON responses are saved to the [OfflineCache];
/// - when the server can't be reached, the saved copy is returned instead
///   of an error (and instantly, without waiting for a timeout, when the
///   device is already known to be offline);
/// - inside `offlineFirst()` providers, a screen's first load is served
///   from the cache straight away and revalidated in the background.
///
/// Any successful write marks the cache as possibly outdated so the next
/// reads go to the network first. Opt a request out with
/// `Options(extra: {'offline': false})`.
class OfflineInterceptor extends Interceptor {
  OfflineInterceptor({
    required this.dio,
    required this.cache,
    required this.network,
  }) {
    network.onReconnect.listen((_) => _refreshStaleWatchers());
  }

  final Dio dio;
  final OfflineCache cache;
  final NetworkStatus network;

  /// Saved copies younger than this aren't revalidated on a cache-first
  /// load — it's the same data we just fetched.
  static const _freshFor = Duration(seconds: 20);

  static const _keyExtra = 'offlineKey';
  static const _revalidatingExtra = 'offlineRevalidating';

  /// Revalidations in flight, keyed by cache key, with every watcher
  /// waiting on each (several providers can share one endpoint).
  final _revalidating = <String, Set<OfflineWatcher>>{};

  /// Keys a background revalidation just refreshed, with when. The
  /// provider rebuild that follows is served the new saved copy rather
  /// than fetching the same data a second time.
  final _justRevalidated = <String, DateTime>{};

  /// Watchers that were handed a saved copy because we were offline — they
  /// refresh as soon as the connection comes back.
  final _staleWatchers = <OfflineWatcher>{};

  bool _cacheable(RequestOptions options) =>
      options.method == 'GET' &&
      options.extra['offline'] != false &&
      !_neverCache.any((pattern) => pattern.hasMatch(options.path));

  static String _key(RequestOptions options) {
    final query =
        options.queryParameters.entries
            .where((e) => e.value != null)
            .map((e) => '${e.key}=${e.value}')
            .toList()
          ..sort();
    return '${options.path}?${query.join('&')}';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_cacheable(options) || options.extra[_revalidatingExtra] == true) {
      return handler.next(options);
    }
    final key = _key(options);
    options.extra[_keyExtra] = key;

    final entry = await cache.read(key);
    if (entry == null) return handler.next(options);

    final watcher = Zone.current[offlineWatcherZoneKey] as OfflineWatcher?;

    if (network.isOffline) {
      if (watcher != null) _staleWatchers.add(watcher);
      return handler.resolve(entry.toResponse(options));
    }

    final revalidatedAt = _justRevalidated[key];
    if (watcher != null &&
        revalidatedAt != null &&
        DateTime.now().difference(revalidatedAt) < const Duration(seconds: 3)) {
      return handler.resolve(entry.toResponse(options));
    }

    if (watcher?.policy == CachePolicy.cacheFirst && !cache.isOutdated(entry)) {
      if (entry.age > _freshFor) _revalidate(options, key, entry, watcher!);
      return handler.resolve(entry.toResponse(options));
    }

    // Network first — but with a saved copy to fall back on, don't make
    // the user wait out the full timeout on a dead connection.
    options.connectTimeout = const Duration(seconds: 6);
    options.receiveTimeout = const Duration(seconds: 10);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    network.reportReachable();
    final options = response.requestOptions;
    final status = response.statusCode ?? 0;
    final ok = status >= 200 && status < 300;

    if (ok && options.method != 'GET') cache.markChanged();

    final key = options.extra[_keyExtra] as String?;
    final data = response.data;
    if (ok && key != null && (data is Map || data is List)) {
      cache.write(key, data);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!isUnreachableError(err)) return handler.next(err);
    network.reportUnreachable();

    final options = err.requestOptions;
    final key = options.extra[_keyExtra] as String?;
    if (key == null || options.extra[_revalidatingExtra] == true) {
      return handler.next(err);
    }
    final entry = await cache.read(key);
    if (entry == null) return handler.next(err);

    final watcher = Zone.current[offlineWatcherZoneKey] as OfflineWatcher?;
    if (watcher != null) _staleWatchers.add(watcher);
    handler.resolve(entry.toResponse(options));
  }

  void _revalidate(
    RequestOptions options,
    String key,
    CacheEntry previous,
    OfflineWatcher watcher,
  ) {
    final waiting = _revalidating[key];
    if (waiting != null) {
      waiting.add(watcher);
      return;
    }
    final watchers = _revalidating[key] = {watcher};
    final request = options.copyWith(
      extra: {...options.extra, _revalidatingExtra: true},
    );
    dio
        .fetch<dynamic>(request)
        .then((response) {
          final status = response.statusCode ?? 0;
          if (status < 200 || status >= 300) return;
          if (jsonEncode(response.data) == jsonEncode(previous.data)) return;
          _justRevalidated[key] = DateTime.now();
          for (final w in watchers) {
            w.refresh();
          }
        })
        .catchError((Object _) {
          // Offline or failed — the saved copy stays on screen and the
          // watcher refreshes on reconnect.
          _staleWatchers.addAll(watchers);
        })
        .whenComplete(() => _revalidating.remove(key));
  }

  void _refreshStaleWatchers() {
    final watchers = _staleWatchers.toList();
    _staleWatchers.clear();
    for (final watcher in watchers) {
      watcher.refresh();
    }
  }
}
