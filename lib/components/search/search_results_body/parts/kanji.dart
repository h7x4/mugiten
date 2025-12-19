import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

import '../../../../routing/routes.dart';
import '../../../../settings.dart';

class KanjiRow extends StatelessWidget {
  final List<String> kanji;
  final double fontSize;
  const KanjiRow({super.key, required this.kanji, this.fontSize = 20});

  Widget _kanjiBox(BuildContext context, String kanji) {
    final colors = Theme.of(context).extension<MenuGreyLightThemeExtension>()!;

    return UnconstrainedBox(
      child: IntrinsicHeight(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FittedBox(
              child: Text(
                kanji,
                style: TextStyle(
                  color: colors.foregroundColor,
                  fontSize: fontSize,
                ).merge(japaneseFont.textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kanji:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final k in kanji)
              InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.kanjiSearch,
                  arguments: k,
                ),
                child: _kanjiBox(context, k),
              ),
          ],
        ),
      ],
    );
  }
}
