import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadb/util/romaji_transliteration.dart';
import 'package:mugiten/models/themes/theme.dart';

import '../../../bloc/theme/theme_bloc.dart';
import '../../../routing/routes.dart';
import '../../../settings.dart';

enum YomiType { onyomi, kunyomi, meaning }

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

  const YomiChips({required this.yomi, required this.type, super.key});

  Widget yomiCard({
    required BuildContext context,
    required String yomi,
    required ColorSet colors,
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

    return Wrap(
      runSpacing: 10.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (type != YomiType.meaning)
          yomiCard(
            context: context,
            yomi: type == YomiType.kunyomi ? 'Kun:' : 'On:',
            searchable: false,
            colors: ColorSet(
              foreground: type.getColors(context).background,
              background: Colors.transparent,
            ),
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
