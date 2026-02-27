import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jadb/const_data/kanji_grades.dart';
import 'package:mugiten/theme.dart';

import '../../../../routing/routes.dart';
import '../../../components/common/loading.dart';
import '../../../settings.dart';

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
  Widget build(BuildContext context) {
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
  Future<Map<int, Map<int, List<Widget>>>> get gradeWidgets async =>
      compute<
        Map<int, Map<int, List<String>>>,
        Map<int, Map<int, List<Widget>>>
      >(
        (gs) => gs.map(
          (grade, sortedByStrokes) => MapEntry(
            grade,
            sortedByStrokes.map<int, List<Widget>>(
              (strokeCount, kanji) => MapEntry(strokeCount, [
                _GridItem(text: strokeCount.toString(), isNumber: true),
                ...kanji.map((k) => _GridItem(text: k)),
              ]),
            ),
          ),
        ),
        JOUYOU_KANJI_BY_GRADE_AND_STROKE_COUNT,
      );

  Future<Widget> get makeGrids async => SingleChildScrollView(
    child: Column(
      children: (await Future.wait(
        JOUYOU_KANJI_BY_GRADE_AND_STROKE_COUNT.keys.map(
          (grade) async => ExpansionTile(
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
                    .expand((l) => l)
                    .toList(),
              ),
            ],
          ),
        ),
      )).toList(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose by grade')),
      body: FutureBuilder<Widget>(
        future: makeGrids,
        initialData: const LoadingScreen(),
        builder: (context, snapshot) => snapshot.data!,
      ),
    );
  }
}
