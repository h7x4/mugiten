import 'package:flutter/material.dart';
import 'package:mugiten/models/library/library_list.dart';
import 'package:mugiten/screens/info/changelog.dart';
import 'package:mugiten/screens/library/library_content_view.dart';
import 'package:mugiten/screens/search/kanji_search_result_page.dart';
import 'package:mugiten/screens/search/word_search_result_page.dart';

import '../screens/home.dart';
import '../screens/info/licenses.dart';
import '../screens/search/search_mechanisms/drawing.dart';
import '../screens/search/search_mechanisms/grade_list.dart';
import '../screens/search/search_mechanisms/radical_list.dart';
import 'routes.dart';

Route<Widget> generateRoute(RouteSettings settings) {
  final args = settings.arguments;

  switch (settings.name) {
    case Routes.root:
      return MaterialPageRoute(builder: (_) => const Home());

    case Routes.search:
      final searchTerm = args! as String;
      return MaterialPageRoute(
        builder: (_) => WordSearchResultPage(searchTerm: searchTerm),
      );

    case Routes.kanjiSearch:
      final searchTerm = args! as String;
      return MaterialPageRoute(
        builder: (_) => KanjiSearchResultPage(
          kanji: searchTerm,
        ),
      );

    case Routes.kanjiSearchDraw:
      return MaterialPageRoute(builder: (_) => const KanjiDrawingSearch());

    case Routes.kanjiSearchGrade:
      return MaterialPageRoute(builder: (_) => const KanjiGradeSearch());

    case Routes.kanjiSearchRadicals:
      final prechosenRadical = args as String?;
      return MaterialPageRoute(
        builder: (_) => KanjiRadicalSearch(prechosenRadical: prechosenRadical),
      );

    case Routes.library:
      final library = args! as LibraryList;
      return MaterialPageRoute(
        builder: (_) => LibraryContentView(library: library),
      );

    case Routes.aboutLicenses:
      return MaterialPageRoute(builder: (_) => const LicensesView());
    case Routes.aboutChangelog:
      return MaterialPageRoute(builder: (_) => const ChangelogView());

    // TODO: Add more specific error screens.
    case Routes.errorNotFound:
    case Routes.errorNetwork:
    case Routes.errorOther:
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar:
              AppBar(title: const Text('Error'), backgroundColor: Colors.red),
          body: Center(child: ErrorWidget('Some kind of error occured')),
        ),
      );
  }
}
