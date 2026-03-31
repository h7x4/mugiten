import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: mugitenWheatBackground),
      child: const Center(
        child: Image(image: AssetImage('assets/images/logo/mugi.png')),
      ),
    );
  }
}
