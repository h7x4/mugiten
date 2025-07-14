import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../components/common/loading.dart';
import '../../components/library/library_list_tile.dart';

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
      .then((libs) => setState(() => libraries = libs));

  @override
  void initState() {
    super.initState();
    getEntriesFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    if (libraries == null) return const LoadingScreen();
    return Column(
      children: [
        LibraryListTile(
          library: libraries!.first,
          leading: const Icon(Icons.star),
          onDelete: getEntriesFromDatabase,
          onUpdate: getEntriesFromDatabase,
          isEditable: false,
        ),
        Expanded(
          child: ListView(
            children: libraries!
                // Skip favourites
                .skip(1)
                .map(
                  (e) => LibraryListTile(
                    library: e,
                    onDelete: getEntriesFromDatabase,
                    onUpdate: getEntriesFromDatabase,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
