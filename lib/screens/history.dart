import 'package:flutter/material.dart';

import '../components/common/loading.dart';
import '../components/common/opaque_box.dart';
import '../components/history/date_divider.dart';
import '../components/history/history_entry_tile.dart';
import '../models/history/history_entry.dart';
import '../services/datetime.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Use infinite scroll pagination
    return FutureBuilder<List<HistoryEntry>>(
      future: HistoryEntry.fromDB,
      builder: (context, snapshot) {
        // TODO: provide proper error handling
        if (snapshot.hasError) return ErrorWidget(snapshot.error!);
        if (!snapshot.hasData) return const LoadingScreen();

        final Map<int, HistoryEntry> data = snapshot.data!.asMap();
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
    List<HistoryEntry> data,
  ) =>
      (context, index) {
        final HistoryEntry search = data[index];
        final DateTime searchDate = search.lastTimestamp;

        if (index == 0 ||
            !dateIsEqual(data[index - 1].lastTimestamp, searchDate)) {
          return TextDivider(text: formatDate(roundToDay(searchDate)));
        }

        return const Divider(
          height: 0,
          indent: 10,
          endIndent: 10,
        );
      };

  Widget Function(BuildContext, int) historyEntryWithData(
    Map<int, HistoryEntry> data,
  ) =>
      (context, index) => (index == 0)
          ? const SizedBox.shrink()
          : HistoryEntryTile(
              entry: data.values.toList()[index - 1],
              objectKey: data.keys.toList()[index - 1],
              onDelete: () => build(context),
            );
}
