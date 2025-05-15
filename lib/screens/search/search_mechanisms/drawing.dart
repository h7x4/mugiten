import 'package:flutter/material.dart';

import '../../../components/drawing_board/drawing_board.dart';
import '../../../routing/routes.dart';

class KanjiDrawingSearch extends StatelessWidget {
  const KanjiDrawingSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw a kanji')),
      body: Column(
        children: [
          const Expanded(child: Column()),
          DrawingBoard(
            onlyOneCharacterSuggestions: true,
            onSuggestionChosen: (suggestion) => Navigator.popAndPushNamed(
              context,
              Routes.kanjiSearch,
              arguments: suggestion,
            ),
          ),
        ],
      ),
    );
  }
}
