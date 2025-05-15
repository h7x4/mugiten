import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';
import 'package:mugiten/screens/search/kanji_search_view.dart';
import 'package:mugiten/screens/search/word_search_view.dart';

import '../bloc/theme/theme_bloc.dart';
import '../components/common/denshi_jisho_background.dart';
import 'debug.dart';
import 'history.dart';
import 'settings.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageNum = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          appBar: AppBar(
            title: pages[pageNum].titleBar,
            centerTitle: true,
            backgroundColor: AppTheme.jishoGreen.background,
            foregroundColor: AppTheme.jishoGreen.foreground,
          ),
          body: DenshiJishoBackground(child: pages[pageNum].content),
          bottomNavigationBar: BottomNavigationBar(
            fixedColor: AppTheme.jishoGreen.background,
            currentIndex: pageNum,
            onTap: (index) => setState(() {
              pageNum = index;
            }),
            items: pages.map((p) => p.item).toList(),
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
          titleBar: Text('Search'),
          item: BottomNavigationBarItem(
            label: 'Search',
            icon: Icon(Icons.search),
          ),
        ),
        const _Page(
          content: KanjiSearchView(),
          titleBar: Text('Kanji Search'),
          item: BottomNavigationBarItem(
            label: 'Kanji',
            icon: Icon(Mdi.ideogramCjk, size: 30),
          ),
        ),
        const _Page(
          content: HistoryView(),
          titleBar: Text('History'),
          item: BottomNavigationBarItem(
            label: 'History',
            icon: Icon(Icons.history),
          ),
        ),
        _Page(
          content: Container(),
          titleBar: const Text('Saved'),
          item: const BottomNavigationBarItem(
            label: 'Saved',
            icon: Icon(Icons.bookmark),
          ),
        ),
        const _Page(
          content: SettingsView(),
          titleBar: Text('Settings'),
          item: BottomNavigationBarItem(
            label: 'Settings',
            icon: Icon(Icons.settings),
          ),
        ),
        if (kDebugMode) ...[
          const _Page(
            content: DebugView(),
            titleBar: Text('Debug Page'),
            item: BottomNavigationBarItem(
              label: 'Debug',
              icon: Icon(Icons.biotech),
            ),
          )
        ],
      ];
}

class _Page {
  final Widget content;
  final Widget titleBar;
  final BottomNavigationBarItem item;

  const _Page({
    required this.content,
    required this.titleBar,
    required this.item,
  });
}
