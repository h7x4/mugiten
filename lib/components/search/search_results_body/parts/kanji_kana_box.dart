import 'package:flutter/material.dart';
import 'package:jadb/util/romaji_transliteration.dart';
import 'package:mugiten/theme.dart';

import '../../../../settings.dart';

class KanjiKanaBox extends StatelessWidget {
  final String baseWord;
  final String? furigana;
  final bool showRomajiBelow;
  final ForegroundBackgroundThemeExtension colors;
  final bool autoTransliterateRomaji;
  final bool centerFurigana;
  final double? furiganaFontsize;
  final double? kanjiFontsize;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const KanjiKanaBox({
    super.key,
    required this.baseWord,
    required this.furigana,
    required this.colors,
    this.showRomajiBelow = false,
    this.autoTransliterateRomaji = true,
    this.centerFurigana = true,
    this.furiganaFontsize,
    this.kanjiFontsize,
    this.margin = const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
    this.padding = const EdgeInsets.all(5.0),
  });

  @override
  Widget build(BuildContext context) {
    final fFontsize =
        furiganaFontsize ??
        ((kanjiFontsize != null) ? 0.8 * kanjiFontsize! : null);

    return Container(
      margin: margin,
      padding: padding,
      color: colors.backgroundColor,
      child: DefaultTextStyle.merge(
        child: Column(
          crossAxisAlignment: centerFurigana
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            (furigana != null)
                ? Text(
                    romajiEnabled.value
                        ? transliterateKanaToLatin(furigana!)
                        : furigana!,
                    style:
                        TextStyle(
                          fontSize: fFontsize,
                          color: colors.foregroundColor,
                        ).merge(
                          romajiEnabled.value && autoTransliterateRomaji
                              ? null
                              : japaneseFont.value.textStyle,
                        ),
                  )
                : Text(
                    'あ',
                    style: TextStyle(
                      color: Colors.transparent,
                      fontSize: fFontsize,
                    ),
                  ),
            DefaultTextStyle.merge(
              child: Text(baseWord),
              style: TextStyle(
                fontSize: kanjiFontsize,
              ).merge(japaneseFont.value.textStyle),
            ),
            if (romajiEnabled.value && showRomajiBelow)
              Text(transliterateKanaToLatin(furigana ?? baseWord)),
          ],
        ),
        style: TextStyle(color: colors.foregroundColor),
      ),
    );
  }
}
