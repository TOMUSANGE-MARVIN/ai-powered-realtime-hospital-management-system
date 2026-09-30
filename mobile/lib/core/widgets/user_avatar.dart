import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/state/auth_controller.dart';

/// Who an avatar belongs to, which picks the default illustration shown
/// when there's no photo.
enum AvatarKind {
  doctor,
  patient,

  /// The signed-in user.
  self,

  /// The person the signed-in user is talking to (chats, calls): a doctor
  /// for patients, a patient for doctors.
  peer,
}

/// Branded default portraits (Gemini-generated, assets/images/avatars/) used
/// everywhere in place of name initials.
const defaultDoctorAvatar = 'assets/images/avatars/default_doctor.webp';
const defaultPatientAvatar = 'assets/images/avatars/default_patient.webp';

/// A round profile picture: the uploaded photo, or the app's default doctor
/// or patient illustration when there's none or it fails to load.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.url,
    this.kind = AvatarKind.patient,
    this.radius = 20,
    this.child,
  });

  final String? url;
  final AvatarKind kind;
  final double radius;

  /// Drawn on top of the picture (e.g. an upload spinner).
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDoctorKind = switch (kind) {
      AvatarKind.doctor => true,
      AvatarKind.patient => false,
      AvatarKind.self =>
        ref.watch(authControllerProvider).value?.role == 'doctor',
      AvatarKind.peer =>
        ref.watch(authControllerProvider).value?.role != 'doctor',
    };
    final photo = url?.isNotEmpty == true ? url : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0F2F2),
      backgroundImage: AssetImage(
        isDoctorKind ? defaultDoctorAvatar : defaultPatientAvatar,
      ),
      // Painted over the default; if the photo fails to load the default
      // stays visible.
      foregroundImage: photo != null ? NetworkImage(photo) : null,
      onForegroundImageError: photo != null ? (_, _) {} : null,
      child: child,
    );
  }
}
