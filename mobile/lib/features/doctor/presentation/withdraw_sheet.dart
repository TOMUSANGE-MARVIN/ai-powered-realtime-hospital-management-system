import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/loading_dots.dart';
import '../../auth/state/auth_controller.dart';
import '../state/doctor_providers.dart';

const _minWithdrawal = 5000;
const _networks = ['MTN', 'Airtel'];
const _banks = ['Stanbic', 'Centenary', 'Absa', 'dfcu', 'Equity', 'Other'];

/// Asks for a payout to mobile money or a bank account. Returns true once
/// the request is filed; an admin pays it out and marks it paid.
Future<bool> showWithdrawSheet(
  BuildContext context, {
  required bool toBank,
  required int available,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _WithdrawSheet(toBank: toBank, available: available),
  );
  return result ?? false;
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.toBank, required this.available});

  final bool toBank;
  final int available;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  late String _provider = widget.toBank ? _banks.first : _networks.first;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(authControllerProvider).value?.name ?? '';
    final phone = ref.read(authControllerProvider).value?.phoneNumber;
    if (!widget.toBank && phone != null) _numberController.text = phone;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(earningsRepositoryProvider)
          .requestWithdrawal(
            amount: int.parse(_amountController.text),
            method: widget.toBank ? 'bank' : 'mobile_money',
            provider: _provider,
            accountName: _nameController.text.trim(),
            accountNumber: _numberController.text.trim(),
          );
      ref.invalidate(earningsProvider);
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
    final money = NumberFormat.decimalPattern();
    final options = widget.toBank ? _banks : _networks;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.toBank
                  ? 'Withdraw to Bank Account'
                  : 'Withdraw to Mobile Money',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Available: UGX ${money.format(widget.available)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  ChoiceChip(
                    label: Text(option),
                    selected: _provider == option,
                    onSelected: (_) => setState(() => _provider = option),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Amount (UGX)',
                helperText: 'Minimum UGX 5,000',
              ),
              validator: (value) {
                final amount = int.tryParse(value ?? '') ?? 0;
                if (amount < _minWithdrawal) return 'Minimum is UGX 5,000';
                if (amount > widget.available) {
                  return 'More than your available balance';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Account name'),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Enter the account name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numberController,
              keyboardType: widget.toBank
                  ? TextInputType.number
                  : TextInputType.phone,
              decoration: InputDecoration(
                labelText: widget.toBank ? 'Account number' : 'Phone number',
                hintText: widget.toBank ? null : '+256 7XX XXX XXX',
              ),
              validator: (value) => (value ?? '').trim().length < 6
                  ? 'Enter a valid number'
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const LoadingDots()
                    : const Text('Request withdrawal'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The Ask Musawo team reviews and sends each payout. Track its '
              'status under Recent Transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
