import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/search.dart';
import 'package:kanimaji/kanimaji.dart';
import 'package:kanimaji/primitives/point.dart';
import 'package:kanimaji/svg_parser.dart';
import 'package:mugiten/theme.dart';
import 'package:sqflite/sqlite_api.dart';

class StrokeOrderGif extends StatelessWidget {
  final String kanji;

  const StrokeOrderGif({required this.kanji, super.key});

  @override
  Widget build(final BuildContext context) {
    final kanjiResultColors = Theme.of(
      context,
    ).extension<KanjiResultThemeExtension>()!;
    final menuGreyLightColors = Theme.of(
      context,
    ).extension<MenuGreyLightThemeExtension>()!;

    return Container(
      height: MediaQuery.of(context).size.width * 0.40,
      width: MediaQuery.of(context).size.width * 0.40,
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: menuGreyLightColors.backgroundColor,
        borderRadius: BorderRadius.circular(15.0),
        border: BoxBorder.all(
          color: kanjiResultColors.backgroundColor!,
          width: 4.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Kanimaji(
          kanji: kanji,
          kanjiDataProvider: (final kanji_) async {
            final result = await GetIt.instance
                .get<Database>()
                .jadbSearchKanjiVGGraph(kanji_);

            // TODO: fix data provider function type to return nullable results
            if (result == null) {
              throw Exception('KanjiVG graph not found for $kanji_');
            }

            return KanjiVGItem(kanji_, [
              for (final p in result.paths)
                KanjiVGPath(
                  strokeNumber: p.pathId,
                  type: p.type ?? '',
                  svgPath: parsePath(p.svgPath),
                  strokeNumberLabelPosition: Point(p.labelX, p.labelY),
                ),
            ]);
          },
          strokeColor: Theme.of(context).colorScheme.onSurface,
          strokeUnfilledColor: menuGreyLightColors.foregroundColor!.withAlpha(
            0x40,
          ),
        ),
      ),
    );
  }
}
