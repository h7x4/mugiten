import 'package:flutter/material.dart';
import 'package:mugiten/settings.dart';

class YomiThemeExtension extends ThemeExtension<YomiThemeExtension> {
  final Color? onyomiColor;
  final Color? kunyomiColor;

  const YomiThemeExtension({this.onyomiColor, this.kunyomiColor});

  @override
  ThemeExtension<YomiThemeExtension> copyWith({
    Color? onyomiColor,
    Color? kunyomiColor,
  }) => YomiThemeExtension(
    onyomiColor: onyomiColor ?? this.onyomiColor,
    kunyomiColor: kunyomiColor ?? this.kunyomiColor,
  );

  @override
  ThemeExtension<YomiThemeExtension> lerp(
    ThemeExtension<YomiThemeExtension>? other,
    double t,
  ) => other is! YomiThemeExtension
      ? this
      : YomiThemeExtension(
          onyomiColor: Color.lerp(onyomiColor, other.onyomiColor, t),
          kunyomiColor: Color.lerp(kunyomiColor, other.kunyomiColor, t),
        );
}

abstract class ForegroundBackgroundThemeExtension<T extends ThemeExtension<T>>
    extends ThemeExtension<T> {
  final Color? foregroundColor;
  final Color? backgroundColor;

  const ForegroundBackgroundThemeExtension({
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  ThemeExtension<T> copyWith({Color? foregroundColor, Color? backgroundColor});

  @override
  ThemeExtension<T> lerp(ThemeExtension<T>? other, double t) =>
      other is! ForegroundBackgroundThemeExtension<T>
      ? this as T
      : copyWith(
              foregroundColor: Color.lerp(
                foregroundColor,
                other.foregroundColor,
                t,
              ),
              backgroundColor: Color.lerp(
                backgroundColor,
                other.backgroundColor,
                t,
              ),
            )
            as T;
}

class KanjiResultThemeExtension
    extends ForegroundBackgroundThemeExtension<KanjiResultThemeExtension> {
  const KanjiResultThemeExtension({
    super.foregroundColor,
    super.backgroundColor,
  });

  @override
  ThemeExtension<KanjiResultThemeExtension> copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
  }) => KanjiResultThemeExtension(
    foregroundColor: foregroundColor ?? this.foregroundColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
  );
}

class MenuGreyLightThemeExtension
    extends ForegroundBackgroundThemeExtension<MenuGreyLightThemeExtension> {
  const MenuGreyLightThemeExtension({
    super.foregroundColor,
    super.backgroundColor,
  });

  @override
  ThemeExtension<MenuGreyLightThemeExtension> copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
  }) => MenuGreyLightThemeExtension(
    foregroundColor: foregroundColor ?? this.foregroundColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
  );
}

class MenuGreyNormalThemeExtension
    extends ForegroundBackgroundThemeExtension<MenuGreyNormalThemeExtension> {
  const MenuGreyNormalThemeExtension({
    super.foregroundColor,
    super.backgroundColor,
  });

  @override
  ThemeExtension<MenuGreyNormalThemeExtension> copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
  }) => MenuGreyNormalThemeExtension(
    foregroundColor: foregroundColor ?? this.foregroundColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
  );
}

class MenuGreyDarkThemeExtension
    extends ForegroundBackgroundThemeExtension<MenuGreyDarkThemeExtension> {
  const MenuGreyDarkThemeExtension({
    super.foregroundColor,
    super.backgroundColor,
  });

  @override
  ThemeExtension<MenuGreyDarkThemeExtension> copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
  }) => MenuGreyDarkThemeExtension(
    foregroundColor: foregroundColor ?? this.foregroundColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
  );
}

const Color mugitenWheatForeground = Colors.black;
const Color mugitenWheatBackground = Color(0xFFFFE680);

const Color mugitenGrey = Color(0xFF5A5A5B);

const Color mugitenLabelForeground = Colors.white;
const Color mugitenLabelBackground = Color(0xFF909DC0);

const Color mugitenCommonForeground = Colors.white;
const Color mugitenCommonBackground = Color(0xFF8ABC83);

