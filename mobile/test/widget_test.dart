// Basic smoke test: boots the app with a stubbed API client (no real
// network/session dependency) and checks it lands on the login screen.

import 'dart:typed_data';

import 'package:ask_musawo/core/api/api_client.dart';
import 'package:ask_musawo/core/api/providers.dart';
import 'package:ask_musawo/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the login screen when signed out', (WidgetTester tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
    dio.httpClientAdapter = _StubAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(ApiClient(dio))],
        child: const AskMusawoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}

class _StubAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // GET /api/me -> no active session, so the router redirects to /login.
    return ResponseBody.fromString(
      '{"session":null,"user":null}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
