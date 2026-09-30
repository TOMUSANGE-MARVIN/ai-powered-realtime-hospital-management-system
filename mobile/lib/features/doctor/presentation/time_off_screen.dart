import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/offline/offline_first.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../doctors/data/doctor.dart' show TimeOffRange;

final _day = DateFormat('EEE d MMM yyyy');
String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

final myTimeOffProvider = FutureProvider.autoDispose<List<TimeOffRange>>(
  (ref) => offlineFirst(ref, () async {
    try {
      final response = await ref
          .watch(dioProvider)
          .get('/api/doctors/me/time-off');
      ApiException.checkStatus(response);
      return [
        for (final t in response.data as List)
          TimeOffRange.fromJson(t as Map<String, dynamic>),
      ];
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }),
);

/// Days a doctor isn't taking bookings. Patients can't book them, and the
/// booking screen hides them.
class TimeOffScreen extends ConsumerStatefulWidget {
  const TimeOffScreen({super.key});

  @override
  ConsumerState<TimeOffScreen> createState() => _TimeOffScreenState();
}

class _TimeOffScreenState extends ConsumerState<TimeOffScreen> {
  bool _busy = false;

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _add() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Days you are away',
    );
    if (range == null || !mounted) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reason (optional)'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: 'e.g. Annual leave, conference',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final response = await ref
          .read(dioProvider)
          .post(
            '/api/doctors/me/time-off',
            data: {
              'startDate': _iso(range.start),
              'endDate': _iso(range.end),
              if (reason.isNotEmpty) 'reason': reason,
            },
          );
      ApiException.checkStatus(response);
      ref.invalidate(myTimeOffProvider);
      final clashes = (response.data['clashes'] as List?) ?? const [];
      if (!mounted) return;
      if (clashes.isEmpty) {
        _toast('Time off saved. Patients can no longer book those days.');
      } else {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              '${clashes.length} booking${clashes.length == 1 ? '' : 's'} on those days',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time off is saved, but these visits were already booked. '
                  'Propose a new time or cancel each one with a reason:',
                ),
                const SizedBox(height: 12),
                for (final c in clashes)
                  Text(
                    '• ${c['patientName']} — '
                    '${DateFormat('EEE d MMM').format(DateTime.parse(c['date'] as String))}'
                    '${c['time'] != null ? ' at ${c['time']}' : ''}',
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/doctor-home/appointments');
                },
                child: const Text('Open appointments'),
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) _toast(ApiException.fromDioError(e).message);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(TimeOffRange t) async {
    try {
      final response = await ref
          .read(dioProvider)
          .delete('/api/doctors/me/time-off/${t.id}');
      ApiException.checkStatus(response);
      ref.invalidate(myTimeOffProvider);
    } on DioException catch (e) {
      if (mounted) _toast(ApiException.fromDioError(e).message);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(myTimeOffProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Time off')),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: seedTeal,
        foregroundColor: Colors.white,
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.event_busy_outlined),
        label: const Text('Add time off'),
      ),
      body: list.when(
        loading: () => const SkeletonList(count: 3),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No time off planned. Add the days you are away so '
                    'patients can\'t book them.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = items[i];
                  final single = t.start == t.end;
                  return SoftCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.event_busy_outlined),
                      title: Text(
                        single
                            ? _day.format(t.start)
                            : '${_day.format(t.start)} – ${_day.format(t.end)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: t.reason == null ? null : Text(t.reason!),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(t),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
