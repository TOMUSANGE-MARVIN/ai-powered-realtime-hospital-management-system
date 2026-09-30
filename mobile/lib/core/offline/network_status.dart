import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Whether the app can currently reach the API, combining two signals:
///
/// - the OS connectivity state (no Wi-Fi/mobile data at all), which flips
///   instantly, and
/// - the outcome of real requests, which catches "connected to Wi-Fi but no
///   internet" and the server itself being unreachable.
///
/// While the server is unreachable a cheap probe runs every few seconds, so
/// the app notices recovery even if the user isn't doing anything.
/// [onReconnect] fires on every offline → online transition, which is when
/// stale screens revalidate and queued chat messages are sent.
class NetworkStatus extends ChangeNotifier {
  NetworkStatus(this._baseUrl);

  final String _baseUrl;
  final _connectivity = Connectivity();
  final _reconnects = StreamController<void>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _probeTimer;

  bool _deviceOffline = false;
  bool _serverUnreachable = false;

  bool get isOffline => _deviceOffline || _serverUnreachable;

  Stream<void> get onReconnect => _reconnects.stream;

  Future<void> start() async {
    try {
      _deviceOffline = _isNone(await _connectivity.checkConnectivity());
    } catch (_) {
      // Some platforms (e.g. desktop test runners) have no connectivity
      // plugin — fall back to request outcomes alone.
    }
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final none = _isNone(results);
      _update(() {
        _deviceOffline = none;
        // A network change invalidates what we learned from the last
        // failed request — let the next probe/request decide again.
        if (!none && _serverUnreachable) _probeSoon();
      });
    });
  }

  static bool _isNone(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  /// Called by the offline interceptor after any request reached the server.
  void reportReachable() {
    if (!_serverUnreachable) return;
    _update(() => _serverUnreachable = false);
  }

  /// Called by the offline interceptor when a request couldn't reach the
  /// server at all (DNS, socket, timeout).
  void reportUnreachable() {
    if (_serverUnreachable) return;
    _update(() => _serverUnreachable = true);
  }

  void _update(void Function() change) {
    final wasOffline = isOffline;
    change();
    if (wasOffline == isOffline) return;
    if (isOffline) {
      _startProbing();
    } else {
      _probeTimer?.cancel();
      _reconnects.add(null);
    }
    notifyListeners();
  }

  void _startProbing() {
    _probeTimer?.cancel();
    _probeTimer = Timer.periodic(const Duration(seconds: 8), (_) => _probe());
  }

  void _probeSoon() => Timer(const Duration(milliseconds: 600), _probe);

  bool _probing = false;

  /// Any HTTP response at all (even a 404) proves the server is reachable.
  Future<void> _probe() async {
    if (_probing || _deviceOffline || !_serverUnreachable) return;
    _probing = true;
    try {
      await Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (_) => true,
        ),
      ).head('/');
      reportReachable();
    } catch (_) {
      // Still unreachable — the periodic timer tries again.
    } finally {
      _probing = false;
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _probeTimer?.cancel();
    _reconnects.close();
    super.dispose();
  }
}
