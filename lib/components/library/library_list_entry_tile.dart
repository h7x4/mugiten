import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/components/search/search_results_body/search_card.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../models/library/library_entry.dart';
import '../../models/library/library_list.dart';
import '../../routing/routes.dart';
import '../../settings.dart';
import '../common/kanji_box.dart';

class LibraryListEntryTile extends StatelessWidget {
  final int? index;
  final LibraryList library;
  final LibraryEntry entry;
  final void Function()? onDelete;
  final void Function()? onUpdate;

  const LibraryListEntryTile({
    super.key,
    required this.entry,
    required this.library,
    this.index,
    this.onDelete,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return entry.kanji != null
        ? _kanjiTile(context, index, entry.kanji!)
        : _jmdictEntryTile(context, index, entry.jmdictEntryId!);
  }

  Widget _index(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        (index + 1).toString(),
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .merge(japaneseFont.textStyle),
      ),
    );
  }

  SlidableAction _deleteAction() {
    return SlidableAction(
      backgroundColor: Colors.red,
      icon: Icons.delete,
      onPressed: (_) async {
        await library.deleteEntry(
          db: GetIt.instance.get<Database>(),
          jmdictEntryId: entry.jmdictEntryId,
          kanji: entry.kanji,
        );
        onDelete?.call();
      },
    );
  }

  Widget _kanjiTile(BuildContext context, int? index, String kanji) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [_deleteAction()],
      ),
      child: ListTile(
        leading: (index != null) ? _index(context, index) : null,
        onTap: () async {
          await Navigator.pushNamed(
            context,
            Routes.kanjiSearch,
            arguments: kanji,
          );
          onUpdate?.call();
        },
        title: Row(children: [
          SizedBox(width: 15),
          KanjiBox.headline4(context: context, kanji: kanji),
        ]),
      ),
    );
  }

  Widget _jmdictEntryTile(BuildContext context, int? index, int jmdictEntryId) {
    return FutureBuilder(
      future: GetIt.instance.get<Database>().jadbGetWordById(jmdictEntryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: (index != null) ? _index(context, index) : null,
            title: const Expanded(
              child: Text(
                '...',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return ListTile(
            leading: (index != null) ? _index(context, index) : null,
            title: const Expanded(
              child: Text(
                '<Not found>',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        final entry = snapshot.data!;

        final result = SearchResultCard(
          result: entry,
          leading: index != null ? _index(context, index) : null,
          slidableActions: [_deleteAction()],
        );

        return result;
      },
    );
  }
}
