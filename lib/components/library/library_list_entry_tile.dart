import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/components/common/kanji_box.dart';
import 'package:mugiten/components/search/search_results_body/search_card.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/services/clipboard.dart';
import 'package:mugiten/settings.dart';
import 'package:sqflite/sqlite_api.dart';

class LibraryListEntryTile extends StatelessWidget {
  final int? index;
  final LibraryList library;
  final LibraryListEntry entry;
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
  Widget build(final BuildContext context) {
    return entry.kanji != null
        ? _kanjiTile(context, index, entry.kanji!)
        : _jmdictEntryTile(context, index, entry);
  }

  Widget _index(final BuildContext context, final int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        (index + 1).toString(),
        style: Theme.of(
          context,
        ).textTheme.titleMedium!.merge(japaneseFont.value.textStyle),
      ),
    );
  }

  SlidableAction _deleteAction() {
    return SlidableAction(
      backgroundColor: Colors.red,
      icon: Icons.delete,
      onPressed: (_) async {
        await GetIt.instance.get<Database>().libraryListDeleteEntry(
          library.name,
          jmdictEntryId: entry.jmdictEntryId,
          kanji: entry.kanji,
        );
        onDelete?.call();
      },
    );
  }

  Widget _kanjiTile(
    final BuildContext context,
    final int? index,
    final String kanji,
  ) {
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
        onLongPress: () => copyToClipboard(context, kanji),
        title: Row(
          children: [
            const SizedBox(width: 15),
            KanjiBox.headline4(context: context, kanji: kanji),
          ],
        ),
      ),
    );
  }

  Widget _jmdictEntryTile(
    final BuildContext context,
    final int? index,
    final LibraryListEntry entry,
  ) {
    return SearchResultCard(
      result: entry.wordSearchResult!,
      leading: index != null ? _index(context, index) : null,
      slidableActions: [_deleteAction()],
    );
  }
}
