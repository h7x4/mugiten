import 'package:flutter/material.dart';
import 'package:jadb/models/word_search/word_search_sense.dart';
import 'package:mugiten/components/search/search_results_body/search_card.dart';
import 'package:mugiten/theme.dart';
import 'package:sealed_languages/sealed_languages.dart';

import 'english_definitions.dart';

final Map<String, String> languageNameMap = {
  ...{
    for (final lang in NaturalLanguage.list) lang.code: lang.name,
    for (final lang in NaturalLanguage.list)
      if (lang.bibliographicCode != null) lang.bibliographicCode!: lang.name,
  },
};

class Sense extends StatelessWidget {
  final int index;
  final WordSearchSense sense;

  const Sense({super.key, required this.index, required this.sense});

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  List<String> _notes() {
    return [
      ...sense.restrictedToReading.map((e) => 'Restricted to $e'),
      ...sense.restrictedToKanji.map((e) => 'Restricted to $e'),
      ...sense.fields.map((e) => 'Field: ${_capitalize(e.description)}'),
      ...sense.misc.map((e) => e.description),
      ...sense.languageSource.map((e) {
        final languageName =
            languageNameMap[e.language.toUpperCase()] ?? e.language;

        if (e.phrase != null) {
          return 'From $languageName, "${e.phrase}"';
        } else {
          return 'From $languageName';
        }
      }),
      ...sense.dialects.map((e) => '${_capitalize(e.description)} dialect'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lightColors = Theme.of(
      context,
    ).extension<MenuGreyLightThemeExtension>()!;
    final normalColors = Theme.of(
      context,
    ).extension<MenuGreyNormalThemeExtension>()!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lightColors.backgroundColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            <Widget>[
                  Text(
                    '${index + 1}. ${sense.partsOfSpeech.map((pos) => _capitalize(pos.shortDescription)).join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                  EnglishDefinitions(
                    englishDefinitions: sense.englishDefinitions,
                    colors: normalColors,
                  ),
                  if (_notes().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      child: Text(
                        _notes().join('\n'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (sense.antonyms.isNotEmpty &&
                      sense.antonyms.first.xrefResult != null)
                    Text(
                      'Antonyms:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ...sense.antonyms
                      .where((antonym) => antonym.xrefResult != null)
                      .map(
                        (antonym) => SearchResultCard(
                          result: antonym.xrefResult!,
                          backgroundColor: Colors.black38,
                          leading: antonym.ambiguous
                              ? const Icon(Icons.question_mark)
                              : null,
                        ),
                      ),
                  if (sense.seeAlso.isNotEmpty &&
                      sense.seeAlso.first.xrefResult != null)
                    Text(
                      'See also:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ...sense.seeAlso
                      .where((seeAlso) => seeAlso.xrefResult != null)
                      .map(
                        (seeAlso) => SearchResultCard(
                          result: seeAlso.xrefResult!,
                          backgroundColor: Colors.black38,
                          leading: seeAlso.ambiguous
                              ? const Icon(Icons.question_mark)
                              : null,
                        ),
                      ),
                ]
                .map(
                  (e) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: e,
                  ),
                )
                .toList(),
      ),
    );
  }
}
