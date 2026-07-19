import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: SvgPicture.asset('assets/images/ask-musawo-logo.svg'),
            ),
            const SizedBox(height: 16),
            const Text('Ask Musawo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
