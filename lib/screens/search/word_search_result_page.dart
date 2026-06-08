import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:jadb/models/word_search/word_search_result.dart';
import 'package:jadb/search.dart' show JaDBConnection;
import 'package:jadb/search/word_search/word_search.dart';
import 'package:mdi/mdi.dart';
import 'package:mugiten/components/search/search_results_body/parts/circle_badge.dart';
import 'package:mugiten/components/search/search_results_body/search_card.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/services/datetime.dart';
import 'package:mugiten/services/snackbar.dart';
import 'package:mugiten/settings.dart';
import 'package:mugiten/theme.dart';
import 'package:sqflite/sqflite.dart';

const int pageSize = 50;
const int invisibleItemsThreshold = 25;

class WordSearchResultPage extends StatefulWidget {
  final String searchTerm;
  final SearchMode searchMode;

  const WordSearchResultPage({
    required this.searchTerm,
    this.searchMode = SearchMode.auto,
    super.key,
  });

  @override
  State<WordSearchResultPage> createState() => _WordSearchResultPageState();
}

class _WordSearchResultPageState extends State<WordSearchResultPage> {
  bool addedToDatabase = false;
  HistoryEntry? historyEntry;

  late final _pagingController = PagingController<int, WordSearchResult>(
    getNextPageKey: (final state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (final pageKey) => GetIt.instance
        .get<Database>()
        .jadbSearchWord(
          widget.searchTerm,
          searchMode: widget.searchMode,
          page: pageKey - 1,
          pageSize: pageSize,
        )
        .then((final v) => v ?? <WordSearchResult>[]),
  );

  @override
  void initState() {
    super.initState();

    if (!incognitoModeEnabled.value && !addedToDatabase) {
      unawaited(
        GetIt.instance
            .get<Database>()
            .historyEntryInsertWord(widget.searchTerm)
            .then(
              (_) => GetIt.instance.get<Database>().historyEntryGetWord(
                widget.searchTerm,
              ),
            )
            .then(
              (final entry) => setState(() {
                addedToDatabase = true;
                historyEntry = entry;
              }),
            ),
      );
    } else {
      unawaited(
        GetIt.instance
            .get<Database>()
            .historyEntryGetWord(widget.searchTerm)
            .then(
              (final entry) => setState(() {
                historyEntry = entry;
              }),
            ),
      );
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = Theme.of(context).extension<MenuGreyNormalThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('"${widget.searchTerm}"', style: japaneseFont.value.textStyle),
            if (widget.searchMode != SearchMode.auto)
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  '(${widget.searchMode.name})',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (incognitoModeEnabled.value)
            IconButton(
              icon: const Icon(Mdi.incognito),
              onPressed: () =>
                  showSnackbar(context, 'History tracking is disabled'),
            ),
          if (historyEntry != null && historyEntry!.timestampCount > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  unawaited(
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (final context) => Scaffold(
                          appBar: AppBar(title: const Text('Last searched')),
                          body: ListView(
                            children: historyEntry!.timestamps
                                .map(
                                  (final ts) => ListTile(
                                    title: Text(
                                      '${formatDate(ts)}    ${formatTime(ts)}',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: CircleBadge(
                  color: colors.backgroundColor!,
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
            .then((final v) => v ?? 0),
        builder: (final context, final snapshot) {
          if (snapshot.hasError) return ErrorWidget(snapshot.error!);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final searchCount = snapshot.data!;
          final singleItem = searchCount == 1;

          return Column(
            children: [
              Center(
                child: Text(
                  'Found $searchCount result${searchCount != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
              Expanded(
                child: PagingListener(
                  controller: _pagingController,
                  builder: (final context, final state, final fetchNextPage) =>
                      PagedListView<int, WordSearchResult>(
                        state: state,
                        fetchNextPage: fetchNextPage,
                        builderDelegate: PagedChildBuilderDelegate(
                          invisibleItemsThreshold: invisibleItemsThreshold,
                          itemBuilder:
                              (final context, final item, final index) =>
                                  SearchResultCard(
                                    result: item,
                                    initiallyExpanded: singleItem,
                                  ),
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
