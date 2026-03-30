import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/const_data/radicals.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/theme.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../routing/routes.dart';
import '../../../settings.dart';

class KanjiRadicalSearch extends StatefulWidget {
  final String? prechosenRadical;

  const KanjiRadicalSearch({super.key, this.prechosenRadical});

  @override
  State<KanjiRadicalSearch> createState() => _KanjiRadicalSearchState();
}

class _KanjiRadicalSearchState extends State<KanjiRadicalSearch> {
  static const double fontSize = 25;

  List<String> suggestions = [];

  Map<String, bool> radicalToggles = {
    for (final String r in radicals.values.expand((l) => l)) r: false,
  };

  Map<String, bool> allowedToggles = {
    for (final String r in radicals.values.expand((l) => l)) r: true,
  };

  @override
  void initState() {
    if (widget.prechosenRadical != null &&
        radicalToggles.containsKey(widget.prechosenRadical)) {
      radicalToggles[widget.prechosenRadical!] = true;
    }
    updateSuggestions();
    super.initState();
  }

  void resetRadicalToggles() => radicalToggles.forEach((k, _) {
    radicalToggles[k] = false;
  });

  void resetAllowedToggles() => allowedToggles.forEach((k, _) {
    allowedToggles[k] = true;
  });

  Future<void> updateSuggestions() async {
    final toggledRadicals = radicalToggles.keys
        .where((r) => radicalToggles[r] ?? false)
        .toList();

    if (toggledRadicals.isEmpty) {
      suggestions.clear();
      resetAllowedToggles();
      return;
    }

    final jadbConnection = GetIt.instance.get<Database>();
    late final List<String> newSuggestions;
    late final List<String> newRadicals;
    await Future.wait([
      jadbConnection.jadbSearchKanjiByRadicals(toggledRadicals).then((value) {
        newSuggestions = value;
      }),
      jadbConnection.jadbSearchRemainingRadicals(toggledRadicals).then((value) {
        newRadicals = value;
      }),
    ]);

    setState(() {
      allowedToggles.forEach((key, value) {
        allowedToggles[key] = false;
      });
      for (final r in newRadicals) {
        allowedToggles[r] = true;
      }
      suggestions = newSuggestions;
    });
  }

  Widget radicalGridElement(String radical, {bool isNumber = false}) {
    final foregroundColor = isNumber
        ? lightTheme.extension<MenuGreyDarkThemeExtension>()!.foregroundColor
        : radicalToggles[radical]!
        ? mugitenWheatForeground
        : lightTheme.extension<MenuGreyNormalThemeExtension>()!.foregroundColor;
    final backgroundColor = isNumber
        ? lightTheme.extension<MenuGreyDarkThemeExtension>()!.backgroundColor
        : radicalToggles[radical]!
        ? mugitenWheatBackground
        : lightTheme.extension<MenuGreyNormalThemeExtension>()!.backgroundColor;

    return InkWell(
      onTap: isNumber
          ? () {}
          : () => setState(() {
              // TODO: Don't let the user toggle on another kanji before the last one is updated
              radicalToggles[radical] = !radicalToggles[radical]!;
              updateSuggestions();
            }),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: backgroundColor,
        ),
        child: Text(
          radical,
          style: TextStyle(color: foregroundColor, fontSize: fontSize),
        ),
      ),
    );
  }

  List<Widget> get radicalGridElements => <Widget>[
    IconButton(
      onPressed: () => setState(() {
        suggestions.clear();
        resetRadicalToggles();
        resetAllowedToggles();
      }),
      icon: const Icon(Icons.restore),
      color: mugitenWheatBackground,
      iconSize: fontSize * 1.3,
    ),
    ...radicals.values
        .expand((l) => l)
        .where((k) => radicalToggles[k] ?? false)
        .map((k) => radicalGridElement(k.toString())),

    ...radicals
        .map(
          (key, value) => MapEntry(
            key,
            value
                .where((r) => !radicalToggles[r]! && allowedToggles[r]!)
                .map((r) => radicalGridElement(r))
                .toList()
              ..insert(0, radicalGridElement(key.toString(), isNumber: true)),
          ),
        )
        .values
        .where((element) => element.length != 1)
        .expand((l) => l),
  ];

  Widget kanjiGridElement(String kanji) {
    // const color = LightTheme.defaultMenuGreyNormal;
    final colors = lightTheme.extension<MenuGreyNormalThemeExtension>()!;
    return InkWell(
      onTap: () => Navigator.popAndPushNamed(
        context,
        Routes.kanjiSearch,
        arguments: kanji,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: colors.backgroundColor,
        ),
        alignment: Alignment.center,
        child: Text(
          kanji,
          style: TextStyle(color: colors.foregroundColor, fontSize: fontSize),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MenuGreyNormalThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose by radicals')),
      body: DefaultTextStyle.merge(
        style: japaneseFont.value.textStyle,
        child: Column(
          children: [
            Expanded(
              child: (suggestions.isEmpty)
                  ? Center(
                      child: Text(
                        'Toggle a radical to start',
                        style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: colors.backgroundColor,
                        ),
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      padding: const EdgeInsets.all(10),
                      children: suggestions
                          .map((s) => kanjiGridElement(s))
                          .toList(),
                    ),
            ),
            Divider(
              color: mugitenWheatBackground,
              thickness: 3,
              height: 30,
              indent: 5,
              endIndent: 5,
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                padding: const EdgeInsets.all(10),
                children: radicalGridElements,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
