import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.image != null ? NetworkImage(user.image!) : null,
                child: user.image == null ? const Icon(Icons.person, size: 36) : null,
              ),
              const SizedBox(height: 12),
              Center(child: Text(user.name, style: Theme.of(context).textTheme.titleLarge)),
              Center(child: Text(user.email, style: TextStyle(color: Colors.grey.shade600))),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
