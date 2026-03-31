import 'package:flutter/material.dart';
import 'package:mugiten/components/drawing_board/drawing_board.dart';
import 'package:mugiten/components/search/language_selector.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/settings.dart';
import 'package:mugiten/theme.dart';

class GlobalSearchBar extends StatelessWidget {
  final TextEditingController textController = TextEditingController();
  final FocusNode textFocus = FocusNode();

  GlobalSearchBar({super.key});

  void _search(final BuildContext context, final String text) =>
      Navigator.pushNamed(context, Routes.search, arguments: text);

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          TextField(
            onSubmitted: (final text) => _search(context, text),
            controller: textController,
            focusNode: textFocus,
            style: japaneseFont.value.textStyle,
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
                color: mugitenWheatBackground,
                child: IconButton(
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isNotEmpty) {
                      _search(context, text);
                    }
                  },
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                color: Colors.red,
                onPressed: textController.clear,
              ),
              const LanguageSelector(),
              IconButton(
                icon: const Icon(Icons.mode),
                onPressed: () async {
                  final precedingText = textController.selection.isValid
                      ? textController.text.substring(
                          textController.selection.baseOffset,
                        )
                      : null;

                  final result = await _drawKanji(precedingText)(context);

                  if (result != null && result.isNotEmpty) {
                    if (textController.selection.isValid) {
                      final pos = textController.selection.baseOffset;
                      textController.text =
                          textController.text.substring(0, pos) +
                          result +
                          textController.text.substring(pos);
                      textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: pos + result.length),
                      );
                    } else {
                      textController.text += result;
                      textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: textController.text.length),
                      );
                      textFocus.requestFocus();
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> Function(BuildContext) _drawKanji(
    final String? precedingText,
  ) {
    final MaterialPageRoute<String> route = MaterialPageRoute(
      builder: (final context) => Scaffold(
        appBar: AppBar(title: const Text('Draw a kanji')),
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(child: Column()),
              DrawingBoard(
                precedingText: precedingText,
                onlyOneCharacterSuggestions: true,
                onSuggestionChosen: (final suggestion) =>
                    Navigator.pop(context, suggestion),
              ),
            ],
          ),
        ),
      ),
    );

    return (final context) => Navigator.push<String>(context, route);
  }
}
