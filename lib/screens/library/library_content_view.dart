import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../components/common/loading.dart';
import '../../components/library/library_list_entry_tile.dart';

class LibraryContentView extends StatefulWidget {
  final LibraryList library;
  const LibraryContentView({
    super.key,
    required this.library,
  });

  @override
  State<LibraryContentView> createState() => _LibraryContentViewState();
}

class _LibraryContentViewState extends State<LibraryContentView> {
  List<LibraryListEntry>? entries;

  Future<void> getEntriesFromDatabase() => GetIt.instance
      .get<Database>()
      .libraryListGetListEntries(
        widget.library.name,
        includeSearchResult: true,
      )
      .then((entries_) => setState(() => entries = entries_?.entries));

  @override
  void initState() {
    super.initState();
    getEntriesFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name),
        actions: [
          IconButton(
            onPressed: () async {
              final entryCount = widget.library.totalCount;
              if (!context.mounted) return;
              final bool userIsSure = await confirm(
                context,
                content: Text(
                  'Are you sure that you want to clear all $entryCount entries?',
                ),
              );
              if (!userIsSure) return;

              await GetIt.instance
                  .get<Database>()
                  .libraryListDeleteAllEntries(widget.library.name);

              await getEntriesFromDatabase();
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: entries == null
          ? const LoadingScreen()
          : ListView.separated(
              itemCount: entries!.length,
              itemBuilder: (context, index) => LibraryListEntryTile(
                index: index,
                entry: entries![index],
                library: widget.library,
                onDelete: () => setState(() {
                  entries!.removeAt(index);
                }),
                onUpdate: () => getEntriesFromDatabase(),
              ),
              separatorBuilder: (context, index) => const Divider(
                height: 0,
                indent: 10,
                endIndent: 10,
              ),
            ),
    );
  }
}
