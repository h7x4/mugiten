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

  factory ArchiveV1LibraryListEntry.fromLibraryListEntry(
    final LibraryListEntry entry,
  ) {
    return ArchiveV1LibraryListEntry(
      lastModified: entry.lastModified,
      jmdictEntryId: entry.jmdictEntryId,
      kanji: entry.kanji,
    );
  }

  factory ArchiveV1LibraryListEntry.fromJson(final Map<String, Object?> json) {
    return ArchiveV1LibraryListEntry(
      lastModified: DateTime.parse(json['lastModified'] as String),
      jmdictEntryId: json['jmdictEntryId'] as int?,
      kanji: json['kanji'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'lastModified': lastModified.toIso8601String(),
    'jmdictEntryId': jmdictEntryId,
    'kanji': kanji,
  };
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
  final entries = (await db.libraryListGetListEntries(libraryName))!.entries
      .map(ArchiveV1LibraryListEntry.fromLibraryListEntry)
      .map((final e) => e.toJson())
      .toList();

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
    final List<ArchiveV1LibraryListEntry> entries =
        (jsonDecode(content) as List)
            .map((final e) => e as Map<String, Object?>)
            .map(ArchiveV1LibraryListEntry.fromJson)
            .toList();

    await libraryListInsertEntriesForSingleList(db, libraryName, entries);
  }
}

/// Append multiple entries into the library list at once, using a list of JSON objects.
Future<void> libraryListInsertEntriesForSingleList(
  final DatabaseExecutor db,
  final String listName,
  final Iterable<ArchiveV1LibraryListEntry> entries, {
  final LibraryListEntry? prevEntry,
  final bool throwErrorOnDuplicate = false,
}) async {
  final List<LibraryListEntry> entries_ = entries
      .map(
        (final e) => LibraryListEntry(
          lastModified: e.lastModified,
          jmdictEntryId: e.jmdictEntryId,
          kanji: e.kanji,
        ),
      )
      .toList();

  await db.libraryListInsertEntries(
    listName,
    entries_,
    prevEntry: prevEntry,
    throwErrorOnDuplicate: throwErrorOnDuplicate,
  );
}
