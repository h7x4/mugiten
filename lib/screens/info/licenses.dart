import 'package:flutter/material.dart';

import '../../settings.dart';

class LicensesView extends StatelessWidget {
  const LicensesView({super.key});

  @override
  Widget build(BuildContext context) => LicensePage(
        applicationName: '麦典',
        applicationVersion: 'Version: $appVersion',
        applicationIcon: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(
                child: Image.asset(
                  'assets/images/logo/mugi.png',
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
}
