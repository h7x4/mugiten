import 'package:flutter/material.dart';
import 'package:jadb/models/word_search/word_search_xref_entry.dart';

import '../../../../../models/themes/theme.dart';
import '../../../../../routing/routes.dart';
import '../../../../../settings.dart';
import 'search_chip.dart';

class Antonyms extends StatelessWidget {
  final List<WordSearchXrefEntry> antonyms;
  final ColorSet colors;

  const Antonyms({
    super.key,
    required this.antonyms,
    this.colors = const ColorSet(
      foreground: Colors.white,
      background: Colors.blue,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Antonyms:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final antonym in antonyms)
              InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.search,
                  arguments: antonym,
                ),
                child: SearchChip(
                  text: antonym.baseWord,
                  colors: colors,
                  extraTextStyle: japaneseFont.textStyle,
                ),
              ),
          ],
        )
      ],
    );
  }
}
