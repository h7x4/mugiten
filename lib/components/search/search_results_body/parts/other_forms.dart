import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadb/models/word_search/word_search_ruby.dart';

import '../../../../bloc/theme/theme_bloc.dart';
import 'kanji_kana_box.dart';

class OtherForms extends StatelessWidget {
  final List<WordSearchRuby> forms;

  const OtherForms({required this.forms, super.key});

  @override
  Widget build(BuildContext context) => Column(
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
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, state) {
                      return KanjiKanaBox(
                        baseWord: form.base,
                        furigana: form.furigana,
                        colors: state.theme.menuGreyLight,
                      );
                    },
                  ),
              ],
            ),
          ]
        : [],
  );
}
