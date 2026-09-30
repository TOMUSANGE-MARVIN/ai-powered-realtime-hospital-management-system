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

/// [AvatarKind] for a user whose role is known (e.g. a chat's other side);
/// falls back to [AvatarKind.peer] when it isn't.
AvatarKind avatarKindForRole(String? role) => switch (role) {
  'doctor' => AvatarKind.doctor,
  'patient' => AvatarKind.patient,
  _ => AvatarKind.peer,
};

/// Branded default portraits (Gemini-generated, assets/images/avatars/) used
/// everywhere in place of name initials.
const defaultDoctorAvatar = 'assets/images/avatars/default_doctor.webp';
const defaultFemaleDoctorAvatar =
    'assets/images/avatars/default_doctor_female.webp';
const defaultPatientAvatar = 'assets/images/avatars/default_patient.webp';
const defaultFemalePatientAvatar =
    'assets/images/avatars/default_patient_female.webp';

bool _isFemale(String? gender) => gender?.trim().toLowerCase() == 'female';

/// The default illustration for a doctor or patient of [gender] (the
/// profile's Male / Female / Other; anything but Female uses the first one).
String defaultAvatarAsset({required bool doctor, String? gender}) {
  if (doctor) {
    return _isFemale(gender) ? defaultFemaleDoctorAvatar : defaultDoctorAvatar;
  }
  return _isFemale(gender) ? defaultFemalePatientAvatar : defaultPatientAvatar;
}

/// A round profile picture: the uploaded photo, or the app's default doctor
/// or patient illustration when there's none or it fails to load.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.url,
    this.kind = AvatarKind.patient,
    this.gender,
    this.radius = 20,
    this.child,
  });

  final String? url;
  final AvatarKind kind;

  /// The person's profile gender; for [AvatarKind.self] it defaults to the
  /// signed-in user's.
  final String? gender;
  final double radius;

  /// Drawn on top of the picture (e.g. an upload spinner).
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = kind == AvatarKind.self
        ? ref.watch(authControllerProvider).value
        : null;
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
        defaultAvatarAsset(doctor: isDoctorKind, gender: gender ?? me?.gender),
      ),
      // Painted over the default; if the photo fails to load the default
      // stays visible.
      foregroundImage: photo != null ? NetworkImage(photo) : null,
      onForegroundImageError: photo != null ? (_, _) {} : null,
      child: child,
    );
  }
}
