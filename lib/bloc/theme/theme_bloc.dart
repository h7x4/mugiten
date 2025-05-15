import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/themes/theme.dart';
import '../../settings.dart';

export 'package:flutter_bloc/flutter_bloc.dart';
export 'package:mugiten/models/themes/theme.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const LightThemeState()) {
    on<SetTheme>(
      (event, emit) => emit(
        event.themeIsDark ? const DarkThemeState() : const LightThemeState(),
      ),
    );

    final bool autoThemeIsDark =
        SchedulerBinding.instance.window.platformBrightness == Brightness.dark;

    add(
      SetTheme(
        themeIsDark: autoThemeEnabled ? autoThemeIsDark : darkThemeEnabled,
      ),
    );
  }
}
