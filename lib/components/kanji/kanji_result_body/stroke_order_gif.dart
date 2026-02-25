import 'package:flutter/material.dart';
import 'package:kanimaji/kanimaji.dart';
import 'package:mugiten/theme.dart';

class StrokeOrderGif extends StatelessWidget {
  final String kanji;

  const StrokeOrderGif({required this.kanji, super.key});

  @override
  Widget build(BuildContext context) {
    final kanjiResultColors = Theme.of(
      context,
    ).extension<KanjiResultThemeExtension>()!;
    final menuGreyLightColors = Theme.of(
      context,
    ).extension<MenuGreyLightThemeExtension>()!;

    return Container(
      height: MediaQuery.of(context).size.width * 0.40,
      width: MediaQuery.of(context).size.width * 0.40,
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: menuGreyLightColors.backgroundColor,
        borderRadius: BorderRadius.circular(15.0),
        border: BoxBorder.all(
          color: kanjiResultColors.backgroundColor!,
          width: 4.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Kanimaji(
          kanji: kanji,
          strokeColor: Theme.of(context).colorScheme.onSurface,
          strokeUnfilledColor: menuGreyLightColors.foregroundColor!.withAlpha(
            0x40,
          ),
        ),
      ),
    );
  }
}
