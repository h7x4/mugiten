import 'package:flutter/material.dart';

part 'light.dart';
part 'dark.dart';

abstract class AppTheme {
  const AppTheme();

  static const ColorSet mugitenWheat = ColorSet(
    foreground: Colors.black,
    // background: Color(0xFF3EDD00),
    background: Color(0xFFFFE680),
  );

  static const Color mugitenGrey = Color(0xFF5A5A5B);

  static const ColorSet mugitenLabel = ColorSet(
    foreground: Colors.white,
    background: Color(0xFF909DC0),
  );

  static const ColorSet mugitenCommonColor = ColorSet(
    foreground: Colors.white,
    background: Color(0xFF8ABC83),
  );

  ColorSet get kanjiResultColor;

  ColorSet get onyomiColor;
  ColorSet get kunyomiColor;

  Color get foreground;
  Color get background;

  ColorSet get menuGreyLight;
  ColorSet get menuGreyNormal;
  ColorSet get menuGreyDark;

  ThemeData getMaterialTheme();
}

class ColorSet {
  final Color foreground;
  final Color background;

  const ColorSet({required this.foreground, required this.background});
}

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