/// Source: https://blog.usejournal.com/creating-a-custom-color-swatch-in-flutter-554bcdcb27f3
MaterialColor createMaterialColor(Color color) {
  final List<double> strengths = [.05];
  final swatch = <int, Color>{};
  final int r = (color.r * 255.0).round().clamp(0, 255);
  final int g = (color.g * 255.0).round().clamp(0, 255);
  final int b = (color.b * 255.0).round().clamp(0, 255);

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  for (final strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.toARGB32(), swatch);
}

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  primarySwatch: createMaterialColor(mugitenWheatBackground),

  // colorScheme: ColorScheme.light(
  //   surface: Color(0xFFF2E6C9), // Pale Grain
  //   primary: Color(0xFFD8B25C), // Golden Wheat
  //   secondary: Color(0xFFC9A44C), // Straw
  //   error: Color(0xFFB5543C), // Clay Red

  //   onSurface: Color(0xFF3E3A2F),
  //   onPrimary: Color(0xFF3E3A2F),
  //   onSecondary: Color(0xFF3E3A2F),
  //   onError: Colors.white,
  // ),
  extensions: <ThemeExtension<dynamic>>[
    const YomiThemeExtension(
      onyomiColor: Color(0xFFFFA726), // Orange
      kunyomiColor: Color(0xFF29B6F6), // Light Blue
    ),
    const KanjiResultThemeExtension(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blue,
    ),
    MenuGreyLightThemeExtension(
      foregroundColor: Colors.black,
      backgroundColor: Colors.grey.shade300,
    ),
    const MenuGreyNormalThemeExtension(
      foregroundColor: Colors.white,
      backgroundColor: Colors.grey,
    ),
    MenuGreyDarkThemeExtension(
      foregroundColor: Colors.white,
      backgroundColor: Colors.grey.shade700,
    ),
  ],

  // scaffoldBackgroundColor: const Color(0xFFFAF3E0),

  // dividerColor: const Color(0xFFECE7DC), // Light gray (Chaff)

  // textTheme: const TextTheme(
  //   bodyLarge: TextStyle(color: Color(0xFF3E3A2F)),
  //   bodyMedium: TextStyle(color: Color(0xFF6B6555)),
  //   labelLarge: TextStyle(color: Color(0xFF3E3A2F)),
  // ),

  // elevatedButtonTheme: ElevatedButtonThemeData(
  //   style: ElevatedButton.styleFrom(
  //     backgroundColor: const Color(0xFFD8B25C),
  //     foregroundColor: const Color(0xFF3E3A2F),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //   ),
  // ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  primarySwatch: createMaterialColor(mugitenWheatBackground),

  // colorScheme: const ColorScheme.dark(
  //   surface: Color(0xFF2A2720), // Loam
  //   primary: Color(0xFFE3C77A), // Warm Wheat
  //   secondary: Color(0xFFC6A85A), // Toasted Grain
  //   error: Color(0xFFB5543C),

  //   onSurface: Color(0xFFF5EEDC),
  //   onPrimary: Color(0xFF1E1C17),
  //   onSecondary: Color(0xFF1E1C17),
  //   onError: Colors.black,
  // ),
  extensions: <ThemeExtension<dynamic>>[
    const YomiThemeExtension(
      onyomiColor: Color(0xFFFFA726),
      kunyomiColor: Color(0xFF29B6F6),
    ),
    const KanjiResultThemeExtension(
      foregroundColor: Colors.white,
      backgroundColor: Colors.green,
    ),
    MenuGreyLightThemeExtension(
      foregroundColor: Colors.white,
      backgroundColor: Colors.grey.shade700,
    ),
    const MenuGreyNormalThemeExtension(
      foregroundColor: Colors.white,
      backgroundColor: Colors.grey,
    ),
    MenuGreyDarkThemeExtension(
      foregroundColor: Colors.black,
      backgroundColor: Colors.grey.shade300,
    ),
  ],

  // scaffoldBackgroundColor: const Color(0xFF1E1C17),

  // dividerColor: const Color(0xFF4A463B), // Dark gray (Charred Husk)

  // textTheme: const TextTheme(
  //   bodyLarge: TextStyle(color: Color(0xFFF5EEDC)),
  //   bodyMedium: TextStyle(color: Color(0xFFCFC7B2)),
  //   labelLarge: TextStyle(color: Color(0xFFF5EEDC)),
  // ),

  // iconTheme: const IconThemeData(
  //   color: Color(0xFFD6D0C3), // Light gray (Moonlit Chaff)
  // ),

  // elevatedButtonTheme: ElevatedButtonThemeData(
  //   style: ElevatedButton.styleFrom(
  //     backgroundColor: const Color(0xFFE3C77A),
  //     foregroundColor: const Color(0xFF1E1C17),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //   ),
  // ),
);

enum AppThemeMode {
  light,
  dark,
  system;

  String get id => switch (this) {
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
    AppThemeMode.system => 'system',
  };

  factory AppThemeMode.fromId(String id) => switch (id) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    'system' => AppThemeMode.system,
    _ => throw ArgumentError('Invalid theme mode id: $id'),
  };

  ThemeData? get lightThemeData => switch (this) {
    AppThemeMode.light => lightTheme,
    AppThemeMode.dark => darkTheme,
    AppThemeMode.system => lightTheme,
  };

  ThemeData? get darkThemeData => switch (this) {
    AppThemeMode.light => lightTheme,
    AppThemeMode.dark => darkTheme,
    AppThemeMode.system => darkTheme,
  };

  ThemeMode get themeMode => switch (this) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  Brightness get brightness => switch (this) {
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
    AppThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };
}

class ThemeController {
  final ValueNotifier<AppThemeMode> themeMode;

  ThemeController(AppThemeMode mode) : themeMode = ValueNotifier(mode);

  factory ThemeController.create() {
    AppThemeMode initialMode;
    if (autoThemeEnabled.value) {
      initialMode = AppThemeMode.system;
    } else {
      initialMode = darkThemeEnabled.value ? AppThemeMode.dark : AppThemeMode.light;
    }

    return ThemeController(initialMode);
  }

  void setThemeMode(AppThemeMode mode) {
    if (mode != themeMode.value) {
      if (mode == AppThemeMode.system) {
        autoThemeEnabled.value = true;
      } else {
        autoThemeEnabled.value = false;
        darkThemeEnabled.value = mode == AppThemeMode.dark;
      }
      themeMode.value = mode;
    }
  }

  void updateThemeMode() {
    if (autoThemeEnabled.value) {
      final platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      themeMode.value = platformBrightness == Brightness.dark
          ? AppThemeMode.dark
          : AppThemeMode.light;
    } else {
      themeMode.value = darkThemeEnabled.value
          ? AppThemeMode.dark
          : AppThemeMode.light;
    }
  }
}
