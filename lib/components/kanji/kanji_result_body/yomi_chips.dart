import 'package:flutter/material.dart';
import 'package:jadb/util/romaji_transliteration.dart';

import '../../../bloc/theme/theme_bloc.dart';
import '../../../routing/routes.dart';
import '../../../settings.dart';

enum YomiType {
  onyomi,
  kunyomi,
  meaning,
}

extension on YomiType {
  String get title {
    switch (this) {
      case YomiType.onyomi:
        return 'Onyomi';
      case YomiType.kunyomi:
        return 'Kunyomi';
      case YomiType.meaning:
        return 'Meanings';
    }
  }

  ColorSet getColors(BuildContext context) {
    // TODO: convert this into a blocbuilder or bloclistener
    final theme = BlocProvider.of<ThemeBloc>(context).state.theme;

    switch (this) {
      case YomiType.onyomi:
        return theme.onyomiColor;
      case YomiType.kunyomi:
        return theme.kunyomiColor;
      case YomiType.meaning:
        return theme.menuGreyNormal;
    }
  }
}

class YomiChips extends StatelessWidget {
  final List<String> yomi;
  final YomiType type;

  const YomiChips({
    required this.yomi,
    required this.type,
    super.key,
  });

  bool get isExpandable => yomi.length > 6;

  Widget yomiCard({
    required BuildContext context,
    required String yomi,
    required ColorSet colors,
    TextStyle? extraTextStyle,
  }) =>
      InkWell(
        onTap: () =>
            Navigator.pushNamed(context, Routes.search, arguments: yomi),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 10.0,
          ),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            yomi,
            style: TextStyle(
              fontSize: 20.0,
              color: colors.foreground,
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
            colors: type.getColors(context),
            extraTextStyle: type != YomiType.meaning && !romajiEnabled
                ? japaneseFont.textStyle
                : null,
          ),
        )
        .toList();

    final yomiCardsWithTitle = <Widget>[
      if (type != YomiType.meaning)
        yomiCard(
          context: context,
          yomi: type == YomiType.kunyomi ? 'Kun:' : 'On:',
          colors: ColorSet(
            foreground: type.getColors(context).background,
            background: Colors.transparent,
          ),
        ),
      ...yomiCards
    ];

    final wrap = Wrap(
      runSpacing: 10.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: yomiCardsWithTitle,
    );

    if (!isExpandable) {
      return wrap;
    } else {
      return ExpansionTile(
        title: Center(
          child: yomiCard(
            context: context,
            yomi: type.title,
            colors: type.getColors(context),
          ),
        ),
        children: [
          const SizedBox(height: 20.0),
          wrap,
          const SizedBox(height: 25.0),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 5.0,
      ),
      alignment: Alignment.centerLeft,
      child: yomiWrapper(context),
    );
  }
}
