import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mugiten/services/initialization/initialization_cubit.dart';
import 'package:mugiten/services/initialization/initialization_status.dart';

class InitializationView extends StatelessWidget {
  final VoidCallback? onInitializationComplete;
  final InitializationCubit cubit;

  InitializationView({
    super.key,
    required this.onInitializationComplete,
    required bool deleteDatabase,
  }) : cubit = InitializationCubit(deleteDatabase);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Image.asset('assets/images/logo/mugi.png', height: 100),
              const SizedBox(height: 20),
              BlocBuilder<InitializationCubit, InitializationStatus>(
                bloc: cubit,
                builder: (context, state) {
                  switch (state) {
                    case InitializationNotStarted _:
                      cubit.start();
                      return const CircularProgressIndicator();

                    case InitializationPending _:
                      return const CircularProgressIndicator();

                    case CheckMLKitDigitalInkModel _:
                      return const Text('Checking for ML Kit updates...');

                    case DownloadMLKitDigitalInkModel _:
                      return const Text('Downloading ML Kit model...');

                    case FinishDownloadMLKitDigitalInkModel _:
                      return const Text('ML Kit model downloaded successfully');

                    case CheckDatabase _:
                      return const Text('Checking for database updates...');

                    case BackupUserData s:
                      return Column(
                        children: [
                          const Text('Backing up user data...'),
                          LinearProgressIndicator(value: s.progress / s.total),
                        ],
                      );

                    case MigrateDatabase s:
                      return Column(
                        children: [
                          const Text('Performing database migrations...'),
                          LinearProgressIndicator(value: s.progress / s.total),
                        ],
                      );

                    case RestoreUserData s:
                      return Column(
                        children: [
                          const Text('Restoring user data...'),
                          LinearProgressIndicator(value: s.progress / s.total),
                        ],
                      );

                    case DatabaseUpdateFinished _:
                      return const Text('Database update finished');

                    case InitializationComplete _:
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onInitializationComplete?.call();
                      });
                      return const Text('Initialization Complete');

                    default:
                      return const CircularProgressIndicator();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
