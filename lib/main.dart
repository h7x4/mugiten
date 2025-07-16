import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mugiten/screens/initialization.dart';
import 'package:mugiten/services/initialization/initialization_logic.dart';

import 'bloc/theme/theme_bloc.dart';
import 'routing/router.dart';
import 'settings.dart';

void runInitializationScreen(bool deleteDatabase) {
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
  final ThemeBloc themeBloc = ThemeBloc();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (autoThemeEnabled) {
      final themeIsDark =
          WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      themeBloc.add(SetTheme(themeIsDark: themeIsDark));
    }
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => themeBloc)],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) => MaterialApp(
          title: '麦典',
          theme: themeState.theme.getMaterialTheme(),
          initialRoute: '/',
          onGenerateRoute: generateRoute,
        ),
      ),
    );
  }
}
