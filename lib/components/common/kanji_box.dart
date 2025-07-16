import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/theme/theme_bloc.dart';
import '../../settings.dart';

/// The ratio is defined as 'the amount of space the text should take'
/// divided by 'the amount of space the padding should take'.
///
/// So if the KanjiBox should span 50 pixels, and you wanted 10 of those pixels
/// to be used for padding (5 on each side), and 40 to be used for the text,
/// you could write:
///
/// ```dart
/// KanjiBox.withRatioAndFontSize({
///   kanji: '例',
///   ratio: 4 / 1,
///   fontSize: 40,
/// })
/// ```
///
class KanjiBox extends StatelessWidget {
  final String kanji;
  final double? fontSize;
  final double? padding;
  final Color? foreground;
  final Color? background;
  final double? contentPaddingRatio;
  final double borderRadius;

  static const double defaultRatio = 3 / 1;
  static const double defaultBorderRadius = 10;

  double get ratio => contentPaddingRatio ?? fontSize! / padding!;
  double get fontSizeFactor => ratio / (ratio + 1);
  double get paddingSizeFactor => 1 / (ratio + 1);

  bool get isExpanded => contentPaddingRatio != null;
  double? get size => isExpanded ? null : fontSize! + (2 * padding!);
  double? get oneSidePadding => padding != null ? padding! / 2 : null;

  const KanjiBox._({
    super.key,
    required this.kanji,
    this.fontSize,
    this.padding,
    this.contentPaddingRatio,
    this.foreground,
    this.background,
    this.borderRadius = defaultBorderRadius,
  }) : assert(
         kanji.length == 1,
         'KanjiBox can not show more than one character at a time',
       ),
       assert(
         contentPaddingRatio != null || (fontSize != null && padding != null),
         'Either contentPaddingRatio or both the fontSize and padding need to be '
         'explicitly defined in order for the box to be able to render correctly',
       );

  const factory KanjiBox.withFontSizeAndPadding({
    required String kanji,
    required double fontSize,
    required double padding,
    Color? foreground,
    Color? background,
    double borderRadius,
  }) = KanjiBox._;

  factory KanjiBox.withFontSize({
    required String kanji,
    required double fontSize,
    double ratio = defaultRatio,
    Color? foreground,
    Color? background,
    double borderRadius = defaultBorderRadius,
  }) => KanjiBox._(
    kanji: kanji,
    fontSize: fontSize,
    padding: pow(ratio * (1 / fontSize), -1).toDouble(),
    foreground: foreground,
    background: background,
    borderRadius: borderRadius,
  );

  factory KanjiBox.withPadding({
    required String kanji,
    double ratio = defaultRatio,
    required double padding,
    Color? foreground,
    Color? background,
    double borderRadius = defaultBorderRadius,
  }) => KanjiBox._(
    kanji: kanji,
    fontSize: ratio * padding,
    padding: padding,
    foreground: foreground,
    background: background,
    borderRadius: borderRadius,
  );

  factory KanjiBox.expanded({
    required String kanji,
    double ratio = defaultRatio,
    Color? foreground,
    Color? background,
    double borderRadius = defaultBorderRadius,
  }) => KanjiBox._(
    kanji: kanji,
    contentPaddingRatio: ratio,
    foreground: foreground,
    background: background,
    borderRadius: borderRadius,
  );

  /// A shortcut
  factory KanjiBox.headline4({
    required BuildContext context,
    required String kanji,
    double ratio = defaultRatio,
    Color? foreground,
    Color? background,
    double borderRadius = defaultBorderRadius,
  }) => KanjiBox.withFontSize(
    kanji: kanji,
    fontSize: Theme.of(context).textTheme.displaySmall!.fontSize!,
    ratio: ratio,
    foreground: foreground,
    background: background,
    borderRadius: borderRadius,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final calculatedForeground =
            foreground ?? state.theme.menuGreyLight.foreground;
        final calculatedBackground =
            background ?? state.theme.menuGreyLight.background;
        return LayoutBuilder(
          builder: (context, constraints) {
            final sizeConstraint = min(
              constraints.maxHeight,
              constraints.maxWidth,
            );
            final calculatedFontSize =
                fontSize ?? sizeConstraint * fontSizeFactor;
            final calculatedPadding =
                oneSidePadding ?? (sizeConstraint * paddingSizeFactor) / 2;

            return Container(
              padding: EdgeInsets.all(calculatedPadding),
              alignment: Alignment.center,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: calculatedBackground,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: FittedBox(
                child: Text(
                  kanji,
                  textScaler: TextScaler.linear(1),
                  style: TextStyle(
                    color: calculatedForeground,
                    fontSize: calculatedFontSize,
                  ).merge(japaneseFont.textStyle),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
