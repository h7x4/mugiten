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
}

Future<void> exportHistoryTo(
  final DatabaseExecutor db,
  final Directory dir,
) async {
  final file = dir.historyFile..createSync();

  final List<Map<String, Object?>> jsonEntries = (await db.historyEntryGetAll())
      .map((final e) => e.toJson())
      .toList();

  file.writeAsStringSync(jsonEncode(jsonEntries));
}

Future<void> importHistoryFrom(final Database db, final File file) async {
  final String content = file.readAsStringSync();
  final List<Map<String, Object?>> json = (jsonDecode(content) as List)
      .map((final h) => h as Map<String, Object?>)
      .toList();
  // log('Importing ${json.length} entries from ${file.path}');
  await db.transaction(
    (final txn) => historyEntryInsertManyFromJson(txn, json),
  );
}

Future<void> historyEntryInsertManyFromJson(
  final DatabaseExecutor db,
  final Iterable<Map<String, Object?>> json,
) async {
  final b = db.batch();
  for (final jsonObject in json) {
    final bool isKanji = jsonObject['word'] == null;
    final existingEntry = isKanji
        ? await db.query(
            HistoryTableNames.historyEntryKanji,
            where: 'kanji = ?',
            whereArgs: [jsonObject['kanji']! as String],
          )
        : await db.query(
            HistoryTableNames.historyEntryWord,
            where: 'word = ?',
            whereArgs: [jsonObject['word']! as String],
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
          'kanji': jsonObject['kanji']! as String,
        });
      } else {
        b.insert(HistoryTableNames.historyEntryWord, {
          'entryId': id,
          'word': jsonObject['word']! as String,
        });
      }
    } else {
      id = existingEntry.first['entryId']! as int;
    }
    final List<int> timestamps = (jsonObject['timestamps']! as List)
        .map((final ts) => ts as int)
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
