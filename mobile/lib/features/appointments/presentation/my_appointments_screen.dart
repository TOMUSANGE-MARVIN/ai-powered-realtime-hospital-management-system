import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../calls/state/call_controller.dart';
import '../../chat/data/chat_args.dart';
import '../../doctors/data/doctor.dart';
import '../../doctors/presentation/doctor_card.dart' show DoctorImage;
import '../../doctors/state/doctor_providers.dart';
import '../data/appointment.dart';
import '../data/booking_draft.dart';
import '../state/appointment_providers.dart';

/// Appointment ids reviewed in this session — flips the button to
/// "Reviewed ✓" immediately without another backend lookup.
final _reviewedAppointmentsProvider = StateProvider<Set<String>>((ref) => {});

enum _Tab { upcoming, completed, cancelled }

const _upcomingStatuses = {
  'requested',
  'scheduled',
  'confirmed',
  'in_progress',
};

_Tab _tabOf(Appointment a) => _upcomingStatuses.contains(a.status)
    ? _Tab.upcoming
    : a.status == 'cancelled'
    ? _Tab.cancelled
    : _Tab.completed;

/// Section heading for an upcoming appointment, in display order.
(int, String) _groupOf(Appointment a) {
  if (a.status == 'in_progress') return (0, 'In progress');
  if (a.proposedDate != null) return (1, 'New time proposed');
  if (a.status == 'requested') return (5, 'Waiting for the doctor to confirm');
  final today = DateUtils.dateOnly(DateTime.now());
  final day = DateUtils.dateOnly(a.date);
  if (day == today) return (2, 'Today');
  if (day == today.add(const Duration(days: 1))) return (3, 'Tomorrow');
  return (4, 'Coming up');
}

