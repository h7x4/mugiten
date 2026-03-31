import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jadb/const_data/kanji_grades.dart';
import 'package:mugiten/components/common/loading.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/settings.dart';
import 'package:mugiten/theme.dart';

class KanjiGradeSearch extends StatefulWidget {
  const KanjiGradeSearch({super.key});

  @override
  State<KanjiGradeSearch> createState() => _KanjiGradeSearchState();
}

class _GridItem extends StatelessWidget {
  final bool isNumber;
  final String text;
  const _GridItem({required this.text, this.isNumber = false});

  @override
  Widget build(final BuildContext context) {
    final ForegroundBackgroundThemeExtension colors = isNumber
        ? lightTheme.extension<MenuGreyDarkThemeExtension>()!
        : lightTheme.extension<MenuGreyNormalThemeExtension>()!;

    final onTap = isNumber
        ? () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text)))
        : () => Navigator.popAndPushNamed(
            context,
            Routes.kanjiSearch,
            arguments: text,
          );

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: colors.backgroundColor,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: colors.foregroundColor,
            fontSize: 25,
          ).merge(japaneseFont.value.textStyle),
        ),
      ),
    );
  }
}

class _KanjiGradeSearchState extends State<KanjiGradeSearch> {
  Future<Map<int, Map<int, List<Widget>>>> get gradeWidgets =>
      compute<
        Map<int, Map<int, List<String>>>,
        Map<int, Map<int, List<Widget>>>
      >(
        (final gs) => gs.map(
          (final grade, final sortedByStrokes) => MapEntry(
            grade,
            sortedByStrokes.map<int, List<Widget>>(
              (final strokeCount, final kanji) => MapEntry(strokeCount, [
                _GridItem(text: strokeCount.toString(), isNumber: true),
                ...kanji.map((final k) => _GridItem(text: k)),
              ]),
            ),
          ),
        ),
        jouyouKanjiByGradeAndStrokeCount,
      );

  Future<Widget> get makeGrids async => SingleChildScrollView(
    child: Column(
      children: (await Future.wait(
        jouyouKanjiByGradeAndStrokeCount.keys.map(
          (final grade) async => ExpansionTile(
            title: Text(grade == 7 ? 'Junior Highschool' : 'Grade $grade'),
            maintainState: true,
            children: [
              GridView.count(
                crossAxisCount: 6,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                padding: const EdgeInsets.all(10),
                children: (await gradeWidgets)[grade]!.values
                    .expand((final l) => l)
                    .toList(),
              ),
            ],
          ),
        ),
      )).toList(),
    ),
  );

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose by grade')),
      body: FutureBuilder<Widget>(
        future: makeGrids,
        initialData: const LoadingScreen(),
        builder: (final context, final snapshot) => snapshot.data!,
      ),
    );
  }
}
