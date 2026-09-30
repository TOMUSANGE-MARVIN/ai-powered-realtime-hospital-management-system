import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/record_access.dart';

/// Settings → Privacy → Who viewed my records: every time a doctor, nurse,
/// pharmacist or staff member opened this patient's records (E23.3).
class RecordAccessScreen extends ConsumerWidget {
  const RecordAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(myRecordAccessProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Who viewed my records')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myRecordAccessProvider.future),
        child: entries.when(
          loading: () => const SkeletonList(count: 6),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [Text(error.toString(), textAlign: TextAlign.center)],
          ),
          data: (list) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'Every time someone other than you opens your records, it '
                  'is logged here. Repeat views within 30 minutes show once. '
                  "If you don't recognise someone, contact care@askmusawo.co.ug.",
                  style: TextStyle(color: context.palette.muted, height: 1.45),
                ),
              ),
              if (list.isEmpty)
                const SoftCard(
                  padding: EdgeInsets.all(20),
                  child: Text('Nobody has opened your records yet.'),
                )
              else
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _Row(entry: list[i]),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});

  final RecordAccess entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.palette.tint,
          shape: BoxShape.circle,
        ),
        child: Icon(
          entry.viewerRole == 'doctor'
              ? Icons.medical_services_outlined
              : Icons.badge_outlined,
          color: seedTeal,
          size: 20,
        ),
      ),
      title: Text(
        entry.viewerName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${entry.roleLabel} · ${entry.resourceLabel}'),
      trailing: Text(
        DateFormat('d MMM\nh:mm a').format(entry.at),
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 12, color: context.palette.muted),
      ),
    );
  }
}