class MyAppointmentsScreen extends ConsumerStatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  ConsumerState<MyAppointmentsScreen> createState() =>
      _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends ConsumerState<MyAppointmentsScreen> {
  _Tab _tab = _Tab.upcoming;

  /// The visible tab's rows: section headings (String) and appointments.
  List<Object> _rows(List<Appointment> all) {
    final list = all.where((a) => _tabOf(a) == _tab).toList();
    if (_tab != _Tab.upcoming) {
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
    list.sort((a, b) {
      final g = _groupOf(a).$1.compareTo(_groupOf(b).$1);
      return g != 0 ? g : a.date.compareTo(b.date);
    });
    final rows = <Object>[];
    String? current;
    for (final a in list) {
      final heading = _groupOf(a).$2;
      if (heading != current) {
        rows.add(heading);
        current = heading;
      }
      rows.add(a);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      backgroundColor: tealBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Appointments',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: darkTealBackground,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View and manage your appointments',
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7A7A)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: appointmentsAsync.when(
                data: (appointments) {
                  if (appointments.isEmpty) return const _EmptyState();
                  final counts = {
                    for (final t in _Tab.values)
                      t: appointments.where((a) => _tabOf(a) == t).length,
                  };
                  final rows = _rows(appointments);
                  return Column(
                    children: [
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          children: [
                            for (final t in _Tab.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _TabChip(
                                  label: switch (t) {
                                    _Tab.upcoming => 'Upcoming',
                                    _Tab.completed => 'Completed',
                                    _Tab.cancelled => 'Cancelled',
                                  },
                                  count: counts[t]!,
                                  selected: _tab == t,
                                  onTap: () => setState(() => _tab = t),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: seedTeal,
                          onRefresh: () =>
                              ref.refresh(myAppointmentsProvider.future),
                          child: rows.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(40),
                                      child: Text(
                                        switch (_tab) {
                                          _Tab.upcoming =>
                                            'No upcoming appointments.',
                                          _Tab.completed =>
                                            'No past visits yet.',
                                          _Tab.cancelled =>
                                            'No cancelled appointments.',
                                        },
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF6B7A7A),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    24,
                                  ),
                                  itemCount: rows.length,
                                  itemBuilder: (context, index) {
                                    final row = rows[index];
                                    if (row is String) {
                                      return Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          4,
                                          index == 0 ? 4 : 10,
                                          4,
                                          10,
                                        ),
                                        child: Text(
                                          row,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: darkTealBackground,
                                          ),
                                        ),
                                      );
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _AppointmentCard(
                                        appointment: row as Appointment,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SkeletonCardList(cardHeight: 200),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: Color(0xFFC62828),
                        ),
                        const SizedBox(height: 12),
                        Text(error.toString(), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(myAppointmentsProvider),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: seedTeal.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 34,
                color: seedTeal,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No appointments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkTealBackground,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Book a visit with a doctor and it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7A7A)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: seedTeal,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kCardRadius),
                ),
              ),
              onPressed: () => context.go('/home'),
              child: const Text('Find a doctor'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  /// Pastel background + vivid/dark foreground, per the brand accent pairs.
  ({Color bg, Color fg, IconData icon, String label}) _statusStyle(
    String status,
  ) {
    switch (status) {
      case 'requested':
        return (
          bg: const Color(0xFFFF9800),
          fg: const Color(0xFF2B1A00),
          icon: Icons.schedule_rounded,
          label: 'Requested',
        );
      case 'confirmed':
      case 'scheduled':
        return (
          bg: seedTeal,
          fg: Colors.white,
          icon: Icons.event_available_rounded,
          label: status == 'confirmed' ? 'Confirmed' : 'Scheduled',
        );
      case 'in_progress':
        return (
          bg: const Color(0xFFFFA000),
          fg: const Color(0xFF2B1A00),
          icon: Icons.play_circle_outline_rounded,
          label: 'In progress',
        );
      case 'completed':
        return (
          bg: const Color(0xFF0B5F60),
          fg: Colors.white,
          icon: Icons.check_circle_outline_rounded,
          label: 'Completed',
        );
      case 'no_show':
        return (
          bg: const Color(0xFF55605F),
          fg: Colors.white,
          icon: Icons.event_busy_outlined,
          label: 'Missed',
        );
      case 'cancelled':
        return (
          bg: const Color(0xFFD32F2F),
          fg: Colors.white,
          icon: Icons.cancel_outlined,
          label: 'Cancelled',
        );
      default:
        return (
          bg: const Color(0xFF55605F),
          fg: Colors.white,
          icon: Icons.info_outline_rounded,
          label: status,
        );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel your appointment with ${appointment.doctorName}?'),
            if (appointment.fee != null && appointment.fee! > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Contact support about a refund for your payment.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true) return;
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .cancel(appointment.id, reason: reason.isEmpty ? null : reason);
      ref.invalidate(myAppointmentsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _reschedule(
    BuildContext context,
    WidgetRef ref,
    Doctor? doctor,
  ) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _RescheduleSheet(doctor: doctor, current: appointment.date),
    );
    if (picked == null) return;
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .reschedule(
            appointment.id,
            date: picked,
            time: DateFormat.jm().format(picked),
          );
      ref.invalidate(myAppointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rescheduled — waiting for the doctor to confirm'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _joinCall(WidgetRef ref, Doctor? doctor) {
    ref
        .read(callControllerProvider.notifier)
        .startOutgoingCall(
          appointment.doctorId!,
          appointment.doctorName,
          isVideo: appointment.consultationType == 'video',
          peerImage: doctor?.image,
        );
  }

  Future<void> _respondToProposal(
    BuildContext context,
    WidgetRef ref, {
    required bool accept,
  }) async {
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .respondToProposal(appointment.id, accept: accept);
      ref.invalidate(myAppointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'New time accepted — your visit is confirmed'
                  : 'Kept your original time. The doctor has been told.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _review(BuildContext context, WidgetRef ref) async {
    final saved = await context.push<bool>(
      '/review/${appointment.id}',
      extra: appointment,
    );
    if (saved != true) return;
    ref
        .read(_reviewedAppointmentsProvider.notifier)
        .update((ids) => {...ids, appointment.id});
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thanks for your review!')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final status = _statusStyle(appointment.status);
    final doctor = appointment.doctorId == null
        ? null
        : ref.watch(doctorDetailProvider(appointment.doctorId!)).asData?.value;
    final specialty =
        doctor?.specialization ?? doctor?.department ?? appointment.department;
    final reviewed = ref
        .watch(_reviewedAppointmentsProvider)
        .contains(appointment.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: ClipOval(
                  child: DoctorImage(
                    url: doctor?.image,
                    name: appointment.doctorName,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: darkTealBackground,
                      ),
                    ),
                    if (specialty != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7A7A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.bg,
                  borderRadius: BorderRadius.circular(kCardRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 14, color: status.fg),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: status.fg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFE6EFEF)),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: tealBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 22,
                  color: seedTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment date',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7A7A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFormat.format(appointment.date)}'
                      '${appointment.time != null ? ' · ${appointment.time}' : ''}',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: darkTealBackground,
                      ),
                    ),
                  ],
                ),
              ),
              if (appointment.isEmergency)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency, size: 15, color: Color(0xFFC62828)),
                    SizedBox(width: 4),
                    Text(
                      'Emergency',
                      style: TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              appointment.reason!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF55605F)),
            ),
          ],
          if (appointment.proposedDate != null &&
              appointment.isCancellable) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(kCardRadius),
                border: Border.all(color: const Color(0xFFFFA000)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${appointment.doctorName} proposed a new time',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('EEE, MMM d, yyyy').format(appointment.proposedDate!)}'
                    '${appointment.proposedTime != null ? ' · ${appointment.proposedTime}' : ''}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _respondToProposal(context, ref, accept: false),
                          child: const Text('Keep original'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              _respondToProposal(context, ref, accept: true),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (appointment.status == 'cancelled' &&
              appointment.cancelledBy != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                appointment.cancelledBy == 'patient'
                    ? 'You cancelled this appointment.'
                    : appointment.cancelledBy == 'doctor'
                    ? '${appointment.doctorName} cancelled this appointment.'
                    : 'Ask Musawo cancelled this appointment.',
                if (appointment.cancellationReason?.isNotEmpty == true)
                  'Reason: ${appointment.cancellationReason}',
              ].join(' '),
              style: const TextStyle(fontSize: 13, color: Color(0xFFD32F2F)),
            ),
          ],
          if (appointment.status == 'completed' &&
              appointment.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _VisitSummary(text: appointment.notes!),
          ],
          if (appointment.doctorId != null &&
              const {
                'completed',
                'cancelled',
                'no_show',
              }.contains(appointment.status)) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Book again'),
                onPressed: () => context.push('/book/${appointment.doctorId}'),
              ),
            ),
          ],
          if (appointment.doctorId != null ||
              appointment.isCancellable ||
              appointment.status == 'completed') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (appointment.doctorId != null)
                  Expanded(
                    flex: 3,
                    child: _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message doctor',
                      background: seedTeal,
                      foreground: Colors.white,
                      onPressed: () => context.push(
                        '/chat/${appointment.doctorId}',
                        extra: ChatArgs(name: appointment.doctorName),
                      ),
                    ),
                  ),
                if (appointment.doctorId != null &&
                    (appointment.isCancellable ||
                        appointment.status == 'completed'))
                  const SizedBox(width: 12),
                if (appointment.isCancellable)
                  Expanded(
                    flex: 2,
                    child: _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Cancel',
                      background: const Color(0xFFFFE9E9),
                      foreground: const Color(0xFFC62828),
                      borderColor: const Color(0xFFF6C4C4),
                      onPressed: () => _cancel(context, ref),
                    ),
                  ),
                if (appointment.status == 'completed')
                  Expanded(
                    flex: 2,
                    child: reviewed
                        ? const _ActionButton(
                            icon: Icons.check_rounded,
                            label: 'Reviewed',
                            background: Color(0xFFE0F2F2),
                            foreground: seedTeal,
                          )
                        : _ActionButton(
                            icon: Icons.star_outline_rounded,
                            label: 'Review',
                            background: const Color(0xFFFF9800),
                            foreground: const Color(0xFF2B1A00),
                            onPressed: () => _review(context, ref),
                          ),
                  ),
              ],
            ),
          ],
          if (!appointment.isEmergency &&
              (appointment.isCancellable ||
                  (appointment.doctorId != null &&
                      appointment.canJoinCallAt(DateTime.now())))) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (appointment.isCancellable)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.event_repeat_rounded,
                      label: 'Reschedule',
                      background: Colors.white,
                      foreground: seedTeal,
                      borderColor: seedTeal,
                      onPressed: () => _reschedule(context, ref, doctor),
                    ),
                  ),
                if (appointment.isCancellable &&
                    appointment.doctorId != null &&
                    appointment.canJoinCallAt(DateTime.now()))
                  const SizedBox(width: 12),
                if (appointment.doctorId != null &&
                    appointment.canJoinCallAt(DateTime.now()))
                  Expanded(
                    child: _ActionButton(
                      icon: appointment.consultationType == 'video'
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      label: 'Join call',
                      background: const Color(0xFF0B5F60),
                      foreground: Colors.white,
                      onPressed: () => _joinCall(ref, doctor),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date + half-hour slot picker limited to the doctor's working days and
/// hours. Pops the chosen start time.
class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.doctor, required this.current});

  final Doctor? doctor;
  final DateTime current;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late final Set<int>? _weekdays = parseAvailableWeekdays(
    widget.doctor?.availabilityDays,
  );
  late final List<int> _slots = parseSlotMinutes(
    widget.doctor?.availabilityHours,
  );
  DateTime? _day;
  int? _slot;

  bool _isOpenDay(DateTime day) =>
      (_weekdays == null || _weekdays.contains(day.weekday)) &&
      !(widget.doctor?.isAwayOn(day) ?? false);

  List<int> _openSlots(DateTime day) {
    final now = DateTime.now();
    return [
      for (final m in _slots)
        if (day.add(Duration(minutes: m)).isAfter(now)) m,
    ];
  }

  Future<void> _pickDay() async {
    final today = DateUtils.dateOnly(DateTime.now());
    var first = today;
    while (!_isOpenDay(first) || _openSlots(first).isEmpty) {
      first = first.add(const Duration(days: 1));
      if (first.difference(today).inDays > 60) break;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? first,
      firstDate: first,
      lastDate: today.add(const Duration(days: 60)),
      selectableDayPredicate: _isOpenDay,
    );
    if (picked != null) {
      setState(() {
        _day = picked;
        _slot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final slots = day == null ? const <int>[] : _openSlots(day);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reschedule appointment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Currently ${DateFormat('EEE, MMM d · h:mm a').format(widget.current)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(
                day == null
                    ? 'Choose date'
                    : DateFormat('EEEE, MMM d').format(day),
              ),
              onPressed: _pickDay,
            ),
            if (day != null) ...[
              const SizedBox(height: 16),
              if (slots.isEmpty)
                const Text('No times left on this day.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in slots)
                      ChoiceChip(
                        label: Text(
                          DateFormat.jm().format(
                            DateTime(2000, 1, 1, m ~/ 60, m % 60),
                          ),
                        ),
                        selected: _slot == m,
                        onSelected: (_) => setState(() => _slot = m),
                      ),
                  ],
                ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: day == null || _slot == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop(day.add(Duration(minutes: _slot!))),
              child: const Text('Request new time'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The doctor's visit summary, collapsed to a few lines until tapped.
class _VisitSummary extends StatefulWidget {
  const _VisitSummary({required this.text});

  final String text;

  @override
  State<_VisitSummary> createState() => _VisitSummaryState();
}

class _VisitSummaryState extends State<_VisitSummary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tealBackground,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes_rounded, size: 16, color: seedTeal),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Visit summary',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: seedTeal,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: seedTeal,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.text,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? seedTeal : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: selected
            ? BorderSide.none
            : BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : darkTealBackground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
