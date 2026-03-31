import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/components/common/loading.dart';
import 'package:mugiten/components/library/library_list_tile.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:sqflite/sqlite_api.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  List<LibraryList>? libraries;

  Future<void> getEntriesFromDatabase() => GetIt.instance
      .get<Database>()
      .libraryListGetLists()
      .then((final libs) => setState(() => libraries = libs));

  @override
  void initState() {
    super.initState();
    unawaited(getEntriesFromDatabase());
  }

  @override
  Widget build(final BuildContext context) {
    if (libraries == null) return const LoadingScreen();
    return Column(
      children: [
        LibraryListTile(
          key: ValueKey(libraries!.first.name),
          library: libraries!.first,
          leading: const Icon(Icons.star),
          isEditable: false,
        ),
        Expanded(
          child: ListView(
            children: libraries!
                // Skip favourites
                .skip(1)
                .map(
                  (final e) => LibraryListTile(
                    key: ValueKey(e.name),
                    library: e,
                    onDelete: getEntriesFromDatabase,
                    onRename: (_, _) => getEntriesFromDatabase(),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
