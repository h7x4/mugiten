part of './format.dart';

class ArchiveV2HistoryEntry {
  final int id;
  final List<ArchiveV2HistorySearchInstance> searchInstances;

  // TODO: add information about whether the search had zero, one or more results.
  // TODO: add information about search mode.

  final String? word;
  final String? kanji;

  const ArchiveV2HistoryEntry({
    required this.id,
    required this.searchInstances,
    this.word,
    this.kanji,
  }) : assert(
         word != null || kanji != null,
         'At least one of word or kanji must be non-null',
       );

  factory ArchiveV2HistoryEntry.fromHistoryEntry(final HistoryEntry entry) {
    return ArchiveV2HistoryEntry(
      id: entry.id,
      searchInstances: entry.timestamps
          .map(
            (final timestamp) => ArchiveV2HistorySearchInstance(
              timestamp: timestamp,
              mediaName: null,
            ),
          )
          .toList(),
      word: entry.word,
      kanji: entry.kanji,
    );
  }

  HistoryEntry toHistoryEntry() {
    return HistoryEntry(
      id: id,
      timestamps: searchInstances.map((final si) => si.timestamp).toList(),
      word: word,
      kanji: kanji,
    );
  }

  factory ArchiveV2HistoryEntry.fromJson(final Map<String, Object?> json) {
    return ArchiveV2HistoryEntry(
      id: json['id'] as int,
      searchInstances: (json['searchInstances'] as List<dynamic>)
          .map((final si) => si as Map<String, Object?>)
          .map(
            (final si) => ArchiveV2HistorySearchInstance(
              timestamp: DateTime.parse(si['timestamp'] as String),
              mediaName: si['mediaName'] as String?,
            ),
          )
          .toList(),
      word: json['word'] as String?,
      kanji: json['kanji'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'searchInstances': searchInstances
          .map(
            (final instance) => {
              'timestamp': instance.timestamp.toIso8601String(),
              'mediaName': instance.mediaName,
            },
          )
          .toList(),
      'word': word,
      'kanji': kanji,
    };
  }
}

class ArchiveV2HistorySearchInstance {
  final DateTime timestamp;
  final String? mediaName;

  const ArchiveV2HistorySearchInstance({
    required this.timestamp,
    this.mediaName,
  });
}

/// Calculate the total number of chunks needed to export the history,
/// needed for progress tracking during export.
Future<int> exportHistoryChunkCount(final DatabaseExecutor db) async =>
    (await db.historyEntryAmount() / historyChunkSize).ceil();

/// Exports the history into json files in the given directory.
///
/// Streams back the number of chunks that have been exported so far.
Stream<ArchiveV2StreamEvent> exportHistory(
  final DatabaseExecutor db,
  final Directory archiveRoot,
) async* {
  final int chunkCount = await exportHistoryChunkCount(db);

  archiveRoot.historyDir.createSync();

  for (int i = 0; i < chunkCount; i++) {
    final List<Map<String, Object?>> jsonEntries =
        (await db.historyEntryGetAll(page: i, pageSize: historyChunkSize))
            .map(ArchiveV2HistoryEntry.fromHistoryEntry)
            .map((final e) => e.toJson())
            .toList();

    archiveRoot.historyChunkFile(i)
      ..createSync()
      ..writeAsStringSync(jsonEncode(jsonEntries));

    yield ArchiveV2StreamEvent(
      type: 'history',
      progress: i + 1,
      total: chunkCount,
    );
  }
}

Stream<ArchiveV2StreamEvent> importHistory(
  final DatabaseExecutor db,
  final Directory archiveRoot,
) async* {
  final int chunkCount = archiveRoot.historyChunkCount;

  for (int i = 0; i < chunkCount; i++) {
    final List<dynamic> jsonEntries =
        jsonDecode(archiveRoot.historyChunkFile(i).readAsStringSync())
            as List<dynamic>;

    final historyEntries = jsonEntries
        .map((final e) => e as Map<String, Object?>)
        .map(ArchiveV2HistoryEntry.fromJson)
        .map((final e) => e.toHistoryEntry());

    await db.historyEntryInsertEntries(historyEntries);

    yield ArchiveV2StreamEvent(
      type: 'history',
      progress: i + 1,
      total: chunkCount,
    );
  }
}
