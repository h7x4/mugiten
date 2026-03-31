import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/routing/router.dart';
import 'package:mugiten/screens/initialization.dart';
import 'package:mugiten/services/initialization/initialization_logic.dart';
import 'package:mugiten/theme.dart';

void runInitializationScreen(final bool deleteDatabase) {
  runApp(
    InitializationView(
      onInitializationComplete: () =>
          quickInitialization().then((_) => runApp(const MyApp())),
      deleteDatabase: deleteDatabase,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await needsInitialization()) {
    runInitializationScreen(false);
  } else {
    await quickInitialization();
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final themeController = ThemeController.create();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
    GetIt.instance.registerSingleton<ThemeController>(themeController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    themeController.updateThemeMode();
  }

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeController.themeMode,
      builder: (final context, final themeMode, _) {
        return MaterialApp(
          title: '麦典',
          theme: themeMode.lightThemeData,
          darkTheme: themeMode.darkThemeData,
          themeMode: themeMode.themeMode,
          initialRoute: '/',
          onGenerateRoute: generateRoute,
        );
      },
    );
  }
}
