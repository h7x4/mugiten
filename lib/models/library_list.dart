import 'package:collection/collection.dart';
import 'package:jadb/models/kanji_search/kanji_search_result.dart';
import 'package:jadb/models/word_search/word_search_result.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/database/library_list/table_names.dart';
import 'package:sqflite/sqlite_api.dart';

extension LibraryListExt on DatabaseExecutor {
  // Query

  Future<List<LibraryList>> libraryListGetLists({
    int? page,
    int? pageSize,
  }) async {
    final result = await rawQuery(
      '''
        SELECT
          "name",
          (
            SELECT COUNT(*)
            FROM "${LibraryListTableNames.libraryListEntry}"
            WHERE "listName" = "name"
          ) AS "count"
        FROM "${LibraryListTableNames.libraryListOrdered}"
        ${pageSize != null ? 'LIMIT ?' : ''}
        ${page != null ? 'OFFSET ?' : ''}
      ''',
      [?pageSize, if (page != null) page * pageSize!],
    );

    //   COUNT(*) AS "count"
    // LEFT JOIN "${LibraryListTableNames.libraryListEntry}"

    return result
        .map(
          (row) => LibraryList(
            name: row['name'] as String,
            totalCount: row['count'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<LibraryList?> libraryListGetList(String listName) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    final result = await rawQuery(
      '''
        SELECT
          "name",
          (
            SELECT COUNT(*)
            FROM "${LibraryListTableNames.libraryListEntry}"
            WHERE "listName" = "name"
          ) AS "count"
        FROM "${LibraryListTableNames.libraryListOrdered}"
        WHERE "name" = ?
      ''',
      [listName],
    );

    if (result.isEmpty) {
      return null;
    }

    return LibraryList(
      name: result.first['name'] as String,
      totalCount: result.first['count'] as int? ?? 0,
    );
  }

  Future<LibraryListPage?> libraryListGetListEntries(
    String listName, {
    int? page,
    int? pageSize,
    bool includeSearchResult = false,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(
      page == null || page >= 0,
      'Page must be null or a non-negative integer.',
    );
    assert(
      pageSize == null || pageSize > 0,
      'Page size must be null or a positive integer.',
    );
    assert(
      page == null || pageSize != null,
      'If page is provided, pageSize must also be provided.',
    );

    final list = await libraryListGetList(listName);

    if (list == null) {
      return null;
    }

    final entries = await rawQuery(
      '''
        WITH RECURSIVE
          "RecursionTable"(
            "jmdictEntryId",
            "kanji",
            "lastModified"
          ) AS (
            SELECT
              "jmdictEntryId",
              "kanji",
              "lastModified"
            FROM "${LibraryListTableNames.libraryListEntry}"
            WHERE
              "listName" = ?
              AND "prevEntryJmdictEntryId" IS NULL
              AND "prevEntryKanji" IS NULL

            UNION ALL

            SELECT
              "R"."jmdictEntryId",
              "R"."kanji",
              "R"."lastModified"
            FROM "${LibraryListTableNames.libraryListEntry}" AS "R", "RecursionTable"
            WHERE
              "R"."listName" = ?
              AND ("R"."prevEntryJmdictEntryId" = "RecursionTable"."jmdictEntryId"
                OR "R"."prevEntryKanji" = "RecursionTable"."kanji")
          )
        SELECT
          "jmdictEntryId",
          "kanji",
          "lastModified"
        FROM "RecursionTable"
        ${pageSize != null ? 'LIMIT ?' : ''}
        ${page != null ? 'OFFSET ?' : ''}

      ''',
      [
        listName,
        listName,
        ?pageSize,
        if (page != null) page * pageSize!,
      ],
    );

    Map<int, WordSearchResult>? wordResults;
    Map<String, KanjiSearchResult>? kanjiResults;
    if (includeSearchResult) {
      final wordResultJmdictIds = entries
          .where((e) => e['jmdictEntryId'] != null)
          .map((e) => e['jmdictEntryId'] as int)
          .toSet();

      wordResults = await jadbGetManyWordsByIds(wordResultJmdictIds);

      final kanjiResultKanjis = entries
          .where((e) => e['kanji'] != null)
          .map((e) => e['kanji'] as String)
          .toSet();

      kanjiResults = await jadbGetManyKanji(kanjiResultKanjis);
    }

    final result = entries.map((entry) {
      if (entry['jmdictEntryId'] != null) {
        return LibraryListEntry.fromJmdictId(
          jmdictEntryId: entry['jmdictEntryId'] as int,
          wordSearchResult: wordResults?[entry['jmdictEntryId'] as int],
          lastModified: DateTime.fromMillisecondsSinceEpoch(
            entry['lastModified'] as int,
          ),
        );
      } else if (entry['kanji'] != null) {
        return LibraryListEntry.fromKanji(
          kanji: entry['kanji'] as String,
          kanjiSearchResult: kanjiResults?[entry['kanji'] as String],
          lastModified: DateTime.fromMillisecondsSinceEpoch(
            entry['lastModified'] as int,
          ),
        );
      } else {
        throw ArgumentError(
          'Library list entry must have either jmdictEntryId or kanji.',
        );
      }
    }).toList();

    return LibraryListPage(
      name: listName,
      totalCount: list.totalCount,
      entries: result,
    );
  }

  Future<Map<String, bool>> libraryListAllListsContain({
    int? jmdictEntryId,
    String? kanji,
  }) async {
    final result = await rawQuery(
      '''
        SELECT
          "name",
          EXISTS(
            SELECT * FROM "${LibraryListTableNames.libraryListEntry}"
            WHERE "listName" = "name"
              AND ("jmdictEntryId" = ? OR "kanji" = ?)
          ) AS "exists"
        FROM "${LibraryListTableNames.libraryListOrdered}"
      ''',
      [jmdictEntryId, kanji],
    );

    return {
      for (final row in result)
        row['name'] as String: (row['exists'] as int) == 1,
    };
  }

  Future<bool> libraryListListContains(
    String listName, {
    int? jmdictEntryId,
    String? kanji,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    final result = await rawQuery(
      '''
        SELECT EXISTS(
          SELECT * FROM "${LibraryListTableNames.libraryListEntry}"
          WHERE "listName" = ?
            AND ("jmdictEntryId" = ? OR "kanji" = ?)
        ) AS "exists"
      ''',
      [listName, jmdictEntryId, kanji],
    );

    return (result.firstOrNull?['exists'] as int? ?? 0) == 1;
  }

  Future<int> libraryListAmount() async {
    final result = await query(
      LibraryListTableNames.libraryList,
      columns: ['COUNT(*) AS count'],
    );

    return result.firstOrNull?['count'] as int? ?? 0;
  }

  Future<bool> libraryListExists(String listName) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    final result = await rawQuery(
      '''
        SELECT EXISTS(
          SELECT * FROM "${LibraryListTableNames.libraryList}"
          WHERE "name" = ?
        ) AS "exists"
      ''',
      [listName],
    );

    return (result.firstOrNull?['exists'] as int? ?? 0) == 1;
  }

  // Modification

  /// Inserts a new library list into the database.
  Future<bool> libraryListInsertList(
    String listName, {
    bool existsOk = true,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    if (!existsOk && await libraryListExists(listName)) {
      return false;
    }

    // // This is ok, because "favourites" should always exist.
    final prevList = (await libraryListGetLists()).last;
    await insert(LibraryListTableNames.libraryList, {
      'name': listName,
      'prevList': prevList.name,
    });

    return true;
  }

  /// Deletes a library list by its name.
  Future<bool> libraryListDeleteList(
    String listName, {
    bool notEmptyOk = true,
    bool doesNotExistOk = false,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(listName != 'favourites', 'Cannot delete the "favourites" list.');

    if (!doesNotExistOk && !(await libraryListExists(listName))) {
      return false;
    }

    if (!notEmptyOk &&
        ((await libraryListGetList(listName))?.totalCount ?? 0) > 0) {
      return false;
    }

    final result = await delete(
      LibraryListTableNames.libraryList,
      where: '"name" = ?',
      whereArgs: [listName],
    );

    return doesNotExistOk || result > 0;
  }

  /// Deletes all entries in a library list.
  Future<bool> libraryListDeleteAllEntries(
    String listName, {
    bool doesNotExistOk = false,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    if (!doesNotExistOk && !(await libraryListExists(listName))) {
      return false;
    }

    final result = await delete(
      LibraryListTableNames.libraryListEntry,
      where: '"listName" = ?',
      whereArgs: [listName],
    );

    return doesNotExistOk || result > 0;
  }

  /// Appends an entry into the library list, optionally at a specific position.
  ///
  /// This function returns false if the position is out of bounds,
  /// if the list does not exist, or if the entry is already a part of the list.
  Future<bool> libraryListInsertEntry(
    String listName, {
    int? jmdictEntryId,
    String? kanji,
    int? position,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(
      (jmdictEntryId == null) != (kanji == null),
      'Either jmdictEntryId or kanji must be provided, but not both.',
    );
    // TODO: set up lastModified insertion

    if (!await libraryListExists(listName)) {
      return false;
    }

    if (await libraryListListContains(
      listName,
      jmdictEntryId: jmdictEntryId,
      kanji: kanji,
    )) {
      return false;
    }

    if (position != null) {
      final len = (await libraryListGetList(listName))!.totalCount;
      if (0 > position || position > len) {
        return false;
      } else if (position != len) {
        // TODO: use a transaction instead of a batch
        final b = batch();

        final entries_ = (await libraryListGetListEntries(listName))!.entries;

        // TODO: create a query to get entries at exact positions.
        final prevEntry = entries_[position - 1];
        final nextEntry = entries_[position];

        b.insert(LibraryListTableNames.libraryListEntry, {
          'listName': listName,
          'jmdictEntryId': jmdictEntryId,
          'kanji': kanji,
          'prevEntryJmdictEntryId': prevEntry.jmdictEntryId,
          'prevEntryKanji': prevEntry.kanji,
        });

        b.update(
          LibraryListTableNames.libraryListEntry,
          {'prevEntryJmdictEntryId': jmdictEntryId, 'prevEntryKanji': kanji},
          where: '"listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)',
          whereArgs: [listName, nextEntry.jmdictEntryId, nextEntry.kanji],
        );

        await b.commit();

        return true;
      }
    }

    final LibraryListEntry? prevEntry = (await libraryListGetListEntries(
      listName,
    ))!.entries.lastOrNull;

    await insert(LibraryListTableNames.libraryListEntry, {
      'listName': listName,
      'jmdictEntryId': jmdictEntryId,
      'kanji': kanji,
      'prevEntryJmdictEntryId': prevEntry?.jmdictEntryId,
      'prevEntryKanji': prevEntry?.kanji,
    });

    return true;
  }

  /// Deletes an entry at a specific position in the library list.
  ///
  /// This function returns false if the list does not exist,
  /// or if the entry is not already a part of the list.
  Future<bool> libraryListDeleteEntry(
    String listName, {
    int? jmdictEntryId,
    String? kanji,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(
      (jmdictEntryId == null) != (kanji == null),
      'Either jmdictEntryId or kanji must be provided, but not both.',
    );

    if (!await libraryListExists(listName)) {
      return false;
    }

    if (!await libraryListListContains(
      listName,
      jmdictEntryId: jmdictEntryId,
      kanji: kanji,
    )) {
      return false;
    }

    // TODO: these queries might be combined into one
    final entryQuery = await query(
      LibraryListTableNames.libraryListEntry,
      columns: ['prevEntryJmdictEntryId', 'prevEntryKanji'],
      where: '"listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)',
      whereArgs: [listName, jmdictEntryId, kanji],
    );

    final nextEntryQuery = await query(
      LibraryListTableNames.libraryListEntry,
      where:
          '"listName" = ? AND ("prevEntryJmdictEntryId" = ? OR "prevEntryKanji" = ?)',
      whereArgs: [listName, jmdictEntryId, kanji],
    );

    final prevEntryJmdictEntryId =
        entryQuery.first['prevEntryJmdictEntryId'] as int?;
    final prevEntryKanji = entryQuery.first['prevEntryKanji'] as String?;

    final LibraryListEntry? nextEntry = nextEntryQuery
        .map((e) => LibraryListEntry.fromDBMap(e))
        .firstOrNull;

    // TODO: use a transaction instead of a batch
    final b = batch();

    if (nextEntry != null) {
      b.update(
        LibraryListTableNames.libraryListEntry,
        {
          'prevEntryJmdictEntryId': prevEntryJmdictEntryId,
          'prevEntryKanji': prevEntryKanji,
        },
        where: '"listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)',
        whereArgs: [listName, nextEntry.jmdictEntryId, nextEntry.kanji],
      );
    }

    b.delete(
      LibraryListTableNames.libraryListEntry,
      where: '"listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)',
      whereArgs: [listName, jmdictEntryId, kanji],
    );

    b.commit();

    return true;
  }

  /// Deletes an entry at a specific position in the library list.
  ///
  /// This function returns false if the position is out of bounds,
  /// or if the list does not exist.
  ///
  /// Avoid using this function if possible, as it has a time complexity of O(n),
  /// in contrast to `libraryListDeleteEntry` which has a time complexity of whatever
  /// SQLite uses for its indices.
  Future<bool> libraryListDeleteEntryByPosition(
    String listName,
    int position,
  ) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    assert(position >= 0, 'Position must be a non-negative integer.');

    if (!await libraryListExists(listName)) {
      return false;
    }

    final entries = (await libraryListGetListEntries(
      listName,
      page: 0,
      pageSize: position + 1,
    ))?.entries;
    if (entries == null || position >= entries.length) {
      return false;
    }

    final entry = entries[position];

    final result = await libraryListDeleteEntry(
      listName,
      jmdictEntryId: entry.jmdictEntryId,
      kanji: entry.kanji,
    );

    return result;
  }

  /// Reorders an entry within the library list.
  ///
  /// This function returns false if the position is out of bounds,
  /// if the list does not exist, or if the entry is not already a part of the list.
  Future<bool> libraryListMoveEntry(
    String listName,
    int newPosition, {
    int? jmdictEntryId,
    String? kanji,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    throw UnimplementedError();
  }

  /// Appends an entry to the library list if it's not there already,
  /// or removes it if it is. Returns whether the entry is now in the list.
  Future<bool> libraryListToggleEntry(
    String listName, {
    int? jmdictEntryId,
    String? kanji,
    bool? overrideToggleOn,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    if ((jmdictEntryId == null) == (kanji == null)) {
      throw ArgumentError(
        'Either jmdictEntryId or kanji must be provided, but not both.',
      );
    }

    final shouldToggleOn =
        overrideToggleOn ??
        !(await libraryListListContains(
          listName,
          jmdictEntryId: jmdictEntryId,
          kanji: kanji,
        ));

    if (shouldToggleOn) {
      final result = await libraryListInsertEntry(
        listName,
        jmdictEntryId: jmdictEntryId,
        kanji: kanji,
      );
      assert(result, 'Failed to insert entry into library list "$listName".');
    } else {
      final result = await libraryListDeleteEntry(
        listName,
        jmdictEntryId: jmdictEntryId,
        kanji: kanji,
      );
      assert(result, 'Failed to delete entry from library list "$listName".');
    }

    return shouldToggleOn;
  }

  /// Verifies the linked list structure of the list of library lists.
  Future<bool> libraryListVerifyLists() async {
    throw UnimplementedError();
  }

  /// Verifies the linked list structure of a single library list.
  Future<bool> libraryListVerifyList(String listName) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    throw UnimplementedError();
  }

  // Future<void> libraryListInsertJsonEntries(
  //   List<Map<String, Object?>> jsonEntries,
  // ) async {
  //   throw UnimplementedError();
  // }

  Future<void> libraryListInsertJsonEntriesForSingleList(
    String listName,
    List<Map<String, Object?>> jsonEntries,
  ) async {
    final List<LibraryListEntry> entries = jsonEntries
        .map((e) => LibraryListEntry.fromJson(e))
        .toList();

    // TODO: batch
    for (final entry in entries) {
      await libraryListInsertEntry(
        listName,
        kanji: entry.kanji,
        jmdictEntryId: entry.jmdictEntryId,
      );
    }
  }
}

class LibraryList {
  final String name;
  final int totalCount;

  const LibraryList({required this.name, required this.totalCount});
}

class LibraryListPage {
  final String name;
  final int totalCount;
  final List<LibraryListEntry> entries;

  const LibraryListPage({
    required this.name,
    required this.totalCount,
    required this.entries,
  });
}

class LibraryListEntry {
  DateTime lastModified;

  final int? jmdictEntryId;
  final WordSearchResult? wordSearchResult;

  final String? kanji;
  final KanjiSearchResult? kanjiSearchResult;

  LibraryListEntry({
    DateTime? lastModified,
    this.wordSearchResult,
    this.jmdictEntryId,
    this.kanji,
    this.kanjiSearchResult,
  }) : lastModified = lastModified ?? DateTime.now(),
       assert(
         kanji != null || jmdictEntryId != null,
         "Library entry can't be empty",
       ),
       assert(
         !(kanji != null && jmdictEntryId != null),
         "Library entry can't have both kanji and jmdictEntryId",
       ),
       assert(
         kanjiSearchResult?.kanji == kanji,
         "KanjiSearchResult's kanji must match the kanji in LibraryListEntry",
       ),
       assert(
         wordSearchResult?.entryId == jmdictEntryId,
         "WordSearchResult's jmdictEntryId must match the jmdictEntryId in LibraryListEntry",
       );

  LibraryListEntry.fromJmdictId({
    required int this.jmdictEntryId,
    this.wordSearchResult,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now(),
       kanji = null,
       kanjiSearchResult = null;

  LibraryListEntry.fromKanji({
    required String this.kanji,
    this.kanjiSearchResult,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now(),
       jmdictEntryId = null,
       wordSearchResult = null;

  Map<String, Object?> toJson() => {
    'kanji': kanji,
    'jmdictEntryId': jmdictEntryId,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  factory LibraryListEntry.fromJson(Map<String, Object?> json) {
    assert(
      (json.containsKey('kanji') && json['kanji'] != null) ||
          (json.containsKey('jmdictEntryId') && json['jmdictEntryId'] != null),
      "Library entry can't be empty",
    );
    assert(
      json.containsKey('lastModified'),
      'Library entry must have a lastModified timestamp',
    );

    if (json.containsKey('kanji') && json['kanji'] != null) {
      return LibraryListEntry.fromKanji(
        kanji: json['kanji']! as String,
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          json['lastModified']! as int,
        ),
      );
    } else {
      return LibraryListEntry.fromJmdictId(
        jmdictEntryId: json['jmdictEntryId']! as int,
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          json['lastModified']! as int,
        ),
      );
    }
  }

  // NOTE: this just happens to be the same as the logic in `fromJson`
  factory LibraryListEntry.fromDBMap(Map<String, Object?> dbObject) =>
      LibraryListEntry.fromJson(dbObject);
}
