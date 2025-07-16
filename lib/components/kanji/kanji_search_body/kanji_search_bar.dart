import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../settings.dart';

class KanjiSearchBar extends StatefulWidget {
  final Function(String)? onChanged;

  const KanjiSearchBar({this.onChanged, super.key});

  @override
  KanjiSearchBarState createState() => KanjiSearchBarState();
}

enum TextFieldButton { clear, paste }

class KanjiSearchBarState extends State<KanjiSearchBar> {
  final TextEditingController textController = TextEditingController();
  TextFieldButton button = TextFieldButton.paste;

  @override
  void initState() {
    super.initState();
  }

  void onChanged() => widget.onChanged?.call(textController.text);

  void clearText() {
    textController.text = '';
    onChanged();
  }

  Future<void> pasteText() async {
    final ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      textController.text = clipboardData.text!;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final IconButton clearButton = IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => clearText(),
    );

    final IconButton pasteButton = IconButton(
      icon: const Icon(Icons.content_paste),
      onPressed: () => pasteText(),
    );

    return TextField(
      controller: textController,
      onChanged: (text) => onChanged(),
      onSubmitted: (_) => {},
      style: japaneseFont.textStyle,
      decoration: InputDecoration(
        hintText: 'Search',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        isDense: false,
        suffixIcon: (button == TextFieldButton.clear)
            ? clearButton
            : pasteButton,
      ),
    );
  }
}
