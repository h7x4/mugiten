import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mugiten/components/common/loading.dart';
import 'package:mugiten/components/common/opaque_box.dart';
import 'package:mugiten/components/history/date_divider.dart';
import 'package:mugiten/components/history/history_entry_tile.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/services/datetime.dart';
import 'package:sqflite/sqlite_api.dart';

const int pageSize = 50;
const int invisibleItemsThreshold = 25;
const int minutesBetweenTimeDividers = 30;

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final _pagingController = PagingController<int, HistoryEntry?>(
    getNextPageKey: (final state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (final pageKey) async {
      List<HistoryEntry?> result = await GetIt.instance
          .get<Database>()
          .historyEntryGetAll(page: pageKey - 1, pageSize: pageSize);

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
  Widget build(final BuildContext context) {
    return FutureBuilder<int>(
      future: GetIt.instance.get<Database>().historyEntryAmount(),
      builder: (final context, final snapshot) {
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
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                child: PagingListener(
                  controller: _pagingController,
                  builder: (final context, final state, final fetchNextPage) =>
                      PagedListView<int, HistoryEntry?>.separated(
                        state: state,
                        fetchNextPage: fetchNextPage,
                        separatorBuilder: (final context, final index) {
                          if (index == 0) {
                            if (_pagingController.items == null ||
                                _pagingController.items!.length < 2) {
                              // No history entries, or the items has not been loaded yet.
                              return const SizedBox.shrink();
                            } else {
                              // The first item is a dummy null entry, so we need to get the date from the second item.
                              final firstItemDate =
                                  _pagingController.items![1]!.lastTimestamp;
                              return _dateDivider(firstItemDate);
                            }
                          }

                          final data = _pagingController.items!;

                          final HistoryEntry search = data[index]!;

                          // Previous in the sense of time, but it is the next item in the list.
                          final HistoryEntry? previousSearch =
                              data.length > index + 1 ? data[index + 1] : null;

                          // Date divider
                          if (previousSearch != null &&
                              !dateIsEqual(
                                search.lastTimestamp,
                                previousSearch.lastTimestamp,
                              )) {
                            return _dateDivider(previousSearch.lastTimestamp);
                          }

                          // Large divider
                          if (previousSearch != null &&
                              search.lastTimestamp
                                      .difference(previousSearch.lastTimestamp)
                                      .inMinutes >
                                  minutesBetweenTimeDividers) {
                            return _timeDivider(previousSearch.lastTimestamp);
                          }

                          // Regular divider
                          return _divider();
                        },
                        builderDelegate: PagedChildBuilderDelegate<HistoryEntry?>(
                          invisibleItemsThreshold: invisibleItemsThreshold,
                          itemBuilder:
                              (final context, final entry, final index) =>
                                  index == 0
                                  ? const SizedBox.shrink()
                                  : HistoryEntryTile(
                                      entry: entry!,
                                      objectKey: entry.id,
                                      onDelete: () =>
                                          _pagingController.refresh(),
                                    ),
                          noItemsFoundIndicatorBuilder: (final context) =>
                              const Center(
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

  Widget _dateDivider(final DateTime date) =>
      TextDivider(text: formatDate(roundToDay(date)));

  Widget _timeDivider(final DateTime date) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Expanded(
        child: Divider(height: 20, thickness: 5, indent: 10, endIndent: 10),
      ),
      Text(
        formatTime(date),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const Expanded(
        child: Divider(height: 20, thickness: 5, indent: 10, endIndent: 10),
      ),
    ],
  );

  Widget _divider() => const Divider(height: 0, indent: 10, endIndent: 10);
}
