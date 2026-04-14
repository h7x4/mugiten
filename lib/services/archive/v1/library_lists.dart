part of './format.dart';

class ArchiveV1LibraryListEntry {
  final DateTime lastModified;
  final int? jmdictEntryId;
  final String? kanji;

  const ArchiveV1LibraryListEntry({
    required this.lastModified,
    this.jmdictEntryId,
    this.kanji,
  }) : assert(
         jmdictEntryId != null || kanji != null,
         'At least one of jmdictEntryId or kanji must be non-null',
       );
}

Future<void> exportLibraryListsTo(
  final DatabaseExecutor db,
  final Directory archiveRoot,
) async {
  final libraryNames = await db
      .query(LibraryListTableNames.libraryList, columns: ['name'])
      .then(
        (final result) =>
            result.map((final row) => row['name'] as String).toList(),
      );

  await Future.wait([
    for (final libraryName in libraryNames)
      exportLibraryListTo(db, libraryName, archiveRoot.libraryDir),
  ]);
}

Future<void> exportLibraryListTo(
  final DatabaseExecutor db,
  final String libraryName,
  final Directory dir,
) async {
  final file = File(dir.uri.resolve('$libraryName.json').toFilePath());
  await file.create();

  // TODO: properly null check
  final entries = (await db.libraryListGetListEntries(
    libraryName,
  ))!.entries.map((final e) => e.toJson()).toList();

  await file.writeAsString(jsonEncode(entries));
}

// TODO: how do we handle lists that already exist? There seems to be no good way to merge them?
Future<void> importLibraryListsFrom(
  final DatabaseExecutor db,
  final Directory archiveRoot,
) async {
  for (final file in archiveRoot.libraryListFiles) {
    final libraryName = file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.json$'),
      '',
    );

    if (await db.libraryListExists(libraryName)) {
      if ((await db.libraryListGetList(libraryName))!.totalCount > 0) {
        print(
          'Library list "$libraryName" already exists and is not empty. Skipping import.',
        );
        continue;
      } else {
        print(
          'Library list "$libraryName" already exists but is empty. '
          'Importing entries from file ${file.path}.',
        );
      }
    } else {
      await db.libraryListInsertList(libraryName);
    }

    final content = await file.readAsString();
    final List<Map<String, Object?>> jsonEntries = (jsonDecode(content) as List)
        .map((final e) => e as Map<String, Object?>)
        .toList();

    await libraryListInsertJsonEntriesForSingleList(
      db,
      libraryName,
      jsonEntries,
    );
  }
}

/// Append multiple entries into the library list at once, using a list of JSON objects.
Future<void> libraryListInsertJsonEntriesForSingleList(
  final DatabaseExecutor db,
  final String listName,
  final Iterable<Map<String, Object?>> jsonEntries, {
  final LibraryListEntry? prevEntry,
  final bool throwErrorOnDuplicate = false,
}) async {
  final List<LibraryListEntry> entries = jsonEntries
      .map(LibraryListEntry.fromJson)
      .toList();

  await db.libraryListInsertEntries(
    listName,
    entries,
    prevEntry: prevEntry,
    throwErrorOnDuplicate: throwErrorOnDuplicate,
  );
}
