import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/ai_search_result.dart';
import '../data/doctor.dart';
import '../state/doctor_providers.dart';

/// Free-text "describe your symptoms" search — Gemini maps the description
/// to relevant specialties, and we list real doctors in those specialties.
class AiSymptomSearchScreen extends ConsumerStatefulWidget {
  const AiSymptomSearchScreen({super.key});

  @override
  ConsumerState<AiSymptomSearchScreen> createState() => _AiSymptomSearchScreenState();
}

class _AiSymptomSearchScreenState extends ConsumerState<AiSymptomSearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  AiSearchResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(aiSearchRepositoryProvider).search(text);
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Symptom Search')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Describe how you feel and we\'ll suggest which specialist to see.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'e.g. "I\'ve had a sharp pain in my chest and shortness of breath since this morning..."',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_loading ? 'Analysing…' : 'Find a specialist'),
            ),
            const SizedBox(height: 24),
            if (_error != null) _ErrorState(message: _error!),
            if (_result != null) _ResultsView(result: _result!),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('/search'),
            child: const Text('Search manually instead'),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.result});

  final AiSearchResult result;

  @override
  Widget build(BuildContext context) {
    if (result.matches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No clear match found — try describing your symptoms differently.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Suggested specialties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ...result.matches.map((m) => _MatchCard(match: m)),
        const SizedBox(height: 20),
        const Text('Matching doctors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        if (result.doctors.isEmpty)
          const Text('No doctors are currently listed under these specialties.')
        else
          ...result.doctors.map((d) => _DoctorResultTile(doctor: d)),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final AiSpecialtyMatch match;

  @override
  Widget build(BuildContext context) {
    final accent = specialtyAccent(match.specialty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        color: accent.background,
        onTap: () => context.push('/search', extra: match.specialty),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.local_hospital, color: accent.foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.specialty,
                    style: TextStyle(fontWeight: FontWeight.bold, color: accent.foreground),
                  ),
                  const SizedBox(height: 2),
                  Text(match.reason, style: TextStyle(color: accent.foreground.withValues(alpha: 0.9))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorResultTile extends StatelessWidget {
  const _DoctorResultTile({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final feeFormat = NumberFormat.decimalPattern();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/doctors/${doctor.id}'),
        leading: CircleAvatar(
          backgroundImage: doctor.image != null ? NetworkImage(doctor.image!) : null,
          child: doctor.image == null ? const Icon(Icons.person) : null,
        ),
        title: Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(doctor.specialization ?? doctor.department ?? 'General'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  doctor.rating != null ? doctor.rating!.toStringAsFixed(1) : 'New',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (doctor.consultationFee != null)
              Text(
                'UGX ${feeFormat.format(doctor.consultationFee)}',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
