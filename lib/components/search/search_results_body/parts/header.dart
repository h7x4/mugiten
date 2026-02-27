import 'package:flutter/material.dart';
import 'package:jadb/util/romaji_transliteration.dart';

import 'package:mugiten/settings.dart';

class JapaneseHeader extends StatelessWidget {
  final String baseWord;
  final String? furigana;
  final bool dimBase;
  final (int, int)? colorSpanBase;
  final (int, int)? colorSpanFurigana;

  const JapaneseHeader({
    super.key,
    required this.baseWord,
    required this.furigana,
    this.dimBase = false,
    this.colorSpanBase,
    this.colorSpanFurigana,
  });

  @override
  Widget build(final BuildContext context) {
    final maybeDimmedTextStyle = japaneseFont.value.textStyle.copyWith(
      color:
          (japaneseFont.value.textStyle.color ??
                  Theme.of(context).textTheme.bodyMedium?.color)
              ?.withAlpha(dimBase ? 0xA0 : 0xFF),
    );

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 10.0),
      child: Column(
        children: [
          (furigana != null)
              ? Text.rich(
                  TextSpan(
                    children:
                        colorSpanFurigana != null &&
                            !romajiEnabled.value &&
                            emphasizeMatchSpans.value
                        ? [
                            TextSpan(
                              text: furigana!.substring(
                                0,
                                colorSpanFurigana!.$1,
                              ),
                              style: japaneseFont.value.textStyle,
                            ),
                            TextSpan(
                              text: furigana!.substring(
                                colorSpanFurigana!.$1,
                                colorSpanFurigana!.$2,
                              ),
                              style: japaneseFont.value.textStyle.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(
                              text: furigana!.substring(colorSpanFurigana!.$2),
                              style: japaneseFont.value.textStyle,
                            ),
                          ]
                        : [
                            TextSpan(
                              text: romajiEnabled.value
                                  ? transliterateKanaToLatin(furigana!)
                                  : furigana!,
                              style: japaneseFont.value.textStyle,
                            ),
                          ],
                  ),
                )
              : const SizedBox.shrink(),
          Text.rich(
            TextSpan(
              children: colorSpanBase != null && emphasizeMatchSpans.value
                  ? [
                      TextSpan(
                        text: baseWord.substring(0, colorSpanBase!.$1),
                        style: maybeDimmedTextStyle,
                      ),
                      TextSpan(
                        text: baseWord.substring(
                          colorSpanBase!.$1,
                          colorSpanBase!.$2,
                        ),
                        style: maybeDimmedTextStyle.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text: baseWord.substring(colorSpanBase!.$2),
                        style: maybeDimmedTextStyle,
                      ),
                    ]
                  : [TextSpan(text: baseWord, style: maybeDimmedTextStyle)],
            ),
          ),
        ],
      ),
    );
  }
}
