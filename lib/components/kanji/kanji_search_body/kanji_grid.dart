import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

import '../../../routing/routes.dart';
import '../../../settings.dart';

class KanjiGrid extends StatelessWidget {
  final List<String> suggestions;

  const KanjiGrid({required this.suggestions, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        children: suggestions.map((kanji) => _GridItem(kanji)).toList(),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final String kanji;
  const _GridItem(this.kanji);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MenuGreyLightThemeExtension>()!;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, Routes.kanjiSearch, arguments: kanji);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          margin: const EdgeInsets.all(10.0),
          child: FittedBox(
            child: Text(
              kanji,
              style: japaneseFont.value.textStyle.merge(
                TextStyle(color: colors.foregroundColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
