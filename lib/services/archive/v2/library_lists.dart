part of './format.dart';

class ArchiveV2LibraryListMetadata {
  final String name;
  final String slug;

  const ArchiveV2LibraryListMetadata({required this.name, required this.slug});

  Map<String, Object?> toJson() => {'name': name, 'slug': slug};
}

class ArchiveV2LibraryListEntry {
  final DateTime lastModified;
  final int? jmdictEntryId;
  final String? kanji;

  const ArchiveV2LibraryListEntry({
    required this.lastModified,
    this.jmdictEntryId,
    this.kanji,
  }) : assert(
         jmdictEntryId != null || kanji != null,
         'At least one of jmdictEntryId or kanji must be non-null',
       );

  factory ArchiveV2LibraryListEntry.fromLibraryListEntry(
    final LibraryListEntry entry,
  ) => ArchiveV2LibraryListEntry(
    lastModified: entry.lastModified,
    jmdictEntryId: entry.jmdictEntryId,
    kanji: entry.kanji,
  );

  Map<String, Object?> toJson() => {
    'lastModified': lastModified.toIso8601String(),
    'jmdictEntryId': jmdictEntryId,
    'kanji': kanji,
  };

  factory ArchiveV2LibraryListEntry.fromJson(final Map<String, Object?> json) =>
      ArchiveV2LibraryListEntry(
        lastModified: DateTime.parse(json['lastModified'] as String),
        jmdictEntryId: json['jmdictEntryId'] as int?,
        kanji: json['kanji'] as String?,
      );
}

/// Exports metadata about library lists, such as their names and order, into the archive.
Future<void> exportLibraryMetadata(
  final DatabaseExecutor db,
  final Directory archiveRoot,
) async {
  final libraryLists = await db.libraryListGetLists();
  final List<ArchiveV2LibraryListMetadata> metadataList = libraryLists
      .map(
        (final libraryList) => ArchiveV2LibraryListMetadata(
          name: libraryList.name,
          slug: slugifyLibraryListFileName(libraryList.name),
        ),
      )
      .toList();

  final metadataFile = archiveRoot.libraryMetadataFile..createSync();
  await metadataFile.writeAsString(jsonEncode(metadataList));
}

List<ArchiveV2LibraryListMetadata> importLibraryMetadata(
  final Directory archiveRoot,
) {
  final metadataFile = archiveRoot.libraryMetadataFile;
  assert(metadataFile.existsSync(), 'Library metadata file does not exist');

  final String content = metadataFile.readAsStringSync();
  final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;

  return jsonList
      .map((final e) => e as Map<String, Object?>)
      .map(
        (final e) => ArchiveV2LibraryListMetadata(
          name: e['name']! as String,
          slug: e['slug']! as String,
        ),
      )
      .toList();
}

/// Calculate the total number of chunks needed to export all library lists,
/// needed for progress tracking during export.
Future<int> exportLibraryListChunkCount(final DatabaseExecutor db) async =>
    (await db.libraryListGetLists())
        .map(
          (final libraryList) =>
              (libraryList.totalCount / libraryListChunkSize).ceil(),
        )
        .reduce((final a, final b) => a + b);

/// Exports all library lists into json files in the given directory.
///
/// Streams back the number of chunks that have been exported so far.
/// See also [exportLibraryListChunkCount].
Stream<ArchiveV2StreamEvent> exportLibraryLists(
  final DatabaseExecutor db,
  final Directory archiveRoot,
) async* {
  archiveRoot.libraryDir.createSync();

  await exportLibraryMetadata(db, archiveRoot);

  final libraryLists = await db.libraryListGetLists();

  for (final (i, libraryList) in libraryLists.indexed) {
    yield* exportLibraryList(
      db,
      archiveRoot,
      libraryList,
      i + 1,
      libraryLists.length,
    );
  }
}

/// Exports a single library list into json files in the given directory.
///
/// Streams back the number of chunks that have been exported so far.
Stream<ArchiveV2StreamEvent> exportLibraryList(
  final DatabaseExecutor db,
  final Directory archiveRoot,
  final LibraryList libraryList,
  final int index,
  final int total,
) async* {
  final int totalEntries = libraryList.totalCount;
  final int chunkCount = (totalEntries / libraryListChunkSize).ceil();

  archiveRoot.libraryListDir(libraryList.name).createSync();

  for (int i = 0; i < chunkCount; i++) {
    final entryPage = (await db.libraryListGetListEntries(
      libraryList.name,
      page: i,
      pageSize: libraryListChunkSize,
    ))!;

    final archiveEntries = entryPage.entries
        .map(ArchiveV2LibraryListEntry.fromLibraryListEntry)
        .toList();

    archiveRoot.libraryListChunkFile(libraryList.name, i)
      ..createSync()
      ..writeAsStringSync(jsonEncode(archiveEntries));

    yield ArchiveV2StreamEvent(
      type: 'library',
      progress: index,
      total: total,
      name: libraryList.name,
      subProgress: i + 1,
      subTotal: chunkCount,
    );
  }
}

Stream<ArchiveV2StreamEvent> importLibraryLists(
  final DatabaseExecutor db,
  final Directory archiveRoot,
) async* {
  final metadata = importLibraryMetadata(archiveRoot);
  for (final (i, meta) in metadata.indexed) {
    final libraryListDir = archiveRoot.libraryListDir(meta.name);
    if (!libraryListDir.existsSync()) {
      print(
        'Library list directory for "${meta.name}" does not exist. Skipping import.',
      );
      continue;
    }

    if (await db.libraryListExists(meta.name)) {
      if ((await db.libraryListGetList(meta.name))!.totalCount > 0) {
        print(
          'Library list "${meta.name}" already exists and is not empty. Skipping import.',
        );
        continue;
      } else {
        print(
          'Library list "${meta.name}" already exists but is empty. '
          'Importing entries from file $libraryListDir.',
        );
      }
    } else {
      await db.libraryListInsertList(meta.name);
    }

    yield* importLibraryList(
      db,
      meta.name,
      libraryListDir,
      i + 1,
      metadata.length,
    );
  }
  // TODO: assert that we have not missed any library lists not present in the metadata.
}

Stream<ArchiveV2StreamEvent> importLibraryList(
  final DatabaseExecutor db,
  final String libraryListName,
  final Directory libraryListDir,
  final int index,
  final int total,
) async* {
  final chunkFiles = libraryListDir.listSync().whereType<File>();

  for (final (i, chunkFile) in chunkFiles.indexed) {
    final chunkContent = chunkFile.readAsStringSync();
    final List<dynamic> jsonEntries = jsonDecode(chunkContent) as List<dynamic>;

    final entries = jsonEntries
        .map((final e) => e as Map<String, Object?>)
        .map(ArchiveV2LibraryListEntry.fromJson)
        .map(
          (final e) => LibraryListEntry(
            lastModified: e.lastModified,
            jmdictEntryId: e.jmdictEntryId,
            kanji: e.kanji,
          ),
        )
        .toList();

    final result = await db.libraryListInsertEntries(libraryListName, entries);
    if (!result) {
      throw Exception(
        'Failed to insert entries for library list "$libraryListName" from chunk file "${chunkFile.path}".',
      );
    }

    yield ArchiveV2StreamEvent(
      type: 'library',
      progress: index,
      total: total,
      name: libraryListName,
      subProgress: i + 1,
      subTotal: chunkFiles.length,
    );
  }
}
