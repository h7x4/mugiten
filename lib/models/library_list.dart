import 'package:collection/collection.dart';
import 'package:jadb/models/kanji_search/kanji_search_result.dart';
import 'package:jadb/models/word_search/word_search_result.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/database/library_list/table_names.dart';
import 'package:sqflite/sqlite_api.dart';

const int basicListOrderNumInterval = 100;
const int defaultLibraryListPageSize = 100;

extension LibraryListExt on DatabaseExecutor {
  // Query

  /// Get a page of library lists, ordered by insertion time (oldest first).
  ///
  /// Pages are 0-indexed.
  Future<List<LibraryList>> libraryListGetLists({final int? page}) async {
    assert(
      page == null || page >= 0,
      'Page must be null or a non-negative integer.',
    );

    final result = await rawQuery(
      '''
        SELECT
          "name",
          (
            SELECT COUNT(*)
            FROM "${LibraryListTableNames.libraryListEntry}"
            WHERE "${LibraryListTableNames.libraryListEntry}"."listName" = "${LibraryListTableNames.libraryList}"."name"
          ) AS "count"
        FROM "${LibraryListTableNames.libraryList}"
        ${page != null ? 'WHERE orderNum >= ? AND orderNum < ?' : ''}
        ORDER BY "orderNum" ASC
      ''',
      [
        if (page != null) (basicListOrderNumInterval * page),
        if (page != null)
          (basicListOrderNumInterval * (page + defaultLibraryListPageSize)),
      ],
    );

    return result
        .map(
          (final row) => LibraryList(
            name: row['name'] as String,
            totalCount: row['count'] as int? ?? 0,
          ),
        )
        .toList();
  }

