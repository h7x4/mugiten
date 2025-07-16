import 'package:flutter/material.dart';
import 'package:jadb/util/romaji_transliteration.dart';

import '../../../../settings.dart';

class JapaneseHeader extends StatelessWidget {
  final String baseWord;
  final String? furigana;

  const JapaneseHeader({
    required this.baseWord,
    required this.furigana,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 10.0),
      child: Column(
        children: [
          (furigana != null)
              ? Text(
                  romajiEnabled
                      ? transliterateKanaToLatin(furigana!)
                      : furigana!,
                  style: japaneseFont.textStyle,
                )
              : const Text(''),
          Text(baseWord, style: japaneseFont.textStyle),
        ],
      ),
    );
  }
}
