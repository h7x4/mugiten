import 'dart:math';

import 'package:mugiten/database/history/table_names.dart';
import 'package:sqflite/sqlite_api.dart';

class HistoryEntry {
  int id;
  final String? kanji;
  final String? word;
  final DateTime lastTimestamp;
  final int? timestampCount;

  /// Whether this item is a kanji search or a word search
  bool get isKanji => word == null;

  HistoryEntry.withKanji({
    required this.id,
    required this.kanji,
    required this.lastTimestamp,
    this.timestampCount,
  })  : word = null,
        assert(
          kanji!.runes.length == 1,
          'Kanji must be a single character',
        );

  HistoryEntry.withWord({
    required this.id,
    required this.word,
    required this.lastTimestamp,
    this.timestampCount,
  })  : kanji = null,
        assert(
          word == word!.trim(),
          'Word must not contain leading or trailing whitespace',
        );

  /// Reconstruct a HistoryEntry object with data from the database
  /// This is specifically intended for the historyEntryOrderedByTimestamp
  /// view, but it can also be used with custom searches as long as it
  /// contains the following attributes:
  ///
  /// - entryId
  /// - timestamp
  /// - word?
  /// - kanji?
  factory HistoryEntry.fromDBMap(Map<String, Object?> dbObject) =>
      dbObject['word'] != null
          ? HistoryEntry.withWord(
              id: dbObject['entryId']! as int,
              word: dbObject['word']! as String,
              lastTimestamp: DateTime.fromMillisecondsSinceEpoch(
                dbObject['timestamp']! as int,
              ),
              timestampCount: dbObject.containsKey('timestampCount')
                  ? dbObject['timestampCount']! as int
                  : null,
            )
          : HistoryEntry.withKanji(
              id: dbObject['entryId']! as int,
              kanji: dbObject['kanji']! as String,
              lastTimestamp: DateTime.fromMillisecondsSinceEpoch(
                dbObject['timestamp']! as int,
              ),
              timestampCount: dbObject.containsKey('timestampCount')
                  ? dbObject['timestampCount']! as int
                  : null,
            );

  // TODO: There is a lot in common with
  //   insertKanji,
  //   insertWord,
  //   insertJsonEntry,
  //   insertJsonEntries,
  // The commonalities should be factored into a helper function

  /// Insert a kanji history entry into the database.
  /// If it already exists, only a timestamp will be added
  static Future<HistoryEntry> insertKanji({
    required Database db,
    required String kanji,
  }) =>
      db.transaction((txn) async {
        final DateTime timestamp = DateTime.now();
        late final int id;

        final existingEntry = await txn.query(
          HistoryTableNames.historyEntryKanji,
          where: 'kanji = ?',
          whereArgs: [kanji],
        );

        if (existingEntry.isNotEmpty) {
          // Retrieve entry record id, and add a timestamp.
          id = existingEntry.first['entryId']! as int;
          await txn.insert(HistoryTableNames.historyEntryTimestamp, {
            'entryId': id,
            'timestamp': timestamp.millisecondsSinceEpoch,
          });
        } else {
          // Create new record, and add a timestamp.
          id = await txn.insert(
            HistoryTableNames.historyEntry,
            {},
            nullColumnHack: 'id',
          );
          final Batch b = txn.batch();

          b.insert(HistoryTableNames.historyEntryTimestamp, {
            'entryId': id,
            'timestamp': timestamp.millisecondsSinceEpoch,
          });
          b.insert(HistoryTableNames.historyEntryKanji, {
            'entryId': id,
            'kanji': kanji,
          });
          await b.commit();
        }

        return HistoryEntry.withKanji(
          id: id,
          kanji: kanji,
          lastTimestamp: timestamp,
        );
      });

  /// Insert a word history entry into the database.
  /// If it already exists, only a timestamp will be added
  static Future<HistoryEntry> insertWord({
    required Database db,
    required String word,
    String? language,
  }) =>
      db.transaction((txn) async {
        final DateTime timestamp = DateTime.now();
        late final int id;

        final existingEntry = await txn.query(
          HistoryTableNames.historyEntryWord,
          where: 'word = ?',
          whereArgs: [word],
        );

        if (existingEntry.isNotEmpty) {
          // Retrieve entry record id, and add a timestamp.
          id = existingEntry.first['entryId']! as int;
          await txn.insert(HistoryTableNames.historyEntryTimestamp, {
            'entryId': id,
            'timestamp': timestamp.millisecondsSinceEpoch,
          });
        } else {
          id = await txn.insert(
            HistoryTableNames.historyEntry,
            {},
            nullColumnHack: 'id',
          );
          final Batch b = txn.batch();

          b.insert(HistoryTableNames.historyEntryTimestamp, {
            'entryId': id,
            'timestamp': timestamp.millisecondsSinceEpoch,
          });
          b.insert(HistoryTableNames.historyEntryWord, {
            'entryId': id,
            'word': word,
            'language': {
              null: null,
              'japanese': 'j',
              'english': 'e',
            }[language]
          });
          await b.commit();
        }

        return HistoryEntry.withWord(
          id: id,
          word: word,
          lastTimestamp: timestamp,
        );
      });

  /// All recorded timestamps for this specific HistoryEntry
  /// sorted in descending order.
  Future<List<DateTime>> timestamps(DatabaseExecutor db) async {
    final timestamps = await db.query(
      HistoryTableNames.historyEntryTimestamp,
      where: 'entryId = ?',
      whereArgs: [id],
      orderBy: 'timestamp DESC',
    );

    return timestamps
        .map((t) => DateTime.fromMillisecondsSinceEpoch(t['timestamp']! as int))
        .toList();
  }

