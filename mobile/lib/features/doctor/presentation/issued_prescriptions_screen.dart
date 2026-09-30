import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';

final issuedPrescriptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      try {
        final response = await ref
            .watch(dioProvider)
            .get('/api/prescriptions/issued');
        ApiException.checkStatus(response);
        return [
          for (final p in response.data as List) p as Map<String, dynamic>,
        ];
      } on DioException catch (error) {
        throw ApiException.fromDioError(error);
      }
    });

/// Prescriptions this doctor has sent, newest first.
class IssuedPrescriptionsScreen extends ConsumerStatefulWidget {
  const IssuedPrescriptionsScreen({super.key});

  @override
  ConsumerState<IssuedPrescriptionsScreen> createState() =>
      _IssuedPrescriptionsScreenState();
}

class _IssuedPrescriptionsScreenState
    extends ConsumerState<IssuedPrescriptionsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(issuedPrescriptionsProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Prescriptions issued')),
      body: list.when(
        loading: () => const SkeletonList(count: 5),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          final q = _query.toLowerCase();
          final filtered = q.isEmpty
              ? items
              : items.where((p) {
                  final meds = (p['items'] as List? ?? const [])
                      .map((i) => '${i['medicationName']}')
                      .join(' ');
                  return '${p['patientName']} $meds'.toLowerCase().contains(q);
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search patient or medication',
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          items.isEmpty
                              ? 'No prescriptions issued yet.'
                              : 'Nothing matches that search.',
                          style: TextStyle(color: muted),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.refresh(issuedPrescriptionsProvider.future),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = filtered[i];
                            final meds = p['items'] as List? ?? const [];
                            final status = p['status'] as String? ?? 'pending';
                            return SoftCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${p['patientName']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('d MMM yyyy').format(
                                          DateTime.parse(
                                            p['createdAt'] as String,
                                          ).toLocal(),
                                        ),
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  for (final m in meds)
                                    Text(
                                      '• ${m['medicationName']} ${m['dosage'] ?? ''}'
                                      ' × ${m['quantity'] ?? 1}'
                                      '${m['instructions'] != null ? ' — ${m['instructions']}' : ''}',
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    status == 'dispensed'
                                        ? 'Dispensed by pharmacy'
                                        : status == 'cancelled'
                                        ? 'Cancelled'
                                        : 'Not yet dispensed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: status == 'dispensed'
                                          ? seedTeal
                                          : status == 'cancelled'
                                          ? const Color(0xFFD32F2F)
                                          : muted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
