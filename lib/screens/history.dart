import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:sqflite/sqlite_api.dart';

import '../components/common/loading.dart';
import '../components/common/opaque_box.dart';
import '../components/history/date_divider.dart';
import '../components/history/history_entry_tile.dart';
import '../models/history_entry.dart';
import '../services/datetime.dart';

const int pageSize = 50;
const int invisibleItemsThreshold = 25;

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final _pagingController = PagingController<int, HistoryEntry?>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      List<HistoryEntry?> result =
          await GetIt.instance.get<Database>().historyEntryGetAll(
                page: pageKey - 1,
                pageSize: pageSize,
              );

      // Insert a null entry at the start in order to prepend a separator to the first actual entry.
      if (pageKey == 1) {
        result = [null, ...result];
      }

      return result;
    },
  );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GetIt.instance.get<Database>().historyEntryGetAll(
      page: 0,
      pageSize: pageSize,
    );

    return FutureBuilder<int>(
      future: GetIt.instance.get<Database>().historyEntryAmount(),
      builder: (context, snapshot) {
        // TODO: provide proper error handling
        if (snapshot.hasError) return ErrorWidget(snapshot.error!);
        if (!snapshot.hasData) return const LoadingScreen();

        final int amountOfEntries = snapshot.data!;

        return OpaqueBox(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    '$amountOfEntries distinct searches made',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PagingListener(
                  controller: _pagingController,
                  builder: (context, state, fetchNextPage) =>
                      PagedListView<int, HistoryEntry?>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) {
                      if (index == 0) {
                        final firstItemDate =
                            _pagingController.items![1]!.lastTimestamp;
                        return _dateDivider(firstItemDate);
                      }

                      final data = _pagingController.items!;

                      final HistoryEntry search = data[index]!;
                      // Previous in the sense of time, but it is the next item in the list.
                      final HistoryEntry? previousSearch =
                          data.length >= index + 1 ? data[index + 1] : null;

                      if (previousSearch != null &&
                          !dateIsEqual(
                            search.lastTimestamp,
                            previousSearch.lastTimestamp,
                          )) {
                        return _dateDivider(previousSearch.lastTimestamp);
                      }

                      return _divider();
                    },
                    builderDelegate: PagedChildBuilderDelegate<HistoryEntry?>(
                      invisibleItemsThreshold: invisibleItemsThreshold,
                      itemBuilder: (context, entry, index) => index == 0
                          ? SizedBox.shrink()
                          : HistoryEntryTile(
                              entry: entry!,
                              objectKey: entry.id,
                              onDelete: () => _pagingController.refresh(),
                            ),
                      noItemsFoundIndicatorBuilder: (context) => const Center(
                        child: Text(
                          'The history is empty.\nTry searching for something!',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dateDivider(DateTime date) =>
      TextDivider(text: formatDate(roundToDay(date)));

  Widget _divider() => const Divider(
        height: 0,
        indent: 10,
        endIndent: 10,
      );
}
