import 'package:flutter/material.dart';

import '../../../../bloc/theme/theme_bloc.dart';
import '../../../../routing/routes.dart';
import '../../../../settings.dart';

class KanjiRow extends StatelessWidget {
  final List<String> kanji;
  final double fontSize;
  const KanjiRow({
    super.key,
    required this.kanji,
    this.fontSize = 20,
  });

  Widget _kanjiBox(String kanji) => UnconstrainedBox(
        child: IntrinsicHeight(
          child: AspectRatio(
            aspectRatio: 1,
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                final colors = state.theme.menuGreyLight;
                return Container(
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                    child: Text(
                      kanji,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: fontSize,
                      ).merge(japaneseFont.textStyle),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kanji:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final k in kanji)
              InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.kanjiSearch,
                  arguments: k,
                ),
                child: _kanjiBox(k),
              )
          ],
        ),
      ],
    );
  }
}
