import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';
import 'package:mugiten/screens/search/kanji_search_view.dart';
import 'package:mugiten/screens/search/word_search_view.dart';
import 'package:mugiten/services/snackbar.dart';
import 'package:mugiten/settings.dart';
import 'package:mugiten/theme.dart';

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
    final colors = Theme.of(context).extension<MenuGreyDarkThemeExtension>()!;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ValueListenableBuilder(
          valueListenable: incognitoModeEnabled,
          builder: (context, incognitoEnabled, child) => AppBar(
            title: Text(page.titleBar),
            centerTitle: true,
            foregroundColor: incognitoEnabled
                ? Colors.white
                : mugitenWheatForeground,
            backgroundColor: incognitoEnabled
                ? Colors.deepPurple
                : mugitenWheatBackground,
            actions: incognitoEnabled
                ? [
                    IconButton(
                      icon: const Icon(Mdi.incognito),
                      onPressed: () =>
                          showSnackbar(context, 'History tracking is disabled'),
                    ),
                    ...page.actions,
                  ]
                : page.actions,
          ),
        ),
      ),
      body: DenshiJishoBackground(child: page.content),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: mugitenWheatBackground,
        currentIndex: pageNum,
        onTap: (index) => setState(() {
          pageNum = index;
        }),
        items: pages
            .map(
              (p) => BottomNavigationBarItem(label: p.titleBar, icon: p.icon),
            )
            .toList(),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        unselectedItemColor: colors.backgroundColor,
      ),
    );
  }

  List<_Page> get pages => [
    _Page(
      content: WordSearchView(),
      titleBar: 'Search',
      icon: Icon(Icons.search),
      // actions: [
      //   if (incognitoModeEnabled.value)
      //     IconButton(
      //       icon: const Icon(Mdi.incognito),
      //       onPressed: () =>
      //           showSnackbar(context, 'History tracking is disabled'),
      //     ),
      // ],
    ),
    _Page(
      content: KanjiSearchView(),
      titleBar: 'Kanji Search',
      icon: Icon(Mdi.ideogramCjk, size: 30),
      // actions: [
      //   if (incognitoModeEnabled.value)
      //     IconButton(
      //       icon: const Icon(Mdi.incognito),
      //       onPressed: () =>
      //           showSnackbar(context, 'History tracking is disabled'),
      //     ),
      // ],
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
        ),
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
      ),
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
