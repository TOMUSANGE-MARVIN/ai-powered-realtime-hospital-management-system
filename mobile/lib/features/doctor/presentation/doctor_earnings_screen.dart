import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/earnings.dart';
import '../state/doctor_providers.dart';

class DoctorEarningsScreen extends ConsumerStatefulWidget {
  const DoctorEarningsScreen({super.key});

  @override
  ConsumerState<DoctorEarningsScreen> createState() => _DoctorEarningsScreenState();
}

class _DoctorEarningsScreenState extends ConsumerState<DoctorEarningsScreen> {
  String _period = 'today';

  int _amountFor(Earnings earnings) {
    switch (_period) {
      case 'week':
        return earnings.thisWeek;
      case 'month':
        return earnings.thisMonth;
      case 'year':
        return earnings.thisYear;
      default:
        return earnings.today;
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payouts are coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(earningsProvider);
    final currency = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: earningsAsync.when(
        data: (earnings) => RefreshIndicator(
          onRefresh: () => ref.refresh(earningsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Available Balance',
                      value: 'UGX ${currency.format(earnings.availableBalance)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Pending',
                      value: 'UGX ${currency.format(earnings.pendingPayments)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Withdraw Funds', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.phone_android),
                        label: const Text('Withdraw to Mobile Money'),
                        onPressed: () => _showComingSoon(context),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.account_balance),
                        label: const Text('Withdraw to Bank Account'),
                        onPressed: () => _showComingSoon(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Earnings Overview', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Today')),
                  ButtonSegment(value: 'week', label: Text('Week')),
                  ButtonSegment(value: 'month', label: Text('Month')),
                  ButtonSegment(value: 'year', label: Text('Year')),
                ],
                selected: {_period},
                onSelectionChanged: (v) => setState(() => _period = v.first),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'UGX ${currency.format(_amountFor(earnings))}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Consultation Stats', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Total', value: '${earnings.consultationTotal}')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Virtual', value: '${earnings.consultationVirtual}')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'In-person', value: '${earnings.consultationInPerson}')),
                ],
              ),
              const SizedBox(height: 24),
              Text('Revenue Breakdown', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Virtual Consultations'),
                      trailing: Text('UGX ${currency.format(earnings.revenueVirtual)}'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('In-person Consultations'),
                      trailing: Text('UGX ${currency.format(earnings.revenueInPerson)}'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Total Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        'UGX ${currency.format(earnings.totalEarnings)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (earnings.recentTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No completed consultations yet.'),
                )
              else
                ...earnings.recentTransactions.map(
                  (t) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(t.isVirtual ? Icons.videocam_outlined : Icons.local_hospital_outlined),
                      title: Text(t.patientName),
                      subtitle: Text(DateFormat('MMM d, yyyy').format(t.date)),
                      trailing: Text('+${currency.format(t.amount)}'),
                    ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
