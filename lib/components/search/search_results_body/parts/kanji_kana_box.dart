import 'package:flutter/material.dart';
import 'package:jadb/util/romaji_transliteration.dart';
import 'package:mugiten/settings.dart';
import 'package:mugiten/theme.dart';

class KanjiKanaBox extends StatelessWidget {
  final String baseWord;
  final String? furigana;
  final (int, int)? colorSpanBase;
  final (int, int)? colorSpanFurigana;
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
    this.colorSpanBase,
    this.colorSpanFurigana,
    this.showRomajiBelow = false,
    this.autoTransliterateRomaji = true,
    this.centerFurigana = true,
    this.furiganaFontsize,
    this.kanjiFontsize,
    this.margin = const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
    this.padding = const EdgeInsets.all(5.0),
  });

  @override
  Widget build(final BuildContext context) {
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
                ? Text.rich(
                    TextSpan(
                      children:
                          colorSpanFurigana != null && !romajiEnabled.value && emphasizeMatchSpans.value
                          ? [
                              TextSpan(
                                text: furigana!.substring(
                                  0,
                                  colorSpanFurigana!.$1,
                                ),
                                style: TextStyle(
                                  fontSize: fFontsize,
                                  color: colors.foregroundColor,
                                ).merge(japaneseFont.value.textStyle),
                              ),
                              TextSpan(
                                text: furigana!.substring(
                                  colorSpanFurigana!.$1,
                                  colorSpanFurigana!.$2,
                                ),
                                style: TextStyle(
                                  fontSize: fFontsize,
                                  decoration: TextDecoration.underline,
                                ).merge(japaneseFont.value.textStyle),
                              ),
                              TextSpan(
                                text: furigana!.substring(
                                  colorSpanFurigana!.$2,
                                ),
                                style: TextStyle(
                                  fontSize: fFontsize,
                                  color: colors.foregroundColor,
                                ).merge(japaneseFont.value.textStyle),
                              ),
                            ]
                          : [
                              TextSpan(
                                text:
                                    autoTransliterateRomaji &&
                                        romajiEnabled.value
                                    ? transliterateKanaToLatin(furigana!)
                                    : furigana!,
                                style:
                                    TextStyle(
                                      fontSize: fFontsize,
                                      color: colors.foregroundColor,
                                    ).merge(
                                      autoTransliterateRomaji &&
                                              romajiEnabled.value
                                          ? null
                                          : japaneseFont.value.textStyle,
                                    ),
                              ),
                            ],
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
              child: Text.rich(
                TextSpan(
                  children: colorSpanBase != null && emphasizeMatchSpans.value
                      ? [
                          TextSpan(
                            text: baseWord.substring(0, colorSpanBase!.$1),
                          ),
                          TextSpan(
                            text: baseWord.substring(
                              colorSpanBase!.$1,
                              colorSpanBase!.$2,
                            ),
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ).merge(japaneseFont.value.textStyle),
                          ),
                          TextSpan(text: baseWord.substring(colorSpanBase!.$2)),
                        ]
                      : [TextSpan(text: baseWord)],
                ),
              ),
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
