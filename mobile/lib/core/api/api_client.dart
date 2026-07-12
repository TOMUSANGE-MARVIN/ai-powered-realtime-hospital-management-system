import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Defaults to the production API. Override at build/run time with
// --dart-define=API_BASE_URL=http://10.0.2.2:5000 (Android emulator) or
// http://localhost:5000 (physical device over `adb reverse`) for local dev.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.askmusawo.mamacareug.xyz',
);

/// Thin wrapper around Dio that carries the better-auth session cookie.
///
/// On mobile the session cookie is persisted to disk via [PersistCookieJar]
/// so users stay logged in across app restarts, mirroring how the web
/// frontend relies on the browser's cookie jar. On web the browser itself
/// owns cookies (sent automatically when `withCredentials` is set), so no
/// cookie manager is needed there.
class ApiClient {
  ApiClient(this.dio);

  final Dio dio;

  static Future<ApiClient> create() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          // Native HTTP clients don't have a real browser Origin. Once a
          // session cookie exists in the persisted cookie jar below,
          // better-auth's origin-check middleware requires *some* Origin
          // header on any cookie-bearing request (including sign-in
          // itself) — this synthetic value is allow-listed server-side in
          // backend/src/lib/auth.ts's trustedOrigins. Omitted on web, where
          // the browser sets and owns the real Origin header itself.
          if (!kIsWeb) 'Origin': 'askmusawo://mobile',
        },
        extra: {'withCredentials': true},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      final cookieJar = PersistCookieJar(
        storage: FileStorage('${dir.path}/.cookies'),
      );
      dio.interceptors.add(CookieManager(cookieJar));
    }

    return ApiClient(dio);
  }
}
