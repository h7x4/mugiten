part of './format.dart';

class ArchiveV2LibraryListMetadata {
  final String name;
  final String slug;

  ArchiveV2LibraryListMetadata({required this.name, final String? slug})
    : slug = slug ?? slugifyLibraryListFileName(name);

  factory ArchiveV2LibraryListMetadata.fromJson(
    final Map<String, Object?> json,
  ) => ArchiveV2LibraryListMetadata(
    name: json['name']! as String,
    slug: json['slug']! as String,
  );

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

class ArchiveV2ExportLibraryList {
  final ArchiveV2LibraryListMetadata metadata;
  final int totalCount;

  const ArchiveV2ExportLibraryList({
    required this.metadata,
    required this.totalCount,
  });
}

Future<List<ArchiveV2ExportLibraryList>> _getExportLibraryLists(
  final DatabaseExecutor db, {
  required final ArchiveV2ExportAdapter adapter,
}) async {
  final metadata = await adapter.libraryListGetLibraryMetadata(db: db);
  final counts = await adapter.libraryListGetTotalCounts(db: db);

  return metadata
      .map(
        (final meta) => ArchiveV2ExportLibraryList(
          metadata: meta,
          totalCount: counts[meta.name] ?? 0,
        ),
      )
      .toList();
}

/// Exports metadata about library lists, such as their names and order, into the archive.
Future<void> exportLibraryMetadata(
  final Directory archiveRoot,
  final List<ArchiveV2ExportLibraryList> libraryLists,
) async {
  final metadataFile = archiveRoot.libraryMetadataFile..createSync();
  await metadataFile.writeAsString(
    jsonEncode(
      libraryLists
          .map((final libraryList) => libraryList.metadata.toJson())
          .toList(),
    ),
  );
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
      .map(ArchiveV2LibraryListMetadata.fromJson)
      .toList();
}

/// Calculate the total number of chunks needed to export all library lists,
/// needed for progress tracking during export.
Future<int> exportLibraryListChunkCount(
  final DatabaseExecutor db, {
  final ArchiveV2ExportAdapter? adapter,
}) async =>
    (await _getExportLibraryLists(
          db,
          adapter: adapter ?? latestSchemaExportAdapter,
        ))
        .map(
          (final libraryList) =>
              (libraryList.totalCount / libraryListChunkSize).ceil(),
        )
        .sum;

/// Exports all library lists into json files in the given directory.
///
/// Streams back the number of chunks that have been exported so far.
/// See also [exportLibraryListChunkCount].
Stream<ArchiveV2StreamEvent> exportLibraryLists(
  final DatabaseExecutor db,
  final Directory archiveRoot, {
  final ArchiveV2ExportAdapter? adapter,
}) async* {
  final exportAdapter = adapter ?? latestSchemaExportAdapter;

  archiveRoot.libraryDir.createSync();

  final libraryLists = await _getExportLibraryLists(db, adapter: exportAdapter);

  await exportLibraryMetadata(archiveRoot, libraryLists);

  for (final (i, libraryList) in libraryLists.indexed) {
    yield* exportLibraryList(
      db,
      archiveRoot,
      libraryList,
      i + 1,
      libraryLists.length,
      adapter: exportAdapter,
    );
  }
}

/// Exports a single library list into json files in the given directory.
///
/// Streams back the number of chunks that have been exported so far.
Stream<ArchiveV2StreamEvent> exportLibraryList(
  final DatabaseExecutor db,
  final Directory archiveRoot,
  final ArchiveV2ExportLibraryList libraryList,
  final int index,
  final int total, {
  final ArchiveV2ExportAdapter? adapter,
}) async* {
  final exportAdapter = adapter ?? latestSchemaExportAdapter;
  final listName = libraryList.metadata.name;
  final int chunkCount = (libraryList.totalCount / libraryListChunkSize).ceil();

  archiveRoot.libraryListDir(listName).createSync();

  for (int i = 0; i < chunkCount; i++) {
    final archiveEntries = await exportAdapter.libraryListGetEntries(
      db: db,
      listName: listName,
      page: i,
    );

    archiveRoot.libraryListChunkFile(listName, i)
      ..createSync()
      ..writeAsStringSync(
        jsonEncode(archiveEntries.map((final e) => e.toJson()).toList()),
      );

    yield ArchiveV2StreamEvent(
      type: 'library',
      progress: index,
      total: total,
      name: listName,
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
  final chunkFiles = libraryListDir.listSync().whereType<File>().sortedBy(
    (final file) =>
        int.tryParse(
          file.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), ''),
        ) ??
        0,
  );

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

    final entryExistenceChecks = await db.jadbFilterWordIds(
      entries
          .where((final e) => e.jmdictEntryId != null)
          .map((final e) => e.jmdictEntryId!),
    );

    final existingEntries = entries.where((final e) {
      if (e.jmdictEntryId != null) {
        final result = entryExistenceChecks.contains(e.jmdictEntryId);
        if (!result) {
          print(
            'Warning: Entry with jmdictEntryId ${e.jmdictEntryId} does not exist in the database. Skipping this entry.',
          );
        }
        return result;
      } else {
        // If the entry does not have a jmdictEntryId, we assume it exists.
        return true;
      }
    }).toList();

    final result = await db.libraryListInsertEntries(
      libraryListName,
      existingEntries,
    );
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
