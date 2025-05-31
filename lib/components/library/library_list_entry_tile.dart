import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (_) async {
              await library.deleteEntry(
                jmdictEntryId: entry.jmdictEntryId,
                kanji: entry.kanji,
              );
              onDelete?.call();
            },
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            entry.kanji != null ? Routes.kanjiSearch : Routes.search,
            arguments: entry.kanji ?? entry.jmdictEntryId,
          );
          onUpdate?.call();
        },
        title: Row(
          children: [
            if (index != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  (index! + 1).toString(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .merge(japaneseFont.textStyle),
                ),
              ),
            entry.kanji != null
                ? KanjiBox.headline4(context: context, kanji: entry.kanji!)
                : Expanded(child: Text(entry.jmdictEntryId.toString())),
          ],
        ),
      ),
    );
  }
}
