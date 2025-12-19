import 'package:flutter/material.dart';
import 'package:jadb/models/word_search/word_search_ruby.dart';
import 'package:mugiten/theme.dart';

import 'kanji_kana_box.dart';

class OtherForms extends StatelessWidget {
  final List<WordSearchRuby> forms;

  const OtherForms({required this.forms, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MenuGreyLightThemeExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: forms.isNotEmpty
          ? [
              const Text(
                'Other Forms:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                children: [
                  for (final form in forms)
                    KanjiKanaBox(
                      baseWord: form.base,
                      furigana: form.furigana,
                      colors: colors,
                    ),
                ],
              ),
            ]
          : [],
    );
  }
}