  /// Get the details of a library list.
  ///
  /// Note that this does not include its entries, use [libraryListGetListEntries] for that.
  Future<LibraryList?> libraryListGetList(final String listName) async {
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
        FROM "${LibraryListTableNames.libraryList}"
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

  /// Get a page of entries in a library list
  ///
  /// If [includeSearchResult] is true, also includes the corresponding search results for each entry.
  ///
  /// Unless  [page] is provided, all entries are returned. This can be very
  /// expensive, so it's recommended to use pagination for lists with many entries.
  ///
  /// Pages are 0-indexed.
  Future<LibraryListPage?> libraryListGetListEntries(
    final String listName, {
    final int? page,
    final bool includeSearchResult = false,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(
      page == null || page >= 0,
      'Page must be null or a non-negative integer.',
    );

    // NOTE: This is used instead of libraryListExists because we'll also return the page count later
    final list = await libraryListGetList(listName);
    if (list == null) {
      return null;
    }

    final offset = page != null ? basicListOrderNumInterval * (basicListOrderNumInterval * page) : null;
    final limit = offset != null
        ? offset + (basicListOrderNumInterval * defaultLibraryListPageSize)
        : null;

    final entries = await rawQuery(
      '''
        SELECT
          "jmdictEntryId",
          "kanji",
          "lastModified"
        FROM "${LibraryListTableNames.libraryListEntry}"
        WHERE
          "listName" = ?
          ${page != null ? 'AND orderNum >= ? AND orderNum < ?' : ''}
        ORDER BY "orderNum" ASC
      ''',
      [listName, if (page != null) offset, if (page != null) limit],
    );

    Map<int, WordSearchResult>? wordResults;
    Map<String, KanjiSearchResult>? kanjiResults;
    if (includeSearchResult) {
      final wordResultJmdictIds = entries
          .where((final e) => e['jmdictEntryId'] != null)
          .map((final e) => e['jmdictEntryId'] as int)
          .toSet();

      wordResults = await jadbGetManyWordsByIds(wordResultJmdictIds);

      final kanjiResultKanjis = entries
          .where((final e) => e['kanji'] != null)
          .map((final e) => e['kanji'] as String)
          .toSet();

      kanjiResults = await jadbGetManyKanji(kanjiResultKanjis);
    }

    final result = entries.map((final entry) {
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
        // TODO: this is not an argument error, fix the error type...
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

  /// Get the position of an entry in a library list, or null if the entry is not in the list.
  Future<int?> libraryListEntryPosition(
    final String listName, {
    final int? jmdictEntryId,
    final String? kanji,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(
      (jmdictEntryId == null) != (kanji == null),
      'Either jmdictEntryId or kanji must be provided, but not both.',
    );

    if (!await libraryListExists(listName)) {
      return null;
    }

    // TODO: select the item matching listname, jmdict id, kanji, and then use the orderNum
    // to find the count of items with a lesser orderNum to know its position.
    //
    // If said entry does not exist, it should return -1
    final result = await rawQuery(
      '''
        WITH
          "item" AS (
            SELECT
              "orderNum"
            FROM "${LibraryListTableNames.libraryListEntry}"
            WHERE "listName" = ?
              AND ("jmdictEntryId" = ? OR "kanji" = ?)
          )
        SELECT
          EXISTS(SELECT * FROM "item") AS "exists",
          COUNT(*) + 1 AS "position"
        FROM "${LibraryListTableNames.libraryListEntry}"
        WHERE "listName" = ?
          AND "orderNum" < (SELECT "orderNum" FROM "item")
      ''',
      [listName, listName, jmdictEntryId, kanji],
    );

    if ((result.firstOrNull?['exists'] as int? ?? 0) == 0) {
      return null;
    }

    return result.firstOrNull?['position'] as int?;
  }

  /// Get whether each library list contains the specified entry.
  ///
  /// Returns a map from library list name to whether the list contains the entry.
  Future<Map<String, bool>> libraryListAllListsContain({
    final int? jmdictEntryId,
    final String? kanji,
  }) async {
    assert(
      (jmdictEntryId == null) != (kanji == null),
      'Either jmdictEntryId or kanji must be provided, but not both.',
    );

    final result = await rawQuery(
      '''
        SELECT
          "name",
          EXISTS(
            SELECT * FROM "${LibraryListTableNames.libraryListEntry}"
            WHERE "listName" = "name"
              AND ("jmdictEntryId" = ? OR "kanji" = ?)
          ) AS "exists"
        FROM "${LibraryListTableNames.libraryList}"
      ''',
      [jmdictEntryId, kanji],
    );

    return {
      for (final row in result)
        row['name'] as String: (row['exists'] as int) == 1,
    };
  }

  /// Get whether a specific library list contains an entry.
  Future<bool> libraryListListContains(
    final String listName, {
    final int? jmdictEntryId,
    final String? kanji,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(
      (jmdictEntryId == null) != (kanji == null),
      'Either jmdictEntryId or kanji must be provided, but not both.',
    );

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

  /// Rename a library list.
  Future<void> libraryListRenameList(
    final String oldName,
    final String newName,
  ) async {
    if (oldName.isEmpty) {
      throw ArgumentError('Old library list name must not be empty.');
    }

    if (newName.isEmpty) {
      throw ArgumentError('New library list name must not be empty.');
    }

    if (oldName == 'favourites') {
      throw ArgumentError('Cannot rename the "favourites" list.');
    }

    if (!await libraryListExists(oldName)) {
      throw ArgumentError('Library list "$oldName" does not exist.');
    }

    if (await libraryListExists(newName)) {
      throw ArgumentError('Library list "$newName" already exists.');
    }

    await update(
      LibraryListTableNames.libraryList,
      {'name': newName},
      where: '"name" = ?',
      whereArgs: [oldName],
    );
  }

  /// Get the total number of library lists.
  Future<int> libraryListAmount() async {
    final result = await query(
      LibraryListTableNames.libraryList,
      columns: ['COUNT(*) AS count'],
    );

    return result.firstOrNull?['count'] as int? ?? 0;
  }

  /// Get whether a library list with the specified name exists.
  Future<bool> libraryListExists(final String listName) async {
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

  /// Insert a new library list into the database.
  Future<bool> libraryListInsertList(
    final String listName, {
    final bool existsOk = true,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    if (!existsOk && await libraryListExists(listName)) {
      return false;
    }

    await rawInsert(
      '''
        INSERT INTO
          "${LibraryListTableNames.libraryList}" ("name", "orderNum")
        VALUES
          (
            ?,
            (SELECT
              IIF(
                MAX("orderNum") IS NULL,
                0,
                MAX("orderNum") + ?
              )
            FROM
              "${LibraryListTableNames.libraryList}"
            )
          )
      ''',
      [listName, basicListOrderNumInterval],
    );

    return true;
  }

  /// Delete a library list by its name.
  Future<bool> libraryListDeleteList(
    final String listName, {
    final bool notEmptyOk = true,
    final bool doesNotExistOk = false,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(listName != 'favourites', 'Cannot delete the "favourites" list.');

    if (!(await libraryListExists(listName))) {
      return doesNotExistOk;
    }

    if (!notEmptyOk &&
        ((await libraryListGetList(listName))?.totalCount ?? 0) > 0) {
      return false;
    }

    final b = batch()
      ..delete(
        LibraryListTableNames.libraryList,
        where: '"name" = ?',
        whereArgs: [listName],
      )
      ..delete(
        LibraryListTableNames.libraryListEntry,
        where: '"listName" = ?',
        whereArgs: [listName],
      );

    await b.commit(noResult: true);

    return true;
  }

  /// Delete all entries in a library list.
  Future<bool> libraryListDeleteAllEntries(
    final String listName, {
    final bool doesNotExistOk = false,
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
  /// The position is zero-indexed, and if not provided, the entry will be appended at the end of the list.
  ///
  /// This function returns false if the position is out of bounds,
  /// if the list does not exist, or if the entry is already a part of the list.
  Future<bool> libraryListInsertEntry(
    final String listName, {
    final int? jmdictEntryId,
    final String? kanji,
    final int? position,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');
    assert(
      position == null || position >= 0,
      'Position must be a non-negative integer.',
    );
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

    if (position == null) {
      await rawInsert(
        '''
          INSERT INTO
            "${LibraryListTableNames.libraryListEntry}" (
              "listName",
              "jmdictEntryId",
              "kanji",
              "orderNum",
              "lastModified"
            )
          VALUES (
            ?,
            ?,
            ?,
            (SELECT
              IIF(
                MAX("orderNum") IS NULL,
                0,
                MAX("orderNum") + ?
              )
            FROM "${LibraryListTableNames.libraryListEntry}" WHERE "listName" = ?),
            strftime('%s', 'now') * 1000
          )
        ''',
        [listName, jmdictEntryId, kanji, basicListOrderNumInterval, listName],
      );
    } else {
      throw UnimplementedError(
        'Inserting an entry at a specific position is not implemented yet, requires reordering algorithm.',
      );
    }

    return true;
  }

  /// Append multiple entries into the library list at once.
  Future<bool> libraryListInsertEntries(
    final String listName,
    final Iterable<LibraryListEntry> entries, {
    final bool throwErrorOnDuplicate = false,
  }) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    if (!await libraryListExists(listName)) {
      return false;
    }

    final maxOrderNum =
        (await rawQuery(
              '''
        SELECT IFNULL(MAX("orderNum"), -1) AS "maxOrderNum"
        FROM "${LibraryListTableNames.libraryListEntry}"
        WHERE "listName" = ?
      ''',
              [listName],
            )).first['maxOrderNum']
            as int;
    final nextOrderNum = maxOrderNum == -1
        ? 0
        : maxOrderNum + basicListOrderNumInterval;

    final b = batch();
    for (final entry in entries.indexed) {
      final i = entry.$1;
      final e = entry.$2;

      b.insert(
        LibraryListTableNames.libraryListEntry,
        {
          'listName': listName,
          'jmdictEntryId': e.jmdictEntryId,
          'kanji': e.kanji,
          'orderNum': nextOrderNum + i * basicListOrderNumInterval,
          'lastModified': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: throwErrorOnDuplicate
            ? ConflictAlgorithm.abort
            : ConflictAlgorithm.ignore,
      );
    }

    await b.commit(noResult: true);

    return true;
  }

  /// Delete an entry at a specific position in the library list.
  ///
  /// This function returns false if the list does not exist,
  /// or if the entry is not already a part of the list.
  Future<bool> libraryListDeleteEntry(
    final String listName, {
    final int? jmdictEntryId,
    final String? kanji,
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

    await delete(
      LibraryListTableNames.libraryListEntry,
      where: jmdictEntryId != null
          ? '"listName" = ? AND "jmdictEntryId" = ?'
          : '"listName" = ? AND "kanji" = ?',
      whereArgs: [listName, jmdictEntryId ?? kanji],
    );

    return true;
  }

  /// Delete an entry at a specific position in the library list.
  ///
  /// This function returns false if the position is out of bounds,
  /// or if the list does not exist.
  ///
  /// Avoid using this function if possible, as it has a time complexity of O(n),
  /// in contrast to `libraryListDeleteEntry` which has a time complexity of whatever
  /// SQLite uses for its indices.
  Future<bool> libraryListDeleteEntryByPosition(
    final String listName,
    final int position,
  ) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    assert(position >= 0, 'Position must be a non-negative integer.');

    final libraryList = await libraryListGetList(listName);
    if (libraryList == null) {
      return false;
    }
    if (position >= libraryList.totalCount) {
      return false;
    }

    await rawQuery(
      '''
        WITH "TargetEntry" AS (
          SELECT
            "jmdictEntryId",
            "kanji"
          FROM "${LibraryListTableNames.libraryListEntry}"
          WHERE "listName" = ?
          ORDER BY "orderNum" ASC
          LIMIT 1 OFFSET ?
        )
        DELETE FROM "${LibraryListTableNames.libraryListEntry}"
        WHERE "listName" = ?
          AND (
            ("jmdictEntryId" IS NOT NULL AND "jmdictEntryId" = (SELECT "jmdictEntryId" FROM "TargetEntry"))
            OR ("kanji" IS NOT NULL AND "kanji" = (SELECT "kanji" FROM "TargetEntry"))
          )
      ''',
      [listName, position, listName],
    );

    return true;
  }

  /// Reorder an entry within the library list.
  ///
  /// The position is zero-indexed.
  ///
  /// This function returns false if the position is out of bounds,
  /// if the list does not exist, or if the entry is not already a part of the list.
  Future<bool> libraryListMoveEntry(
    final String listName,
    final int newPosition, {
    final int? jmdictEntryId,
    final String? kanji,
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

    if (newPosition < 0) {
      return false;
    }

    if ((await libraryListGetList(listName))!.totalCount <= newPosition) {
      return false;
    }

    throw UnimplementedError(
      'Reordering an entry within the library list is not implemented yet, requires reordering algorithm.',
    );
  }

  /// Append an entry to the library list if it's not there already,
  /// or removes it if it is. Returns whether the entry is now in the list.
  Future<bool> libraryListToggleEntry(
    final String listName, {
    final int? jmdictEntryId,
    final String? kanji,
    final bool? overrideToggleOn,
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

  /// Reindex the `orderNum` on all library lists to have a consistent interval.
  ///
  /// This should be done regularly (or after significant reordering operations) to retain
  /// somewhat even spacing between orderNums.
  Future<void> libraryListReindexOrderNums() async {
    await rawQuery(
      '''
        WITH "OrderedLists" AS (
          SELECT
            "name",
            ROW_NUMBER() OVER (ORDER BY "prevList" ASC) - 1 AS "newOrderNum"
          FROM "${LibraryListTableNames.libraryList}"
        )
        UPDATE "${LibraryListTableNames.libraryList}" AS "l"
        SET "orderNum" = ("newOrderNum" * ?)
        FROM "OrderedLists" AS "ol"
        WHERE "l"."name" = "ol"."name"
      ''',
      [basicListOrderNumInterval],
    );
  }

  /// Reindex the `orderNum` on all entries in all library lists to have a consistent interval.
  ///
  /// See [libraryListEntryReindexAllOrderNums] for more details.
  Future<void> libraryListEntryReindexAllOrderNums() async {
    await rawQuery(
      '''
        WITH "OrderedEntries" AS (
          SELECT
            "listName",
            "jmdictEntryId",
            "kanji",
            ROW_NUMBER() OVER (PARTITION BY "listName" ORDER BY "orderNum" ASC) - 1 AS "newOrderNum"
          FROM "${LibraryListTableNames.libraryListEntry}"
        )
        UPDATE "${LibraryListTableNames.libraryListEntry}" AS "e"
        SET "orderNum" = ("newOrderNum" * ?)
        FROM "OrderedEntries" AS "oe"
        WHERE
          "e"."listName" = "oe"."listName"
          AND (
            ("e"."jmdictEntryId" IS NOT NULL AND "e"."jmdictEntryId" = "oe"."jmdictEntryId")
            OR ("e"."kanji" IS NOT NULL AND "e"."kanji" = "oe"."kanji")
          )
      ''',
      [basicListOrderNumInterval],
    );
  }

  /// Reindex the `orderNum` on all entries in the library list to have a consistent interval.
  ///
  /// This should be done regularly (or after significant reordering operations) to retain
  /// somewhat even spacing between orderNums.
  Future<void> libraryListEntryReindexOrderNums(final String listName) async {
    assert(listName.isNotEmpty, 'Library list name must not be empty.');

    if (!await libraryListExists(listName)) {
      throw ArgumentError('Library list "$listName" does not exist.');
    }

    await rawQuery(
      '''
        WITH "OrderedEntries" AS (
          SELECT
            "jmdictEntryId",
            "kanji",
            ROW_NUMBER() OVER (ORDER BY "orderNum" ASC) - 1 AS "newOrderNum"
          FROM "${LibraryListTableNames.libraryListEntry}"
          WHERE "listName" = ?
        )
        UPDATE "${LibraryListTableNames.libraryListEntry}" AS "e"
        SET "orderNum" = ("newOrderNum" * ?)
        FROM "OrderedEntries" AS "oe"
        WHERE
          "e"."listName" = ?
          AND (
            ("e"."jmdictEntryId" IS NOT NULL AND "e"."jmdictEntryId" = "oe"."jmdictEntryId")
            OR ("e"."kanji" IS NOT NULL AND "e"."kanji" = "oe"."kanji")
          )
      ''',
      [listName, basicListOrderNumInterval, listName],
    );
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
    final DateTime? lastModified,
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
         kanjiSearchResult == null || kanjiSearchResult.kanji == kanji,
         "KanjiSearchResult's kanji must match the kanji in LibraryListEntry",
       ),
       assert(
         wordSearchResult == null || wordSearchResult.entryId == jmdictEntryId,
         "WordSearchResult's jmdictEntryId must match the jmdictEntryId in LibraryListEntry",
       );

  LibraryListEntry.fromJmdictId({
    required int this.jmdictEntryId,
    this.wordSearchResult,
    final DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now(),
       kanji = null,
       kanjiSearchResult = null;

  LibraryListEntry.fromKanji({
    required String this.kanji,
    this.kanjiSearchResult,
    final DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now(),
       jmdictEntryId = null,
       wordSearchResult = null;

  @override
  String toString() {
    if (jmdictEntryId != null) {
      return 'LibraryListEntry(jmdictEntryId: $jmdictEntryId, lastModified: $lastModified)';
    } else {
      return 'LibraryListEntry(kanji: $kanji, lastModified: $lastModified)';
    }
  }

  Map<String, Object?> toJson() => {
    'kanji': kanji,
    'jmdictEntryId': jmdictEntryId,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  factory LibraryListEntry.fromJson(final Map<String, Object?> json) {
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
  factory LibraryListEntry.fromDBMap(final Map<String, Object?> dbObject) =>
      LibraryListEntry.fromJson(dbObject);
}
