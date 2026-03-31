import 'package:flutter/material.dart';
import 'package:jadb/models/word_search/word_search_sense.dart';

import 'package:mugiten/components/search/search_results_body/parts/sense/sense.dart';

class Senses extends StatelessWidget {
  final List<WordSearchSense> senses;

  const Senses({required this.senses, super.key});

  List<Widget> get _senseWidgets => [
    for (int i = 0; i < senses.length; i++) Sense(index: i, sense: senses[i]),
  ];

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: _senseWidgets,
  );
}
