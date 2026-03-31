import 'package:flutter/material.dart';
import 'package:mugiten/components/search/search_results_body/parts/sense/search_chip.dart';
import 'package:mugiten/theme.dart';

class EnglishDefinitions extends StatelessWidget {
  final List<String> englishDefinitions;
  final ForegroundBackgroundThemeExtension colors;

  const EnglishDefinitions({
    super.key,
    required this.englishDefinitions,
    required this.colors,
  });

  @override
  Widget build(final BuildContext context) => Wrap(
    runSpacing: 10.0,
    spacing: 5,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final def in englishDefinitions)
        SearchChip(text: def, colors: colors),
    ],
  );
}
