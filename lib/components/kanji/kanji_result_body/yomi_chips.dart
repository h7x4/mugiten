import 'package:flutter/material.dart';
import 'package:jadb/search/word_search/word_search.dart';
import 'package:jadb/util/romaji_transliteration.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/settings.dart';
import 'package:mugiten/theme.dart';

enum YomiType { onyomi, kunyomi, meaning }

extension on YomiType {
  // String get title {
  //   switch (this) {
  //     case YomiType.onyomi:
  //       return 'Onyomi';
  //     case YomiType.kunyomi:
  //       return 'Kunyomi';
  //     case YomiType.meaning:
  //       return 'Meanings';
  //   }
  // }

  Color getColor(final BuildContext context) {
    switch (this) {
      case YomiType.onyomi:
        return Theme.of(context).extension<YomiThemeExtension>()!.onyomiColor!;
      case YomiType.kunyomi:
        return Theme.of(context).extension<YomiThemeExtension>()!.kunyomiColor!;
      case YomiType.meaning:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class YomiChips extends StatelessWidget {
  final List<String> yomi;
  final YomiType type;

  const YomiChips({required this.yomi, required this.type, super.key});

  Widget yomiCard({
    required final BuildContext context,
    required final String yomi,
    required final Color? color,
    final bool searchable = true,
    final TextStyle? extraTextStyle,
  }) => InkWell(
    onTap: searchable
        ? () => Navigator.pushNamed(
            context,
            Routes.search,
            arguments: (
              yomi,
              type == YomiType.meaning ? SearchMode.english : SearchMode.kana,
            ),
          )
        : null,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        yomi,
        style: TextStyle(
          fontSize: 20.0,
          color: Theme.of(context).colorScheme.onPrimary,
        ).merge(extraTextStyle),
      ),
    ),
  );

  Widget yomiWrapper(final BuildContext context) {
    final yomiCards = yomi
        .map((final y) => romajiEnabled.value ? transliterateKanaToLatin(y) : y)
        .map(
          (final y) => yomiCard(
            context: context,
            yomi: y,
            color: type.getColor(context),
            extraTextStyle: type != YomiType.meaning && !romajiEnabled.value
                ? japaneseFont.value.textStyle
                : null,
          ),
        )
        .toList();

    return Wrap(
      runSpacing: 10.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (type != YomiType.meaning)
          yomiCard(
            context: context,
            yomi: type == YomiType.kunyomi ? 'Kun:' : 'On:',
            searchable: false,
            color: type.getColor(context),
          ),
        ...yomiCards,
      ],
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      alignment: Alignment.centerLeft,
      child: yomiWrapper(context),
    );
  }
}
