part of './format.dart';

class ArchiveV1HistoryEntry {
  final int id;
  final List<DateTime> timestamps;

  final String? word;
  final String? kanji;

  const ArchiveV1HistoryEntry({
    required this.id,
    required this.timestamps,
    this.word,
    this.kanji,
  }) : assert(
         word != null || kanji != null,
         'At least one of word or kanji must be non-null',
       );

  factory ArchiveV1HistoryEntry.fromHistoryEntry(final HistoryEntry entry) {
    return ArchiveV1HistoryEntry(
      id: entry.id,
      timestamps: entry.timestamps,
      word: entry.word,
      kanji: entry.kanji,
    );
  }

  factory ArchiveV1HistoryEntry.fromJson(final Map<String, Object?> json) {
    return ArchiveV1HistoryEntry(
      id: json['id'] as int,
      timestamps: (json['timestamps'] as List<dynamic>)
          .map((final ts) => DateTime.fromMillisecondsSinceEpoch(ts as int))
          .toList(),
      word: json['word'] as String?,
      kanji: json['kanji'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'timestamps': timestamps
        .map((final ts) => ts.millisecondsSinceEpoch)
        .toList(),
    'word': word,
    'kanji': kanji,
  };
}

Future<void> exportHistoryTo(
  final DatabaseExecutor db,
  final Directory dir,
) async {
  final file = dir.historyFile..createSync();

  final List<Map<String, Object?>> jsonEntries = (await db.historyEntryGetAll())
      .map(ArchiveV1HistoryEntry.fromHistoryEntry)
      .map((final e) => e.toJson())
      .toList();

  file.writeAsStringSync(jsonEncode(jsonEntries));
}

Future<void> importHistoryFrom(final Database db, final File file) async {
  final String content = file.readAsStringSync();
  final List<ArchiveV1HistoryEntry> entries = (jsonDecode(content) as List)
      .map((final h) => h as Map<String, Object?>)
      .map(ArchiveV1HistoryEntry.fromJson)
      .toList();
  await db.transaction(
    (final txn) => historyEntryInsertMany(txn, entries),
  );
}

Future<void> historyEntryInsertMany(
  final DatabaseExecutor db,
  final Iterable<ArchiveV1HistoryEntry> entries,
) async {
  final b = db.batch();
  for (final entry in entries) {
    final bool isKanji = entry.word == null;
    final existingEntry = isKanji
        ? await db.query(
            HistoryTableNames.historyEntryKanji,
            where: 'kanji = ?',
            whereArgs: [entry.kanji],
          )
        : await db.query(
            HistoryTableNames.historyEntryWord,
            where: 'word = ?',
            whereArgs: [entry.word],
          );

    late final int id;
    if (existingEntry.isEmpty) {
      id = await db.insert(
        HistoryTableNames.historyEntry,
        {},
        nullColumnHack: 'id',
      );
      if (isKanji) {
        b.insert(HistoryTableNames.historyEntryKanji, {
          'entryId': id,
          'kanji': entry.kanji,
        });
      } else {
        b.insert(HistoryTableNames.historyEntryWord, {
          'entryId': id,
          'word': entry.word,
        });
      }
    } else {
      id = existingEntry.first['entryId']! as int;
    }
    final List<int> timestamps = entry.timestamps
        .map((final ts) => ts.millisecondsSinceEpoch)
        .toList();
    for (final timestamp in timestamps) {
      b.insert(
        HistoryTableNames.historyEntryTimestamp,
        {'entryId': id, 'timestamp': timestamp},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  await b.commit();
}
