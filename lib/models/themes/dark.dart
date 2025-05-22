part of './theme.dart';

class DarkTheme extends AppTheme {
  const DarkTheme() : super();

  static const ColorSet defaultKanjiResultColor = ColorSet(
    foreground: Colors.white,
    background: Colors.green,
  );

  static const ColorSet defaultOnyomiColor = ColorSet(
    foreground: Colors.white,
    background: Colors.orange,
  );

  static const ColorSet defaultKunyomiColor = ColorSet(
    foreground: Colors.white,
    background: Colors.lightBlue,
  );

  static const Color defaultForeground = Colors.white;
  static const Color defaultBackground = Colors.black;

  static final defaultMenuGreyLight = ColorSet(
    foreground: Colors.white,
    background: Colors.grey.shade700,
  );
  static const defaultMenuGreyNormal = ColorSet(
    foreground: Colors.white,
    background: Colors.grey,
  );

  static final defaultMenuGreyDark = ColorSet(
    foreground: Colors.black,
    background: Colors.grey.shade300,
  );

  @override
  ColorSet get kanjiResultColor => defaultKanjiResultColor;

  @override
  ColorSet get onyomiColor => defaultOnyomiColor;

  @override
  ColorSet get kunyomiColor => defaultKunyomiColor;

  @override
  Color get foreground => defaultForeground;
  @override
  Color get background => defaultBackground;

  @override
  ColorSet get menuGreyLight => defaultMenuGreyLight;
  @override
  ColorSet get menuGreyNormal => defaultMenuGreyNormal;

  @override
  ColorSet get menuGreyDark => defaultMenuGreyDark;

  @override
  ThemeData getMaterialTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: createMaterialColor(AppTheme.mugitenWheat.background),
    );
  }
}
