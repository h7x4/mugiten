import 'package:flutter/material.dart';
import 'package:jadb/util/romaji_transliteration.dart';
// import 'package:jadic/services/kanji_regex.dart';
// import 'package:unofficial_jisho_api/api.dart';

import '../../../../models/themes/theme.dart';
import '../../../../settings.dart';

class KanjiKanaBox extends StatelessWidget {
  final String baseWord;
  final String? furigana;
  // final JishoJapaneseWord word;
  final bool showRomajiBelow;
  final ColorSet colors;
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
    this.showRomajiBelow = false,
    this.colors = LightTheme.defaultMenuGreyNormal,
    this.autoTransliterateRomaji = true,
    this.centerFurigana = true,
    this.furiganaFontsize,
    this.kanjiFontsize,
    this.margin = const EdgeInsets.symmetric(
      horizontal: 5.0,
      vertical: 5.0,
    ),
    this.padding = const EdgeInsets.all(5.0),
  });

  @override
  Widget build(BuildContext context) {
    final fFontsize = furiganaFontsize ??
        ((kanjiFontsize != null) ? 0.8 * kanjiFontsize! : null);

    return Container(
      margin: margin,
      padding: padding,
      color: colors.background,
      child: DefaultTextStyle.merge(
        child: Column(
          crossAxisAlignment: centerFurigana
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            (furigana != null)
                ? Text(
                    romajiEnabled
                        ? transliterateKanaToLatin(furigana!)
                        : furigana!,
                    style: TextStyle(
                      fontSize: fFontsize,
                      color: colors.foreground,
                    ).merge(
                      romajiEnabled && autoTransliterateRomaji
                          ? null
                          : japaneseFont.textStyle,
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
              style: TextStyle(fontSize: kanjiFontsize)
                  .merge(japaneseFont.textStyle),
            ),
            if (romajiEnabled && showRomajiBelow)
              Text(
                transliterateKanaToLatin(furigana ?? baseWord),
              )
          ],
        ),
        style: TextStyle(color: colors.foreground),
      ),
    );
  }
}
