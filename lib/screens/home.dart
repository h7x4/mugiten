import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';
import 'package:mugiten/screens/search/kanji_search_view.dart';
import 'package:mugiten/screens/search/word_search_view.dart';

import '../bloc/theme/theme_bloc.dart';
import '../components/common/denshi_jisho_background.dart';
import '../components/library/new_library_dialog.dart';
import 'debug.dart';
import 'history.dart';
import 'library/library_view.dart';
import 'settings.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageNum = 0;

  _Page get page => pages[pageNum];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          appBar: AppBar(
            title: Text(page.titleBar),
            centerTitle: true,
            backgroundColor: AppTheme.mugitenWheat.background,
            foregroundColor: AppTheme.mugitenWheat.foreground,
            actions: page.actions,
          ),
          body: DenshiJishoBackground(child: page.content),
          bottomNavigationBar: BottomNavigationBar(
            fixedColor: AppTheme.mugitenWheat.background,
            currentIndex: pageNum,
            onTap: (index) => setState(() {
              pageNum = index;
            }),
            items: pages
                .map(
                  (p) => BottomNavigationBarItem(
                    label: p.titleBar,
                    icon: p.icon,
                  ),
                )
                .toList(),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            unselectedItemColor: themeState.theme.menuGreyDark.background,
          ),
        );
      },
    );
  }

  List<_Page> get pages => [
        const _Page(
          content: WordSearchView(),
          titleBar: 'Search',
          icon: Icon(Icons.search),
        ),
        const _Page(
          content: KanjiSearchView(),
          titleBar: 'Kanji Search',
          icon: Icon(Mdi.ideogramCjk, size: 30),
        ),
        const _Page(
          content: HistoryView(),
          titleBar: 'History',
          icon: Icon(Icons.history),
        ),
        _Page(
          content: const LibraryView(),
          titleBar: 'Library',
          icon: const Icon(Icons.bookmark),
          actions: [
            IconButton(
              onPressed: showNewLibraryDialog(context),
              icon: const Icon(Icons.add),
            )
          ],
        ),
        const _Page(
          content: SettingsView(),
          titleBar: 'Settings',
          icon: Icon(Icons.settings),
        ),
        if (kDebugMode) ...[
          const _Page(
            content: DebugView(),
            titleBar: 'Debug Page',
            icon: Icon(Icons.biotech),
          )
        ],
      ];
}

class _Page {
  final Widget content;
  final String titleBar;
  final Icon icon;
  final List<Widget> actions;

  const _Page({
    required this.content,
    required this.titleBar,
    required this.icon,
    this.actions = const [],
  });
}
