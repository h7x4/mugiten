import 'package:flutter/material.dart';
import 'package:mugiten/components/drawing_board/drawing_board.dart';

import '../../models/themes/theme.dart';
import '../../routing/routes.dart';
import '../../settings.dart';
import 'language_selector.dart';

class GlobalSearchBar extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  GlobalSearchBar({super.key});

  void _search(BuildContext context, String text) => Navigator.pushNamed(
        context,
        Routes.search,
        arguments: text,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          TextField(
            onSubmitted: (text) => _search(context, text),
            controller: controller,
            style: japaneseFont.textStyle,
            decoration: InputDecoration(
              labelText: 'Search',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIconConstraints: const BoxConstraints.tightFor(height: 60),
              suffixIcon: Material(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
                color: AppTheme.mugitenWheat.background,
                child: IconButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      _search(context, controller.text);
                    }
                  },
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LanguageSelector(),
              IconButton(
                icon: const Icon(Icons.mode),
                onPressed: () async {
                  final result = await _drawKanji()(context);
                  if (result != null && result.isNotEmpty) {
                    final pos = controller.selection.baseOffset;
                    controller.text = controller.text.substring(0, pos) +
                        result +
                        controller.text.substring(pos);
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(
                        offset: pos + result.length,
                      ),
                    );
                  }
                },
              )
            ],
          )
        ],
      ),
    );
  }

  Future<String?> Function(BuildContext) _drawKanji() {
    final MaterialPageRoute<String> route = MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Draw a kanji')),
        body: Column(
          children: [
            const Expanded(child: Column()),
            DrawingBoard(
              onlyOneCharacterSuggestions: true,
              onSuggestionChosen: (suggestion) => Navigator.pop(
                context,
                suggestion,
              ),
            ),
          ],
        ),
      ),
    );

    return (context) => Navigator.push<String>(context, route);
  }
}
