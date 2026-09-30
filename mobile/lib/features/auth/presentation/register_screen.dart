import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_dots.dart';
import '../../doctor/data/verification_repository.dart';
import '../../legal/data/legal_repository.dart';
import '../../legal/presentation/legal_accept_screen.dart';
import '../state/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  /// Doctors sign up the same way, then submit their licence on the
  /// verification screen before patients can see them.
  bool _asDoctor = false;

  /// Terms + Privacy consent, required by the Data Protection and Privacy
  /// Act before we store any health information.
  bool _agreed = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Privacy Policy'),
        ),
      );
      return;
    }
    final LegalDocuments legal;
    try {
      legal = await ref.read(legalDocumentsProvider.future);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load the Terms. Check your connection."),
        ),
      );
      return;
    }
    if (!mounted) return;
    ref.read(doctorSignupIntentProvider.notifier).set(_asDoctor);
    await ref
        .read(authControllerProvider.notifier)
        .signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          acceptedLegalVersion: legal.version,
        );
    // A successful sign-up triggers an immediate redirect away from this
    // screen (see app_router.dart), which can unmount it before this
    // continuation runs. Touching `ref`/`context` after that is unsafe.
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      ref.read(doctorSignupIntentProvider.notifier).set(false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 300,
                    child: SvgPicture.asset(
                      'assets/images/illustrations/creaate-account-illustration.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book consultations and manage your care from your phone',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text("I'm a patient"),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text("I'm a doctor"),
                        icon: Icon(Icons.medical_services_outlined),
                      ),
                    ],
                    selected: {_asDoctor},
                    showSelectedIcon: false,
                    onSelectionChanged: isLoading
                        ? null
                        : (value) => setState(() => _asDoctor = value.first),
                  ),
                  if (_asDoctor) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Next you'll add your UMDPC licence. Patients can book "
                      'you once an admin has verified it.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.palette.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 8)
                        ? 'Minimum 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: isLoading
                            ? null
                            : (v) => setState(() => _agreed = v ?? false),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LegalAgreementText(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isLoading || !_agreed ? null : _submit,
                    child: isLoading
                        ? const LoadingDots()
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
