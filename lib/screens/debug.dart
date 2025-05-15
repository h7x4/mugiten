import 'package:flutter/material.dart';

import '../components/drawing_board/drawing_board.dart';

class DebugView extends StatelessWidget {
  const DebugView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DrawingBoard(
          allowHiragana: true,
          allowKatakana: true,
          allowOther: true,
          onSuggestionChosen: (s) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chose: $s'),
              duration: const Duration(milliseconds: 600),
            ),
          ),
        ),
      ],
    );
  }
}
