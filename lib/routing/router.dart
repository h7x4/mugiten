import 'package:flutter/material.dart';
import 'package:jadb/const_data/radicals.dart';
import 'package:jadb/search/word_search/word_search.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/screens/home.dart';
import 'package:mugiten/screens/info/changelog.dart';
import 'package:mugiten/screens/info/datasources.dart';
import 'package:mugiten/screens/info/licenses.dart';
import 'package:mugiten/screens/library/library_content_view.dart';
import 'package:mugiten/screens/search/kanji_search_result_page.dart';
import 'package:mugiten/screens/search/search_mechanisms/drawing.dart';
import 'package:mugiten/screens/search/search_mechanisms/grade_list.dart';
import 'package:mugiten/screens/search/search_mechanisms/radical_list.dart';
import 'package:mugiten/screens/search/word_search_result_page.dart';

Route<Widget> generateRoute(final RouteSettings settings) {
  final args = settings.arguments;

  switch (settings.name) {
    case Routes.root:
      return MaterialPageRoute(builder: (_) => const Home());

    case Routes.search:
      final args_ = args is String
          ? (args, SearchMode.auto)
          : args is (String, SearchMode)
          ? args
          : throw ArgumentError(
              'Invalid arguments for ${Routes.search}: $args. Expected either a String or a (String, SearchMode) tuple.',
            );
      return MaterialPageRoute(
        builder: (_) =>
            WordSearchResultPage(searchTerm: args_.$1, searchMode: args_.$2),
      );

    case Routes.kanjiSearch:
      final searchTerm = args! as String;
      return MaterialPageRoute(
        builder: (_) => KanjiSearchResultPage(kanji: searchTerm),
      );

    case Routes.kanjiSearchDraw:
      return MaterialPageRoute(builder: (_) => const KanjiDrawingSearch());

    case Routes.kanjiSearchGrade:
      return MaterialPageRoute(builder: (_) => const KanjiGradeSearch());

    case Routes.kanjiSearchRadicals:
      late final RadkfileRadical? prechosenRadical;
      if (args != null && args is String) {
        prechosenRadical = radicalsByFormalVariant[args];
      } else if (args != null && args is RadkfileRadical) {
        prechosenRadical = args;
      } else {
        prechosenRadical = null;
      }

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
    case Routes.aboutDatasources:
      return MaterialPageRoute(builder: (_) => const DataSourcesView());

    // TODO: Add more specific error screens.
    case Routes.errorNotFound:
    case Routes.errorNetwork:
    case Routes.errorOther:
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
            backgroundColor: Colors.red,
          ),
          body: Center(child: ErrorWidget('Some kind of error occured')),
        ),
      );
  }
}
