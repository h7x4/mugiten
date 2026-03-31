import 'package:flutter/material.dart';

import 'package:mugiten/components/drawing_board/drawing_board.dart';
import 'package:mugiten/routing/routes.dart';

class KanjiDrawingSearch extends StatelessWidget {
  const KanjiDrawingSearch({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw a kanji')),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: Column()),
            DrawingBoard(
              onlyOneCharacterSuggestions: true,
              onSuggestionChosen: (final suggestion) =>
                  Navigator.popAndPushNamed(
                    context,
                    Routes.kanjiSearch,
                    arguments: suggestion,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
