import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/providers.dart';
import '../realtime/socket_providers.dart';
import 'presence_repository.dart';

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository(ref.watch(dioProvider));
});

/// Whether [userId] currently has a live app session — seeded from a REST
/// fetch (so a freshly opened chat shows a value immediately), then kept
/// live via the socket's `presence_changed` broadcast.
final presenceProvider = StreamProvider.family.autoDispose<bool, String>((ref, userId) async* {
  final repo = ref.watch(presenceRepositoryProvider);
  final socket = ref.watch(socketServiceProvider);

  yield await repo.isOnline(userId);

  await for (final event in socket.presenceChanged) {
    if (event['userId'] == userId) yield event['online'] as bool? ?? false;
  }
});
