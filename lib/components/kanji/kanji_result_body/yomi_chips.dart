import 'package:flutter/material.dart';
import 'package:jadb/util/romaji_transliteration.dart';
import 'package:mugiten/theme.dart';

import '../../../routing/routes.dart';
import '../../../settings.dart';

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

  Color getColor(BuildContext context) {
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
    required BuildContext context,
    required String yomi,
    required Color? color,
    bool searchable = true,
    TextStyle? extraTextStyle,
  }) => InkWell(
    onTap: searchable
        ? () => Navigator.pushNamed(context, Routes.search, arguments: yomi)
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

  Widget yomiWrapper(BuildContext context) {
    final yomiCards = yomi
        .map((y) => romajiEnabled ? transliterateKanaToLatin(y) : y)
        .map(
          (y) => yomiCard(
            context: context,
            yomi: y,
            color: type.getColor(context),
            extraTextStyle: type != YomiType.meaning && !romajiEnabled
                ? japaneseFont.textStyle
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      alignment: Alignment.centerLeft,
      child: yomiWrapper(context),
    );
  }
}
