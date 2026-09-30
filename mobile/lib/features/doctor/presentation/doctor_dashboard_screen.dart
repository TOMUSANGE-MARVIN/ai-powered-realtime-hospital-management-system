import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_gate.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../appointments/data/booking_draft.dart'
    show parseAvailableWeekdays, parseSlotMinutes;
import '../../auth/data/app_user.dart';
import '../../appointments/data/appointment.dart';
import '../../appointments/state/appointment_providers.dart';
import '../../auth/state/auth_controller.dart';
import '../../notifications/presentation/notifications_screen.dart'
    show NotificationBell;
import 'appointment_dialogs.dart';
import 'doctor_appointments_screen.dart' show DoctorAppointmentCard;
import '../state/doctor_providers.dart';
import '../../../core/widgets/user_avatar.dart';

String _greetingName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return 'Doctor';
  final parts = fullName.trim().split(RegExp(r'\s+'));
  // Skip a leading title (e.g. "Dr.", "Prof.") so the greeting shows the
  // doctor's actual first name rather than just the honorific.
  final firstNonTitle = parts.firstWhere(
    (p) =>
        !RegExp(r'^(Dr|Prof|Mr|Mrs|Ms)\.?$', caseSensitive: false).hasMatch(p),
    orElse: () => parts.first,
  );
  return firstNonTitle;
}

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final earningsAsync = ref.watch(earningsProvider);
    final todaysAsync = ref.watch(todaysAssignedAppointmentsProvider);
    final requestsAsync = ref.watch(assignedRequestsProvider);
    final currencyFormat = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${_greetingName(userAsync.value?.name)}'),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(earningsProvider);
          ref.invalidate(todaysAssignedAppointmentsProvider);
          ref.invalidate(assignedRequestsProvider);
        },
        child: DashboardGate(
          values: [earningsAsync, todaysAsync, requestsAsync],
          loadingBuilder: (context) => const _DoctorDashboardSkeleton(),
          builder: (context) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (userAsync.value != null)
                _DoctorHeader(
                  user: userAsync.value!,
                  todays: todaysAsync.value ?? const [],
                ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earnings today',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      earningsAsync.when(
                        data: (earnings) => Text(
                          'UGX ${currencyFormat.format(earnings.today)}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: SkeletonBox(width: 160, height: 28),
                        ),
                        error: (_, _) => const Text('—'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Appointments",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go('/doctor-home/appointments'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              todaysAsync.when(
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No appointments scheduled for today.'),
                    );
                  }
                  final sorted = [...appointments]
                    ..sort((a, b) => a.date.compareTo(b.date));
                  return Column(
                    children: [
                      for (final a in sorted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DoctorAppointmentCard(appointment: a),
                        ),
                    ],
                  );
                },
                loading: () =>
                    const SkeletonCardList(count: 2, cardHeight: 110),
                error: (error, _) => Text(error.toString()),
              ),
              const SizedBox(height: 24),
              Text(
                'Appointment Requests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              requestsAsync.when(
                data: (requests) {
                  if (requests.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No pending requests.'),
                    );
                  }
                  return Column(
                    children: requests
                        .map((a) => _RequestTile(appointment: a))
                        .toList(),
                  );
                },
                loading: () => const Column(
                  children: [SkeletonListTile(), SkeletonListTile()],
                ),
                error: (error, _) => Text(error.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors [DoctorDashboardScreen]'s real layout — earnings card, today's
/// appointments, appointment requests — so the first-load wait reads as
/// "this page is here, filling in" rather than a generic spinner.
class _DoctorDashboardSkeleton extends StatelessWidget {
  const _DoctorDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const SkeletonBox(
          width: double.infinity,
          height: 108,
          borderRadius: kCardRadius,
        ),
        const SizedBox(height: 24),
        const SkeletonBox(width: 180, height: 18),
        const SizedBox(height: 12),
        ...List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SkeletonListTile(),
          ),
        ),
        const SizedBox(height: 16),
        const SkeletonBox(width: 200, height: 18),
        const SizedBox(height: 12),
        ...List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SkeletonListTile(),
          ),
        ),
      ],
    );
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({required this.appointment});

  final Appointment appointment;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    String? reason;
    if (status == 'cancelled') {
      reason = await askCancellationReason(
        context,
        patientName: appointment.patientName ?? 'the patient',
        isReject: true,
      );
      if (reason == null || !context.mounted) return;
    }
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateAssigned(
            appointment.id,
            status: status,
            cancellationReason: reason?.isEmpty == true ? null : reason,
          );
      ref.invalidate(assignedRequestsProvider);
      ref.invalidate(todaysAssignedAppointmentsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.patientName ?? 'Patient',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (appointment.isEmergency)
                  Chip(
                    avatar: Icon(
                      Icons.emergency,
                      size: 15,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                    label: const Text('EMERGENCY'),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${dateFormat.format(appointment.date)}${appointment.time != null ? ' · ${appointment.time}' : ''}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(context, ref, 'confirmed'),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(context, ref, 'cancelled'),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo, name and specialty, plus the next free slot today worked out from
/// the doctor's working hours and today's bookings.
class _DoctorHeader extends StatelessWidget {
  const _DoctorHeader({required this.user, required this.todays});

  final AppUser user;
  final List<Appointment> todays;

  String _nextFree() {
    final now = DateTime.now();
    final days = parseAvailableWeekdays(user.availabilityDays);
    if (days != null && !days.contains(now.weekday)) {
      return 'Not a working day';
    }
    final taken = {
      for (final a in todays)
        if (a.status != 'cancelled') a.time,
    };
    final slot = parseSlotMinutes(user.availabilityHours).where((m) {
      final start = DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
      final label = DateFormat.jm().format(start);
      return start.isAfter(now) &&
          !taken.contains(label) &&
          !taken.contains(label.padLeft(8, '0'));
    });
    if (slot.isEmpty) return 'No free slots left today';
    final m = slot.first;
    return 'Next free slot today: '
        '${DateFormat.jm().format(DateTime(2000, 1, 1, m ~/ 60, m % 60))}';
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SoftCard(
      child: Row(
        children: [
          UserAvatar(url: user.image, kind: AvatarKind.self, radius: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (user.specialization != null)
                  Text(user.specialization!, style: TextStyle(color: muted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 16,
                      color: seedTeal,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _nextFree(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
