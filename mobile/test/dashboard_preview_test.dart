import 'dart:io';
import 'dart:ui' as ui;

import 'package:ask_musawo/core/theme/app_theme.dart';
import 'package:ask_musawo/features/appointments/data/appointment.dart';
import 'package:ask_musawo/features/appointments/state/appointment_providers.dart';
import 'package:ask_musawo/features/auth/data/app_user.dart';
import 'package:ask_musawo/features/auth/state/auth_controller.dart';
import 'package:ask_musawo/features/doctors/data/doctor.dart';
import 'package:ask_musawo/features/doctors/state/doctor_providers.dart';
import 'package:ask_musawo/features/home/presentation/patient_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final outDir = '/var/folders/_3/xgvs39s52cq9g2d74pff_y580000gn/T/opencode';

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required AppUser user,
    required List<Appointment> appointments,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuthController(user)),
          categoriesWithCountsProvider.overrideWith((ref) async => _categories),
          featuredDoctorsProvider.overrideWith((ref) async => _doctors),
          myAppointmentsProvider.overrideWith((ref) async => appointments),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          home: RepaintBoundary(
            key: const Key('preview'),
            child: const PatientHomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('preview')));
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('preview dashboard with upcoming appointment', (tester) async {
    final user = AppUser(
      id: 'u1',
      name: 'Kiwana',
      email: 'kiwana@example.com',
      role: 'patient',
    );
    final appointment = Appointment(
      id: 'a1',
      doctorName: 'Dr. Namutebi Sarah',
      date: DateTime.now(),
      status: 'confirmed',
      isVirtual: true,
      time: '10:30 AM',
      reason: 'Follow-up',
    );

    await pumpDashboard(tester, user: user, appointments: [appointment]);
    await capture(tester, 'dashboard_home.png');

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 400));
    await capture(tester, 'dashboard_scrolled.png');
  });

  testWidgets('preview dashboard without appointment', (tester) async {
    final user = AppUser(
      id: 'u1',
      name: 'Kiwana',
      email: 'kiwana@example.com',
      role: 'patient',
    );

    await pumpDashboard(tester, user: user, appointments: const []);
    await capture(tester, 'dashboard_no_appointment.png');
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);

  final AppUser user;

  @override
  Future<AppUser?> build() async => user;
}

final _categories = [
  CategoryWithCount(
    Category(id: 'c1', name: 'Internal Medicine', iconKey: 'internal_medicine', colorKey: 'blue'),
    12,
  ),
  CategoryWithCount(
    Category(id: 'c2', name: 'Pediatrics', iconKey: 'pediatrics', colorKey: 'teal'),
    8,
  ),
  CategoryWithCount(
    Category(id: 'c3', name: 'Cardiology', iconKey: 'cardiology', colorKey: 'pink'),
    5,
  ),
  CategoryWithCount(
    Category(id: 'c4', name: 'Dermatology', iconKey: 'dermatology', colorKey: 'orange'),
    6,
  ),
  CategoryWithCount(
    Category(id: 'c5', name: 'Neurology', iconKey: 'neurology', colorKey: 'purple'),
    4,
  ),
];

final _doctors = [
  Doctor(
    id: 'd1',
    name: 'Dr. Namutebi Sarah',
    specialization: 'Cardiologist',
    consultationFee: 50000,
    rating: 4.9,
    reviewCount: 120,
  ),
  Doctor(
    id: 'd2',
    name: 'Dr. Okello James',
    specialization: 'Pediatrician',
    consultationFee: 40000,
    rating: 4.8,
    reviewCount: 96,
  ),
  Doctor(
    id: 'd3',
    name: 'Dr. Achieng Grace',
    specialization: 'Dermatologist',
    consultationFee: 45000,
    rating: 4.7,
    reviewCount: 78,
  ),
  Doctor(
    id: 'd4',
    name: 'Dr. Kato David',
    specialization: 'Neurologist',
    consultationFee: 60000,
    rating: 5.0,
    reviewCount: 64,
  ),
];
