import 'package:jadb/models/kanji_search/kanji_search_result.dart';
import 'package:jadb/models/word_search/word_search_result.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/database/history/table_names.dart';
import 'package:sqflite/sqlite_api.dart';

extension HistoryEntryExt on DatabaseExecutor {
  // Query

  Future<HistoryEntry?> historyEntryGetWord(
    String word,
    // bool includeSearchResult = false,
  ) async {
    assert(word.isNotEmpty, 'Word must not be empty');

    final result = await query(
      HistoryTableNames.historyEntryWord,
      where: 'word = ?',
      whereArgs: [word],
    );

    if (result.isEmpty) {
      return null;
    }

    final entryId = result.first['entryId']! as int;
    final language = result.first['language'] as String?;

    final List<DateTime> timestamps =
        (await query(
              HistoryTableNames.historyEntryTimestamp,
              where: 'entryId = ?',
              whereArgs: [entryId],
              orderBy: 'timestamp DESC',
            ))
            .map(
              (e) =>
                  DateTime.fromMillisecondsSinceEpoch(e['timestamp']! as int),
            )
            .toList();

    // TODO: join with search result(s) if matching exactly one, or single search result

    return HistoryEntry(
      id: entryId,
      timestamps: timestamps,
      word: word,
      language: language,
      wordSearchResult: null,
    );
  }

  Future<HistoryEntry?> historyEntryGetKanji(
    String kanji, {
    bool includeSearchResult = false,
  }) async {
    assert(kanji.runes.length == 1, 'Kanji must be a single character');

    final result = await query(
      HistoryTableNames.historyEntryKanji,
      where: 'kanji = ?',
      whereArgs: [kanji],
    );

    if (result.isEmpty) {
      return null;
    }

    final entryId = result.first['entryId']! as int;

    final List<DateTime> timestamps =
        (await query(
              HistoryTableNames.historyEntryTimestamp,
              where: 'entryId = ?',
              whereArgs: [entryId],
              orderBy: 'timestamp DESC',
            ))
            .map(
              (e) =>
                  DateTime.fromMillisecondsSinceEpoch(e['timestamp']! as int),
            )
            .toList();

    final KanjiSearchResult? kanjiSearchResult = includeSearchResult
        ? await jadbSearchKanji(kanji)
        : null;

    return HistoryEntry(
      id: entryId,
      timestamps: timestamps,
      kanji: kanji,
      kanjiSearchResult: kanjiSearchResult,
    );
  }

  Future<List<HistoryEntry>> historyEntryGetAll({
    int? page,
    int? pageSize,
    // TODO: implement join against jadb
    // bool includeSearchResult = false,
  }) async {
    assert(page == null || page >= 0);
    assert(pageSize == null || pageSize > 0);
    assert(
      pageSize != null || page == null,
      'pageSize must be provided if page is provided',
    );

    final result = await rawQuery(
      '''
        SELECT
          *,
          GROUP_CONCAT("${HistoryTableNames.historyEntryTimestamp}"."timestamp") AS "timestamps"
        FROM "${HistoryTableNames.historyEntryOrderedByTimestamp}"
        LEFT JOIN "${HistoryTableNames.historyEntryTimestamp}" USING ("entryId")
        GROUP BY "${HistoryTableNames.historyEntryOrderedByTimestamp}"."entryId"
        ORDER BY "${HistoryTableNames.historyEntryOrderedByTimestamp}"."timestamp" DESC
        ${pageSize != null ? 'LIMIT ?' : ''}
        ${page != null ? 'OFFSET ?' : ''}
      ''',
      [?pageSize, if (page != null) page * pageSize!],
    );

    final List<HistoryEntry> entries = result.map((e) {
      final timestamps = (e['timestamps'] as String)
          .split(',')
          .map((ts) => DateTime.fromMillisecondsSinceEpoch(int.parse(ts)))
          .toList();

      if (e['kanji'] != null) {
        return HistoryEntry(
          id: e['entryId']! as int,
          timestamps: timestamps,
          kanji: e['kanji'] as String,
        );
      } else {
        return HistoryEntry(
          id: e['entryId']! as int,
          timestamps: timestamps,
          word: e['word'] as String,
        );
      }
    }).toList();

    return entries;
  }

  Future<int> historyEntryAmount({
    /// Whether to ignore duplicate searches
    bool unique = true,
  }) async {
    late final int count;

    if (unique) {
      final result = await query(
        HistoryTableNames.historyEntry,
        columns: ['COUNT(*) AS count'],
      );
      count = result.firstOrNull?['count'] as int? ?? 0;
    } else {
      final result = await rawQuery('''
          SELECT COUNT(*) AS count
          FROM "${HistoryTableNames.historyEntryTimestamp}"
        ''');
      count = result.firstOrNull?['count'] as int? ?? 0;
    }

    return count;
  }

  // Modification

