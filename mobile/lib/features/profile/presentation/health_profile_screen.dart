import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/soft_card.dart';
import '../../auth/state/auth_controller.dart';

/// Read-only summary of the health details a patient keeps on file, with a
/// shortcut to edit them.
class HealthProfileScreen extends ConsumerWidget {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const Scaffold();
    final dob = DateTime.tryParse(user.dateOfBirth ?? '');

    final rows = <(String, String?)>[
      ('Blood group', user.bloodgroup),
      (
        'Date of birth',
        dob == null ? null : DateFormat('d MMM yyyy').format(dob),
      ),
      ('Age', user.age),
      ('Gender', user.gender),
      ('Marital status', user.maritalStatus),
      (
        'Insurance',
        user.hasInsurance
            ? [
                user.insuranceProvider,
                user.insuranceMemberNo,
              ].whereType<String>().where((v) => v.isNotEmpty).join(' · ')
            : null,
      ),
      (
        'Emergency contact',
        user.emergencyContactName == null
            ? null
            : [
                user.emergencyContactName,
                user.emergencyContactRelation,
                user.emergencyContactPhone,
              ].whereType<String>().where((v) => v.isNotEmpty).join(' · '),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile'),
        actions: [
          TextButton(
            onPressed: () => context.push('/edit-profile'),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    title: Text(
                      rows[i].$1,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    subtitle: Text(
                      rows[i].$2?.isNotEmpty == true ? rows[i].$2! : 'Not set',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
