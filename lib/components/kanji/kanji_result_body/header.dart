import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

import '../../../settings.dart';

class Header extends StatelessWidget {
  final String kanji;

  const Header({required this.kanji, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KanjiResultThemeExtension>()!;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: colors.backgroundColor,
        ),
        child: Text(
          kanji,
          style: TextStyle(
            fontSize: 70.0,
            color: colors.foregroundColor,
          ).merge(japaneseFont.textStyle),
        ),
      ),
    );
  }
}
