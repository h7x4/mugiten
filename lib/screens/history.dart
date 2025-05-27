import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sembast/sembast_io.dart';

import '../components/common/loading.dart';
import '../components/common/opaque_box.dart';
import '../components/history/date_divider.dart';
import '../components/history/search_item.dart';
import '../models/history/search.dart';
import '../services/datetime.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  Stream<Map<int, Search>> get searchStream => Search.store
      .query(finder: Finder(sortOrders: [SortOrder('lastTimestamp', false)]))
      .onSnapshots(_db)
      .map(
        (snapshot) => Map.fromEntries(
          snapshot.where((snap) => snap.value != null).map(
                (snap) => MapEntry(
                  snap.key,
                  Search.fromJson(snap.value! as Map<String, Object?>),
                ),
              ),
        ),
      );

  Database get _db => GetIt.instance.get<Database>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<int, Search>>(
      stream: searchStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingScreen();

        final Map<int, Search> data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(
            child: Text('The history is empty.\nTry searching for something!'),
          );
        }

        return OpaqueBox(
          child: ListView.separated(
            itemCount: data.length + 1,
            itemBuilder: historyEntryWithData(data),
            separatorBuilder:
                historyEntrySeparatorWithData(data.values.toList()),
          ),
        );
      },
    );
  }

  Widget Function(BuildContext, int) historyEntrySeparatorWithData(
    List<Search> data,
  ) =>
      (context, index) {
        final Search search = data[index];
        final DateTime searchDate = search.timestamp;

        if (index == 0 || !dateIsEqual(data[index - 1].timestamp, searchDate)) {
          return TextDivider(text: formatDate(roundToDay(searchDate)));
        }

        return const Divider(height: 0);
      };

  Widget Function(BuildContext, int) historyEntryWithData(
    Map<int, Search> data,
  ) =>
      (context, index) => (index == 0)
          ? const SizedBox.shrink()
          : SearchItem(
              search: data.values.toList()[index - 1],
              objectKey: data.keys.toList()[index - 1],
              onDelete: () => build(context),
            );
}