  Future<void> historyEntryInsertKanji(String kanji) async {
    final DateTime timestamp = DateTime.now();

    final existingEntry = await query(
      HistoryTableNames.historyEntryKanji,
      where: 'kanji = ?',
      whereArgs: [kanji],
    );

    late final int id;
    if (existingEntry.isNotEmpty) {
      // Retrieve entry record id, and add a timestamp.
      id = existingEntry.first['entryId']! as int;
    } else {
      id = await insert(
        HistoryTableNames.historyEntry,
        {},
        nullColumnHack: 'id',
      );
      await insert(HistoryTableNames.historyEntryKanji, {
        'entryId': id,
        'kanji': kanji,
      });
    }

    await insert(
      HistoryTableNames.historyEntryTimestamp,
      {'entryId': id, 'timestamp': timestamp.millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> historyEntryInsertWord(String word, {String? language}) async {
    final DateTime timestamp = DateTime.now();

    final existingEntry = await query(
      HistoryTableNames.historyEntryWord,
      where: 'word = ?',
      whereArgs: [word],
    );

    late final int id;
    if (existingEntry.isNotEmpty) {
      // Retrieve entry record id, and add a timestamp.
      id = existingEntry.first['entryId']! as int;
    } else {
      id = await insert(
        HistoryTableNames.historyEntry,
        {},
        nullColumnHack: 'id',
      );
      await insert(HistoryTableNames.historyEntryWord, {
        'entryId': id,
        'word': word,
        // TODO: use an enum?
        'language': {null: null, 'japanese': 'j', 'english': 'e'}[language],
      });
    }

    await insert(
      HistoryTableNames.historyEntryTimestamp,
      {'entryId': id, 'timestamp': timestamp.millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> historyEntryDelete(int entryId) async {
    await delete(
      HistoryTableNames.historyEntryTimestamp,
      where: 'entryId = ?',
      whereArgs: [entryId],
    );

    await delete(
      HistoryTableNames.historyEntryKanji,
      where: 'entryId = ?',
      whereArgs: [entryId],
    );

    await delete(
      HistoryTableNames.historyEntryWord,
      where: 'entryId = ?',
      whereArgs: [entryId],
    );

    final result = await delete(
      HistoryTableNames.historyEntry,
      where: 'id = ?',
      whereArgs: [entryId],
    );

    return result > 0;
  }

  Future<bool> historyEntryDeleteTimestamp(
    int entryId,
    DateTime timestamp,
  ) async {
    final timestampCount = await query(
      HistoryTableNames.historyEntryTimestamp,
      columns: ['COUNT(*) AS count'],
      where: 'entryId = ?',
      whereArgs: [entryId],
    );

    if (timestampCount.isEmpty) {
      return false;
    }

    final result = await delete(
      HistoryTableNames.historyEntryTimestamp,
      where: 'entryId = ? AND timestamp = ?',
      whereArgs: [entryId, timestamp.millisecondsSinceEpoch],
    );

    if (result == 0) {
      return false; // No timestamp was deleted
    }

    // If this is the last timestamp, delete the entry
    if (timestampCount.isEmpty || timestampCount.first['count']! as int <= 1) {
      return await historyEntryDelete(entryId);
    }

    return true;
  }

  Future<void> historyEntryInsertManyFromJson(
    List<Map<String, Object?>> json,
  ) async {
    final b = batch();
    for (final jsonObject in json) {
      final bool isKanji = jsonObject['word'] == null;
      final existingEntry = isKanji
          ? await query(
              HistoryTableNames.historyEntryKanji,
              where: 'kanji = ?',
              whereArgs: [jsonObject['kanji']! as String],
            )
          : await query(
              HistoryTableNames.historyEntryWord,
              where: 'word = ?',
              whereArgs: [jsonObject['word']! as String],
            );

      late final int id;
      if (existingEntry.isEmpty) {
        id = await insert(
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
          {'entryId': id, 'timestamp': timestamp},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    await b.commit();
  }
}

class HistoryEntry {
  final int id;
  final List<DateTime> timestamps;

  final String? word;
  final String? language;
  final WordSearchResult? wordSearchResult;

  final String? kanji;
  final KanjiSearchResult? kanjiSearchResult;

  HistoryEntry({
    required this.id,
    required this.timestamps,
    this.word,
    this.language,
    this.wordSearchResult,
    this.kanji,
    this.kanjiSearchResult,
  }) : assert(
         (word != null && kanji == null) || (word == null && kanji != null),
         'HistoryEntry must have either a word or a kanji, but not both',
       ),
       assert(
         (language == null || word != null),
         'If language is provided, word must not be null',
       ),
       assert(
         (kanjiSearchResult == null || kanji != null),
         'If kanjiSearchResult is provided, kanji must not be null',
       ),
       assert(
         (wordSearchResult == null || word != null),
         'If wordSearchResult is provided, word must not be null',
       ),
       assert(
         kanji == null || kanji.runes.length == 1,
         'Kanji must be a single character',
       ),
       // TODO: This has not always been the case, so we should add a migration
       //       or something to clean up the data.
       // assert(
       //   word == null || word == word.trim(),
       //   'Word must not contain leading or trailing whitespace',
       // ),
       assert(timestamps.isNotEmpty, 'Timestamps must not be empty');

  bool get isKanji => word == null;
  int get timestampCount => timestamps.length;
  DateTime get lastTimestamp => timestamps.isNotEmpty
      ? timestamps.reduce((a, b) => a.isAfter(b) ? a : b)
      : DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, Object?> toJson() {
    return {
      'word': word,
      'kanji': kanji,
      'timestamps': timestamps.map((ts) => ts.millisecondsSinceEpoch).toList(),
    };
  }
}
