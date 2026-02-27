import 'package:flutter/material.dart';
import 'package:jadb/models/word_search/word_search_match_span.dart';
import 'package:jadb/models/word_search/word_search_ruby.dart';
import 'package:mugiten/components/search/search_results_body/parts/kanji_kana_box.dart';
import 'package:mugiten/theme.dart';

class OtherForms extends StatelessWidget {
  final List<WordSearchRuby> forms;
  final List<WordSearchMatchSpan>? matchSpans;

  const OtherForms({super.key, required this.forms, this.matchSpans});

  @override
  Widget build(final BuildContext context) {
    final colors = Theme.of(context).extension<MenuGreyLightThemeExtension>()!;
    final matchSpansAsMap = matchSpans != null
        ? {
            for (var i = matchSpans!.length - 1; i >= 0; i--)
              (matchSpans![i].spanType, matchSpans![i].index): (
                matchSpans![i].start,
                matchSpans![i].end,
              ),
          }
        : <(WordSearchMatchSpanType, int), (int, int)>{};

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
                  for (final (i, form) in forms.indexed)
                    KanjiKanaBox(
                      baseWord: form.base,
                      furigana: form.furigana,
                      colors: colors,
                      colorSpanBase:
                          matchSpansAsMap[(
                            WordSearchMatchSpanType.kanji,
                            i + 1,
                          )],
                      colorSpanFurigana:
                          matchSpansAsMap[(
                            WordSearchMatchSpanType.kana,
                            i + 1,
                          )],
                    ),
                ],
              ),
            ]
          : [],
    );
  }
}
