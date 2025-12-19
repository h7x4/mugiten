import 'package:flutter/material.dart' hide Ink;
import 'package:get_it/get_it.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/theme.dart';
import 'package:signature/signature.dart';
import 'package:sqflite/sqflite.dart';

import '../../settings.dart';

class DrawingBoard extends StatefulWidget {
  final Function(String)? onSuggestionChosen;
  final String? precedingText;
  final bool onlyOneCharacterSuggestions;
  final bool allowKanji;
  final bool allowHiragana;
  final bool allowKatakana;
  final bool allowOther;

  const DrawingBoard({
    this.onSuggestionChosen,
    this.precedingText,
    this.onlyOneCharacterSuggestions = false,
    this.allowKanji = true,
    this.allowHiragana = false,
    this.allowKatakana = false,
    this.allowOther = false,
    super.key,
  });

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  List<String> suggestions = [];

  final List<List<StrokePoint>> strokes = [];
  final List<List<StrokePoint>> undoQueue = [];

  GlobalKey signatureW = GlobalKey();
  GlobalKey suggestionBarW = GlobalKey();

  static const double fontSize = 30;
  static const double suggestionCirclePadding = 13;

  late final panelColor = Theme.of(
    context,
  ).extension<MenuGreyLightThemeExtension>()!;
  late final barColor = Theme.of(
    context,
  ).extension<MenuGreyNormalThemeExtension>()!;

  late final SignatureController controller = SignatureController(
    penColor: panelColor.foregroundColor!,
    onDrawStart: () {
      strokes.add([]);
      undoQueue.clear();
    },
    onDrawMove: () => strokes.last.add(
      StrokePoint(
        t: DateTime.now().millisecondsSinceEpoch,
        x: controller.points.last.offset.dx,
        y: controller.points.last.offset.dy,
      ),
    ),
    onDrawEnd: () => updateSuggestions(),
  );

  Future<void> updateSuggestions() async {
    if (strokes.isEmpty) return setState(() => suggestions.clear());

    final digitalInkRecognizer = DigitalInkRecognizer(languageCode: 'ja');
    final context = DigitalInkRecognitionContext(
      preContext: widget.precedingText,
      writingArea: WritingArea(
        height: signatureW.currentContext!.size!.height,
        width: signatureW.currentContext!.size!.width,
      ),
    );

    final ink = Ink()
      ..strokes = strokes.map((s) => Stroke()..points = s).toList();

    final newSuggestions = await digitalInkRecognizer.recognize(
      ink,
      context: context,
    );

    setState(() {
      suggestions = newSuggestions.map((rc) => rc.text).toList();
    });
  }

  Future<List<String>> filterSuggestions() async {
    const hiraganaR = r'\p{Script=Hiragana}';
    const katakanaR = r'\p{Script=Katakana}';

    final kanjiSuggestions = await GetIt.instance.get<Database>().filterKanji(
      suggestions,
      deduplicate: true,
    );
    final hiraganaSuggestions = suggestions
        .where((s) => RegExp(hiraganaR).hasMatch(s))
        .toSet()
        .toList();
    final katakanaSuggestions = suggestions
        .where((s) => RegExp(katakanaR).hasMatch(s))
        .toSet()
        .toList();

    return {
          if (widget.allowKanji) ...kanjiSuggestions,
          if (widget.allowHiragana) ...hiraganaSuggestions,
          if (widget.allowKatakana) ...katakanaSuggestions,
        }
        .where((s) => !widget.onlyOneCharacterSuggestions || s.length == 1)
        .toList();
  }

  Widget kanjiChip(String kanji) => InkWell(
    onTap: () => widget.onSuggestionChosen?.call(kanji),
    child: Container(
      height: fontSize + 2 * suggestionCirclePadding,
      width: fontSize + 2 * suggestionCirclePadding,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: panelColor.backgroundColor,
      ),
      child: Center(
        child: Text(
          kanji,
          style: TextStyle(
            fontSize: fontSize,
            color: panelColor.foregroundColor,
          ).merge(japaneseFont.textStyle),
        ),
      ),
    ),
  );

  Widget suggestionBar() {
    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);

    return FutureBuilder<List<String>>(
      future: filterSuggestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            (!snapshot.hasError && (snapshot.data?.isEmpty ?? false))) {
          return Container(
            key: suggestionBarW,
            color: barColor.backgroundColor,
            alignment: Alignment.center,
            padding: padding,
            child: const Text('No suggestions'),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final filteredSuggestions = snapshot.data!;

        return Container(
          key: suggestionBarW,
          color: barColor.backgroundColor,
          alignment: Alignment.center,
          padding: padding,

          // TODO: calculate dynamically
          constraints: BoxConstraints(
            minHeight:
                8 +
                suggestionCirclePadding * 2 +
                fontSize +
                (2 * 4) +
                padding.vertical,
          ),

          child: Wrap(
            spacing: 20,
            runSpacing: 5,
            children: filteredSuggestions.map((s) => kanjiChip(s)).toList(),
          ),
        );
      },
    );
  }

  Widget buttonRow() => Container(
    color: panelColor.backgroundColor,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => setState(() {
            controller.clear();
            strokes.clear();
            suggestions.clear();
          }),
          icon: const Icon(Icons.delete),
        ),
        IconButton(
          onPressed: () {
            if (strokes.isNotEmpty) {
              undoQueue.add(strokes.removeLast());
              controller.undo();
              updateSuggestions();
            }
          },
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          onPressed: () {
            if (undoQueue.isNotEmpty) {
              strokes.add(undoQueue.removeLast());
              controller.redo();
              updateSuggestions();
            }
          },
          icon: const Icon(Icons.redo),
        ),
        if (!widget.onlyOneCharacterSuggestions)
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('TODO: implement scrolling page feature!'),
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
          ),
      ],
    ),
  );

  Widget drawingPanel() {
    final board = AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ClipRect(
            child: Signature(
              key: signatureW,
              controller: controller,
              backgroundColor: panelColor.backgroundColor!,
            ),
          ),
          buttonRow(),
        ],
      ),
    );

    if (reduceKanjiDrawingBoardSize) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(50, 0, 50, 30),
        child: board,
      );
    }
    return board;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [suggestionBar(), drawingPanel()]);
  }
}