  /// Export to json for archival reasons
  /// Combined with [insertJsonEntry], this makes up functionality for exporting
  /// and importing data from the app.
  Future<Map<String, Object?>> toJson(DatabaseExecutor db) async {
    final rawTimestamps = await timestamps(db);
    final timestamps_ =
        rawTimestamps.map((ts) => ts.millisecondsSinceEpoch).toList();

    return {
      'word': word,
      'kanji': kanji,
      'timestamps': timestamps_,
    };
  }

  /// Insert archived json entry into database if it doesn't exist there already.
  /// Combined with [toJson], this makes up functionality for exporting and
  /// importing data from the app.
  static Future<HistoryEntry> insertJsonEntry(
    Database db,
    Map<String, Object?> json,
  ) async =>
      db.transaction((txn) async {
        final b = txn.batch();
        final bool isKanji = json['word'] == null;
        final existingEntry = isKanji
            ? await txn.query(
                HistoryTableNames.historyEntryKanji,
                where: 'kanji = ?',
                whereArgs: [json['kanji']! as String],
              )
            : await txn.query(
                HistoryTableNames.historyEntryWord,
                where: 'word = ?',
                whereArgs: [json['word']! as String],
              );

        late final int id;
        if (existingEntry.isEmpty) {
          id = await txn.insert(
            HistoryTableNames.historyEntry,
            {},
            nullColumnHack: 'id',
          );
          if (isKanji) {
            b.insert(HistoryTableNames.historyEntryKanji, {
              'entryId': id,
              'kanji': json['kanji']! as String,
            });
          } else {
            b.insert(HistoryTableNames.historyEntryWord, {
              'entryId': id,
              'word': json['word']! as String,
            });
          }
        } else {
          id = existingEntry.first['entryId']! as int;
        }
        final List<int> timestamps =
            (json['timestamps']! as List).map((ts) => ts as int).toList();
        for (final timestamp in timestamps) {
          b.insert(
            HistoryTableNames.historyEntryTimestamp,
            {
              'entryId': id,
              'timestamp': timestamp,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        await b.commit();

        return isKanji
            ? HistoryEntry.withKanji(
                id: id,
                kanji: json['kanji']! as String,
                lastTimestamp:
                    DateTime.fromMillisecondsSinceEpoch(timestamps.reduce(max)),
              )
            : HistoryEntry.withWord(
                id: id,
                word: json['word']! as String,
                lastTimestamp:
                    DateTime.fromMillisecondsSinceEpoch(timestamps.reduce(max)),
              );
      });

  /// An efficient implementation of [insertJsonEntry] for multiple
  /// entries.
  ///
  /// This assumes that there are no duplicates within the elements
  /// in the json.
  static Future<List<HistoryEntry>> insertJsonEntries(
    Database db,
    List<Map<String, Object?>> json,
  ) =>
      db.transaction((txn) async {
        final b = txn.batch();
        final List<HistoryEntry> entries = [];
        for (final jsonObject in json) {
          final bool isKanji = jsonObject['word'] == null;
          final existingEntry = isKanji
              ? await txn.query(
                  HistoryTableNames.historyEntryKanji,
                  where: 'kanji = ?',
                  whereArgs: [jsonObject['kanji']! as String],
                )
              : await txn.query(
                  HistoryTableNames.historyEntryWord,
                  where: 'word = ?',
                  whereArgs: [jsonObject['word']! as String],
                );

          late final int id;
          if (existingEntry.isEmpty) {
            id = await txn.insert(
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
              .map((ts) => ts as int)
              .toList();
          for (final timestamp in timestamps) {
            b.insert(
              HistoryTableNames.historyEntryTimestamp,
              {
                'entryId': id,
                'timestamp': timestamp,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          entries.add(
            isKanji
                ? HistoryEntry.withKanji(
                    id: id,
                    kanji: jsonObject['kanji']! as String,
                    lastTimestamp: DateTime.fromMillisecondsSinceEpoch(
                      timestamps.reduce(max),
                    ),
                  )
                : HistoryEntry.withWord(
                    id: id,
                    word: jsonObject['word']! as String,
                    lastTimestamp: DateTime.fromMillisecondsSinceEpoch(
                      timestamps.reduce(max),
                    ),
                  ),
          );
        }

        await b.commit();
        return entries;
      });

  static Future<int> amountOfEntries(DatabaseExecutor db) async {
    final query = await db.query(
      HistoryTableNames.historyEntry,
      columns: ['COUNT(*) AS count'],
    );
    return query.first['count']! as int;
  }

  static Future<List<HistoryEntry>> entriesFromDb(
    DatabaseExecutor db, {
    int? page,
    int? pageSize,
  }) async {
    assert(page == null || page >= 0);
    assert(pageSize == null || pageSize > 0);
    assert(
      pageSize != null || page == null,
      'pageSize must be provided if page is provided',
    );

    final result = await db.query(
      HistoryTableNames.historyEntryOrderedByTimestamp,
      limit: pageSize,
      offset: page != null && pageSize != null ? page * pageSize : null,
    );

    return result.map((e) => HistoryEntry.fromDBMap(e)).toList();
  }

  Future<void> delete(DatabaseExecutor db) => db.delete(
        HistoryTableNames.historyEntry,
        where: 'id = ?',
        whereArgs: [id],
      );
}
