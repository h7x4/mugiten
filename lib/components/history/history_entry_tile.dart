import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/bloc/theme/theme_bloc.dart';
import 'package:mugiten/components/search/search_results_body/parts/circle_badge.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/services/clipboard.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../routing/routes.dart';
import '../../services/datetime.dart';
import '../../settings.dart';
import '../common/kanji_box.dart';

class HistoryEntryTile extends StatelessWidget {
  final HistoryEntry entry;
  final int objectKey;
  final void Function()? onDelete;
  final void Function()? onFavourite;

  const HistoryEntryTile({
    required this.entry,
    required this.objectKey,
    this.onDelete,
    this.onFavourite,
    super.key,
  });

  /// Perform the search again when the entry is tapped.
  void Function() _onTap(BuildContext context) => entry.isKanji
      ? () => Navigator.pushNamed(
          context,
          Routes.kanjiSearch,
          arguments: entry.kanji,
        )
      : () =>
            Navigator.pushNamed(context, Routes.search, arguments: entry.word);

  /// Copy the kanji/searchword to the clipboard when the entry is long-pressed.
  void Function() _onLongPress(BuildContext context) =>
      () =>
          copyToClipboard(context, entry.isKanji ? entry.kanji! : entry.word!);

  MaterialPageRoute get timestamps => MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(title: const Text('Last searched')),
      body: ListView(
        children: entry.timestamps
            .map(
              (ts) => ListTile(
                title: Text('${formatDate(ts)}    ${formatTime(ts)}'),
              ),
            )
            .toList(),
      ),
    ),
  );

  List<SlidableAction> _actions(BuildContext context) => [
    SlidableAction(
      backgroundColor: Colors.blue,
      icon: Icons.access_time,
      onPressed: (_) => Navigator.push(context, timestamps),
    ),
    SlidableAction(
      backgroundColor: Colors.red,
      icon: Icons.delete,
      onPressed: (_) async {
        await GetIt.instance.get<Database>().historyEntryDelete(entry.id);
        onDelete?.call();
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: _actions(context),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          onTap: _onTap(context),
          onLongPress: _onLongPress(context),
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(formatTime(entry.lastTimestamp)),
              ),
              DefaultTextStyle.merge(
                style: japaneseFont.textStyle,
                child: entry.isKanji
                    ? KanjiBox.headline4(context: context, kanji: entry.kanji!)
                    : Expanded(child: Text(entry.word!)),
              ),
              if (entry.isKanji) Expanded(child: SizedBox.shrink()),
              if (entry.timestampCount > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, themeState) => CircleBadge(
                      color: themeState.theme.menuGreyNormal.background,
                      child: Text('${entry.timestampCount}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
