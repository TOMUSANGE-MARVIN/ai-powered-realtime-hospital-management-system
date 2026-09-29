import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../doctors/data/review.dart';
import '../../doctors/presentation/doctor_card.dart' show DoctorImage;
import '../../doctors/state/doctor_providers.dart';
import '../data/appointment.dart';

/// Full-screen rating for a completed appointment. Pops `true` once the
/// review is saved.
class RateDoctorScreen extends ConsumerStatefulWidget {
  const RateDoctorScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<RateDoctorScreen> createState() => _RateDoctorScreenState();
}

class _RateDoctorScreenState extends ConsumerState<RateDoctorScreen> {
  final _commentController = TextEditingController();
  final _helpedWith = <String>{};
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .submit(
            appointmentId: widget.appointment.id,
            rating: _rating,
            comment: _commentController.text.trim(),
            helpedWith: _helpedWith.toList(),
          );
      final doctorId = widget.appointment.doctorId;
      if (doctorId != null) ref.invalidate(doctorReviewsProvider(doctorId));
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final doctor = appointment.doctorId == null
        ? null
        : ref.watch(doctorDetailProvider(appointment.doctorId!)).value;
    final specialty =
        doctor?.specialization ?? doctor?.department ?? appointment.department;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Rating'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Center(
            child: SizedBox(
              width: 112,
              height: 112,
              child: ClipOval(
                child: DoctorImage(
                  url: doctor?.image,
                  name: appointment.doctorName,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            appointment.doctorName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (specialty != null) ...[
            const SizedBox(height: 4),
            Text(specialty, textAlign: TextAlign.center,
                style: TextStyle(color: muted)),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 40,
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i <= _rating ? const Color(0xFFFFB300) : muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'What did the doctor help you?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          for (final entry in reviewHelpTags.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.trailing,
              activeColor: seedTeal,
              title: Text(entry.value),
              value: _helpedWith.contains(entry.key),
              onChanged: _submitting
                  ? null
                  : (checked) => setState(() {
                        checked == true
                            ? _helpedWith.add(entry.key)
                            : _helpedWith.remove(entry.key);
                      }),
            ),
          const SizedBox(height: 16),
          Text('Leave a public review', style: TextStyle(color: muted)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            minLines: 4,
            maxLines: 6,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Eg. The doctor is very friendly',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: FilledButton(
          onPressed: _rating == 0 || _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ),
    );
  }
}
