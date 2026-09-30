import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One saved API response.
class CacheEntry {
  CacheEntry({required this.savedAt, required this.data});

  final DateTime savedAt;
  final Object? data;

  Duration get age => DateTime.now().difference(savedAt);

  Response<dynamic> toResponse(RequestOptions options) => Response(
    requestOptions: options,
    statusCode: 200,
    data: data,
    extra: {'fromCache': true, 'cachedAt': savedAt},
  );

  Map<String, Object?> toJson() => {
    'savedAt': savedAt.toIso8601String(),
    'data': data,
  };

  static CacheEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    if (savedAt == null) return null;
    return CacheEntry(savedAt: savedAt, data: json['data']);
  }
}

/// Disk-backed store of the last successful response for each GET request,
/// so every screen has something to show offline and can render instantly
/// on the next launch.
///
/// Entries live in memory once read and in one small JSON file each under
/// the app-support directory (web keeps them in memory only). The whole
/// store belongs to the signed-in user and is wiped on sign in/out.
class OfflineCache {
  OfflineCache._(this._dir);

  /// A cache that never touches disk — for tests.
  OfflineCache.inMemory() : _dir = null;

  final Directory? _dir;
  final _memory = <String, CacheEntry>{};

  /// Set after any successful write request (POST/PUT/PATCH/DELETE):
  /// anything saved before it might no longer match the server, so reads
  /// go to the network first instead of trusting the saved copy.
  DateTime? _changedSince;

  static Future<OfflineCache> open() async {
    if (kIsWeb) return OfflineCache.inMemory();
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/offline_cache');
    await dir.create(recursive: true);
    return OfflineCache._(dir);
  }

  File _file(String key) => File('${_dir!.path}/${_hash(key)}.json');

  Future<CacheEntry?> read(String key) async {
    final cached = _memory[key];
    if (cached != null || _dir == null) return cached;
    try {
      final file = _file(key);
      if (!await file.exists()) return null;
      final entry = CacheEntry.fromJson(jsonDecode(await file.readAsString()));
      if (entry != null) _memory[key] = entry;
      return entry;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Object? data) async {
    final entry = CacheEntry(savedAt: DateTime.now(), data: data);
    _memory[key] = entry;
    if (_dir == null) return;
    try {
      await _file(key).writeAsString(jsonEncode(entry.toJson()));
    } catch (_) {
      // Disk full / unencodable body — the in-memory copy still works for
      // this session.
    }
  }

  void markChanged() => _changedSince = DateTime.now();

  bool isOutdated(CacheEntry entry) =>
      _changedSince != null && entry.savedAt.isBefore(_changedSince!);

  Future<void> clear() async {
    _memory.clear();
    _changedSince = null;
    if (_dir == null) return;
    try {
      await for (final file in _dir.list()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Two FNV-1a (32-bit) passes with different seeds — a stable,
  /// filename-safe name for a cache key. (Only used on native, where int
  /// arithmetic is exact.)
  static String _hash(String key) {
    final bytes = utf8.encode(key);
    String fnv(int seed) {
      var hash = seed;
      for (final unit in bytes) {
        hash = ((hash ^ unit) * 16777619) & 0xFFFFFFFF;
      }
      return hash.toRadixString(16).padLeft(8, '0');
    }

    return '${fnv(2166136261)}${fnv(0x811C9DC5 ^ 0x5bd1e995)}';
  }
}
