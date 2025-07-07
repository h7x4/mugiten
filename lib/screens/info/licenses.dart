import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LicensesView extends StatelessWidget {
  const LicensesView({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final packageInfo = snapshot.data!;
          return _buildLicensePage(packageInfo);
        },
      );

  Widget _buildLicensePage(PackageInfo packageInfo) => LicensePage(
        applicationName: '麦典',
        applicationVersion: 'Version: ${packageInfo.version}',
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
