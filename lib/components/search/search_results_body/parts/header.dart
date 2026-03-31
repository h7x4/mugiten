import 'package:flutter/material.dart';
import 'package:jadb/util/romaji_transliteration.dart';

import 'package:mugiten/settings.dart';

class JapaneseHeader extends StatelessWidget {
  final String baseWord;
  final String? furigana;

  const JapaneseHeader({
    required this.baseWord,
    required this.furigana,
    super.key,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 10.0),
      child: Column(
        children: [
          (furigana != null)
              ? Text(
                  romajiEnabled.value
                      ? transliterateKanaToLatin(furigana!)
                      : furigana!,
                  style: japaneseFont.value.textStyle,
                )
              : const Text(''),
          Text(baseWord, style: japaneseFont.value.textStyle),
        ],
      ),
    );
  }
}
