import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/doctor_providers.dart';

class DoctorDetailScreen extends ConsumerWidget {
  const DoctorDetailScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor profile')),
      body: doctorAsync.when(
        data: (doctor) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: doctor.image != null ? NetworkImage(doctor.image!) : null,
                      child: doctor.image == null ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(doctor.name, style: Theme.of(context).textTheme.titleLarge),
                    if (doctor.specialization != null)
                      Text(
                        doctor.specialization!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.indigo),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (doctor.department != null) ...[
                const Text('Department', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(doctor.department!),
                const SizedBox(height: 16),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Book appointment'),
                  onPressed: () => context.push('/book/${doctor.id}', extra: doctor.name),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
