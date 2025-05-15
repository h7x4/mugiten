import 'package:flutter/material.dart';
import 'package:jadb/models/word_search/word_search_sense.dart';
// import 'package:unofficial_jisho_api/api.dart';

import '../../../../../bloc/theme/theme_bloc.dart';
import 'antonyms.dart';
import 'english_definitions.dart';

class Sense extends StatelessWidget {
  final int index;
  final WordSearchSense sense;

  const Sense({
    super.key,
    required this.index,
    required this.sense,
    // this.meaning,
  });

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) => Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: state.theme.menuGreyLight.background,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${index + 1}. ${sense.partsOfSpeech.join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
              EnglishDefinitions(
                englishDefinitions: sense.englishDefinitions,
                colors: state.theme.menuGreyNormal,
              ),
              if (sense.antonyms.isNotEmpty) Antonyms(antonyms: sense.antonyms),
            ]
                .map(
                  (e) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: e,
                  ),
                )
                .toList(),
          ),
        ),
      );
}
