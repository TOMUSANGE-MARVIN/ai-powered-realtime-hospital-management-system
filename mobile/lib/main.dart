import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/api/providers.dart';
import 'core/realtime/socket_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/calls/presentation/call_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = await ApiClient.create();

  runApp(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(apiClient)],
      child: const AskMusawoApp(),
    ),
  );
}

class AskMusawoApp extends ConsumerWidget {
  const AskMusawoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(socketLifecycleProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Ask Musawo',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => CallOverlay(child: child),
    );
  }
}
