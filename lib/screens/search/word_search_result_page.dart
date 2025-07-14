import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:jadb/models/word_search/word_search_result.dart';
import 'package:jadb/search.dart' show JaDBConnection;
import 'package:mdi/mdi.dart';
import 'package:mugiten/bloc/theme/theme_bloc.dart';
import 'package:mugiten/components/search/search_results_body/parts/circle_badge.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/services/snackbar.dart';
import 'package:mugiten/settings.dart';
import 'package:sqflite/sqflite.dart';

import '../../components/search/search_results_body/search_card.dart';

const int pageSize = 50;
const int invisibleItemsThreshold = 25;

class WordSearchResultPage extends StatefulWidget {
  final String searchTerm;

  const WordSearchResultPage({
    required this.searchTerm,
    super.key,
  });

  @override
  State<WordSearchResultPage> createState() => _WordSearchResultPageState();
}

class _WordSearchResultPageState extends State<WordSearchResultPage> {
  bool addedToDatabase = false;
  HistoryEntry? historyEntry;

  late final _pagingController = PagingController<int, WordSearchResult>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) => GetIt.instance
        .get<Database>()
        .jadbSearchWord(
          widget.searchTerm,
          page: pageKey - 1,
          pageSize: pageSize,
        )
        .then((v) => v ?? <WordSearchResult>[]),
  );

  @override
  void initState() {
    super.initState();

    if (!incognitoModeEnabled && !addedToDatabase) {
      GetIt.instance
          .get<Database>()
          .historyEntryInsertWord(widget.searchTerm)
          .then((_) => GetIt.instance
              .get<Database>()
              .historyEntryGetWord(widget.searchTerm))
          .then(
            (entry) => setState(() {
              addedToDatabase = true;
              historyEntry = entry;
            }),
          );
    } else {
      GetIt.instance
          .get<Database>()
          .historyEntryGetWord(widget.searchTerm)
          .then(
            (entry) => setState(() {
              historyEntry = entry;
            }),
          );
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
        actions: [
          if (incognitoModeEnabled)
            IconButton(
              icon: const Icon(Mdi.incognito),
              onPressed: () =>
                  showSnackbar(context, 'History tracking is disabled'),
            ),
          if (historyEntry != null && historyEntry!.timestampCount > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) => CircleBadge(
                  color: themeState.theme.menuGreyNormal.background,
                  child: Text('${historyEntry!.timestampCount}'),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder(
        future: GetIt.instance
            .get<Database>()
            .jadbSearchWordCount(widget.searchTerm)
            .then((v) => v ?? 0),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorWidget(snapshot.error!);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final searchCount = snapshot.data!;

          return Column(
            children: [
              Center(
                child: Text(
                  'Found $searchCount results for "${widget.searchTerm}"',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: PagingListener(
                  controller: _pagingController,
                  builder: (context, state, fetchNextPage) =>
                      PagedListView<int, WordSearchResult>(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    builderDelegate: PagedChildBuilderDelegate(
                      invisibleItemsThreshold: invisibleItemsThreshold,
                      itemBuilder: (context, item, index) =>
                          SearchResultCard(result: item),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
