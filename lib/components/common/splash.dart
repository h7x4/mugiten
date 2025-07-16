import 'package:flutter/material.dart';

import '../../models/themes/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.mugitenWheat.background),
      child: const Center(
        child: Image(image: AssetImage('assets/images/logo/mugi.png')),
      ),
    );
  }
}
