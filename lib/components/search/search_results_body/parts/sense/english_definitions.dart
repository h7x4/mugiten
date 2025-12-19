import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';
import 'search_chip.dart';

class EnglishDefinitions extends StatelessWidget {
  final List<String> englishDefinitions;
  final ForegroundBackgroundThemeExtension colors;

  const EnglishDefinitions({
    super.key,
    required this.englishDefinitions,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    runSpacing: 10.0,
    spacing: 5,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final def in englishDefinitions)
        SearchChip(text: def, colors: colors),
    ],
  );
}
