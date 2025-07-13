import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:mugiten/database/library_list/table_names.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../database/database_errors.dart';
import 'library_entry.dart';

class LibraryList {
  final String name;

  const LibraryList.byName(this.name);

  static const LibraryList favourites = LibraryList.byName('favourites');

  /// Get all entries within the library, in their custom order
  Future<List<LibraryEntry>> entries(
    DatabaseExecutor db, {
    int? page,
    int? pageSize,
  }) async {
    assert(
      page == null || page >= 0,
    );
    assert(pageSize == null || pageSize > 0);
    assert(
      page == null || pageSize != null,
      'If page is provided, pageSize must also be provided.',
    );

    const columns = ['jmdictEntryId', 'kanji', 'lastModified'];
    final query = await db.rawQuery(
      '''
        WITH RECURSIVE
          "RecursionTable"(${columns.map((c) => '"$c"').join(', ')}) AS (
            SELECT ${columns.map((c) => '"$c"').join(', ')}
            FROM "${LibraryListTableNames.libraryListEntry}"
            WHERE
              "listName" = ?
              AND "prevEntryJmdictEntryId" IS NULL
              AND "prevEntryKanji" IS NULL

            UNION ALL

            SELECT ${columns.map((c) => '"R"."$c"').join(', ')}
            FROM "${LibraryListTableNames.libraryListEntry}" AS "R", "RecursionTable"
            WHERE "R"."listName" = ?
              AND ("R"."prevEntryJmdictEntryId" = "RecursionTable"."jmdictEntryId"
              OR "R"."prevEntryKanji" = "RecursionTable"."kanji")
          )
        SELECT ${columns.map((c) => '"$c"').join(', ')} FROM "RecursionTable"
        ${pageSize != null ? 'LIMIT ?' : ''}
        ${page != null ? 'OFFSET ?' : ''}
      ''',
      [
        name,
        name,
        if (pageSize != null) pageSize,
        if (page != null) page * pageSize!,
      ],
    );

    return query.map((e) => LibraryEntry.fromDBMap(e)).toList();
  }

  /// Get all existing libraries in their custom order.
  static Future<List<LibraryList>> allLibraries(DatabaseExecutor db) async {
    final query = await db.query(LibraryListTableNames.libraryListOrdered);
    return query
        .map((lib) => LibraryList.byName(lib['name']! as String))
        .toList();
  }

  /// Generates a map of all the libraries, with the value being
  /// whether or not the specified entry is within the library.
  static Future<Map<LibraryList, bool>> allListsContains({
    required DatabaseExecutor db,
    required int? jmdictEntryId,
    required String? kanji,
  }) async {
    if ((jmdictEntryId == null) == (kanji == null)) {
      throw ArgumentError(
        'Either jmdictEntryId or kanji must be provided, but not both.',
      );
    }

    final query = await db.rawQuery(
      '''
      SELECT
        *,
        EXISTS(
          SELECT * FROM "${LibraryListTableNames.libraryListEntry}"
          WHERE "listName" = "name" AND ("jmdictEntryId" = ? OR "kanji" = ?)
        ) AS "exists"
      FROM "${LibraryListTableNames.libraryListOrdered}"
      ''',
      [
        jmdictEntryId,
        kanji,
      ],
    );

    return Map.fromEntries(
      query.map(
        (lib) => MapEntry(
          LibraryList.byName(lib['name']! as String),
          lib['exists']! as int == 1,
        ),
      ),
    );
  }

  /// Whether a library contains a specific entry
  Future<bool> contains({
    required DatabaseExecutor db,
    required int? jmdictEntryId,
    required String? kanji,
  }) async {
    if (jmdictEntryId == null && kanji == null) {
      return false;
    }
    if (jmdictEntryId != null && kanji != null) {
      throw ArgumentError(
        'Either jmdictEntryId or kanji must be provided, but not both.',
      );
    }

    final query = await db.rawQuery(
      '''
        SELECT EXISTS(
          SELECT *
          FROM "${LibraryListTableNames.libraryListEntry}"
          WHERE "listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)
        ) AS "exists"
      ''',
      [name, jmdictEntryId, kanji],
    );
    return query.first['exists']! as int == 1;
  }

  /// Whether a library contains a specific word entry
  Future<bool> containsJmdictEntryId(
    DatabaseExecutor db,
    int jmdictEntryId,
  ) =>
      contains(
        db: db,
        jmdictEntryId: jmdictEntryId,
        kanji: null,
      );

  /// Whether a library contains a specific kanji entry
  Future<bool> containsKanji(
    DatabaseExecutor db,
    String kanji,
  ) =>
      contains(
        db: db,
        jmdictEntryId: null,
        kanji: kanji,
      );

  /// Whether a library exists in the database
  static Future<bool> exists(
    DatabaseExecutor db,
    String libraryName,
  ) async {
    final query = await db.rawQuery(
      '''
        SELECT EXISTS(
          SELECT *
          FROM "${LibraryListTableNames.libraryList}"
          WHERE "name" = ?
        ) AS "exists"
      ''',
      [libraryName],
    );
    return query.first['exists']! as int == 1;
  }

  static Future<int> libraryCount(
    DatabaseExecutor db,
  ) async {
    final query = await db.query(
      LibraryListTableNames.libraryList,
      columns: ['COUNT(*) AS count'],
    );
    return query.first['count']! as int;
  }

  /// The amount of items within this library.
  Future<int> length(DatabaseExecutor db) async {
    final query = await db.query(
      LibraryListTableNames.libraryListEntry,
      columns: ['COUNT(*) AS count'],
      where: 'listName = ?',
      whereArgs: [name],
    );
    return query.first['count']! as int;
  }

  /// Swaps two entries within a list
  /// Will throw an exception if the entry is already in the library
  Future<void> insertEntry({
    required DatabaseExecutor db,
    required int? jmdictEntryId,
    required String? kanji,
    int? position,
    DateTime? lastModified,
  }) async {
    if ((jmdictEntryId == null) == (kanji == null)) {
      throw ArgumentError(
        'Either jmdictEntryId or kanji must be provided, but not both.',
      );
    }
    // TODO: set up lastModified insertion

    if (await contains(
      db: db,
      jmdictEntryId: jmdictEntryId,
      kanji: kanji,
    )) {
      throw DataAlreadyExistsError(
        tableName: LibraryListTableNames.libraryListEntry,
        illegalArguments: {
          'jmdictEntryId': jmdictEntryId,
          'kanji': kanji,
        },
      );
    }

    if (position != null) {
      final len = await length(db);
      if (0 > position || position > len) {
        throw IndexError.withLength(
          position,
          len,
          indexable: this,
          name: 'position',
          message:
              'Data insertion position ($position) can not be between 0 and length ($len).',
        );
      } else if (position != len) {
        log(
          'Adding ${jmdictEntryId != null ? 'jmdict entry $jmdictEntryId' : 'kanji "$kanji"'} to library "$name" at position $position',
        );

        // TODO: use a transaction instead of a batch
        final b = db.batch();

        final entries_ = await entries(db);
        final prevEntry = entries_[position - 1];
        final nextEntry = entries_[position];

        b.insert(LibraryListTableNames.libraryListEntry, {
          'listName': name,
          'jmdictEntryId': jmdictEntryId,
          'kanji': kanji,
          'prevEntryJmdictEntryId': prevEntry.jmdictEntryId,
          'prevEntryKanji': prevEntry.kanji,
        });

        b.update(
          LibraryListTableNames.libraryListEntry,
          {
            'prevEntryJmdictEntryId': jmdictEntryId,
            'prevEntryKanji': kanji,
          },
          where: '"listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)',
          whereArgs: [name, nextEntry.jmdictEntryId, nextEntry.kanji],
        );

        await b.commit();

        return;
      }
    }

    log(
      'Adding ${jmdictEntryId != null ? 'jmdict entry $jmdictEntryId' : 'kanji "$kanji"'} to library "$name"',
    );

    final LibraryEntry? prevEntry = (await entries(db)).lastOrNull;

    await db.insert(LibraryListTableNames.libraryListEntry, {
      'listName': name,
      'jmdictEntryId': jmdictEntryId,
      'kanji': kanji,
      'prevEntryJmdictEntryId': prevEntry?.jmdictEntryId,
      'prevEntryKanji': prevEntry?.kanji,
    });
  }

  Future<void> insertJsonEntries(
    DatabaseExecutor db,
    List<Map<String, Object?>> jsonEntries,
  ) async {
    List<LibraryEntry> entries =
        jsonEntries.map((e) => LibraryEntry.fromJson(e)).toList();

    // TODO: batch
    for (final entry in entries) {
      if (entry.kanji != null) {
        await insertEntry(
          db: db,
          kanji: entry.kanji,
          jmdictEntryId: null,
          position: null,
          lastModified: entry.lastModified,
        );
      } else if (entry.jmdictEntryId != null) {
        await insertEntry(
          db: db,
          jmdictEntryId: entry.jmdictEntryId,
          kanji: null,
          position: null,
          lastModified: entry.lastModified,
        );
      }
    }
  }

  /// Deletes an entry within a list
  /// Will throw an exception if the entry is not in the library
  Future<void> deleteEntry({
    required DatabaseExecutor db,
    required int? jmdictEntryId,
    required String? kanji,
  }) async {
    if ((jmdictEntryId == null) == (kanji == null)) {
      throw ArgumentError(
        'Either jmdictEntryId or kanji must be provided, but not both.',
      );
    }

    if (!await contains(
      db: db,
      jmdictEntryId: jmdictEntryId,
      kanji: kanji,
    )) {
      throw DataNotFoundError(
        tableName: LibraryListTableNames.libraryListEntry,
        illegalArguments: {
          'jmdictEntryId': jmdictEntryId,
          'kanji': kanji,
        },
      );
    }

    log(
      'Deleting ${jmdictEntryId != null ? 'jmdict entry $jmdictEntryId' : 'kanji "$kanji"'} from library "$name"',
    );

    // TODO: these queries might be combined into one
    final entryQuery = await db.query(
      LibraryListTableNames.libraryListEntry,
      columns: ['prevEntryJmdictEntryId', 'prevEntryKanji'],
      where: '"listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)',
      whereArgs: [name, jmdictEntryId, kanji],
    );

    final nextEntryQuery = await db.query(
      LibraryListTableNames.libraryListEntry,
      where:
          '"listName" = ? AND ("prevEntryJmdictEntryId" = ? OR "prevEntryKanji" = ?)',
      whereArgs: [name, jmdictEntryId, kanji],
    );

    final prevEntryJmdictEntryId =
        entryQuery.first['prevEntryJmdictEntryId'] as int?;
    final prevEntryKanji = entryQuery.first['prevEntryKanji'] as String?;

    final LibraryEntry? nextEntry =
        nextEntryQuery.map((e) => LibraryEntry.fromDBMap(e)).firstOrNull;

    // TODO: use a transaction instead of a batch
    final b = db.batch();

    if (nextEntry != null) {
      b.update(
        LibraryListTableNames.libraryListEntry,
        {
          'prevEntryJmdictEntryId': prevEntryJmdictEntryId,
          'prevEntryKanji': prevEntryKanji,
        },
        where: '"listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)',
        whereArgs: [name, nextEntry.jmdictEntryId, nextEntry.kanji],
      );
    }

    b.delete(
      LibraryListTableNames.libraryListEntry,
      where: '"listName" = ? AND ("jmdictEntryId" = ? OR "kanji" = ?)',
      whereArgs: [name, jmdictEntryId, kanji],
    );

    b.commit();
  }

  /// Swaps two entries within a list
  /// Will throw an error if both of the entries doesn't exist
  Future<void> swapEntries({
    required DatabaseExecutor db,
    required int? jmdictEntryId1,
    required String? kanji1,
    required int? jmdictEntryId2,
    required String? kanji2,
  }) async {
    if ((jmdictEntryId1 == null) == (kanji1 == null) ||
        (jmdictEntryId2 == null) == (kanji2 == null)) {
      throw ArgumentError(
        'Either jmdictEntryId or kanji must be provided for both entries, but not both.',
      );
    }

    if (!await contains(
      db: db,
      jmdictEntryId: jmdictEntryId1,
      kanji: kanji1,
    )) {
      throw DataNotFoundError(
        tableName: LibraryListTableNames.libraryListEntry,
        illegalArguments: {
          'jmdictEntryId': jmdictEntryId1,
          'kanji': kanji1,
        },
      );
    }

    if (!await contains(
      db: db,
      jmdictEntryId: jmdictEntryId2,
      kanji: kanji2,
    )) {
      throw DataNotFoundError(
        tableName: LibraryListTableNames.libraryListEntry,
        illegalArguments: {
          'jmdictEntryId': jmdictEntryId2,
          'kanji': kanji2,
        },
      );
    }

    log(
      'Swapping ${jmdictEntryId1 != null ? 'jmdict entry $jmdictEntryId1' : 'kanji "$kanji1"'} with ${jmdictEntryId2 != null ? 'jmdict entry $jmdictEntryId2' : 'kanji "$kanji2"'} in library "$name"',
    );

    // TODO: implement function.
    throw UnimplementedError();
  }

  /// Toggle whether an entry is in the library or not.
  /// If [overrideToggleOn] is given true or false, it will specifically insert or
  /// delete the entry respectively. Else, it will figure out whether the entry
  /// is in the library already automatically.
  Future<bool> toggleEntry({
    required DatabaseExecutor db,
    required int? jmdictEntryId,
    required String? kanji,
    bool? overrideToggleOn,
  }) async {
    if ((jmdictEntryId == null) == (kanji == null)) {
      throw ArgumentError(
        'Either jmdictEntryId or kanji must be provided, but not both.',
      );
    }

    overrideToggleOn ??= !(await contains(
      db: db,
      jmdictEntryId: jmdictEntryId,
      kanji: kanji,
    ));

    if (overrideToggleOn) {
      await insertEntry(
        db: db,
        jmdictEntryId: jmdictEntryId,
        kanji: kanji,
      );
    } else {
      await deleteEntry(
        db: db,
        jmdictEntryId: jmdictEntryId,
        kanji: kanji,
      );
    }
    return overrideToggleOn;
  }

  Future<void> deleteAllEntries(DatabaseExecutor db) => db.delete(
        LibraryListTableNames.libraryListEntry,
        where: 'listName = ?',
        whereArgs: [name],
      );

  /// Insert a new library list into the database
  static Future<LibraryList> insert(
    DatabaseExecutor db,
    String libraryName,
  ) async {
    if (await exists(db, libraryName)) {
      throw DataAlreadyExistsError(
        tableName: LibraryListTableNames.libraryList,
        illegalArguments: {
          'libraryName': libraryName,
        },
      );
    }

    // This is ok, because "favourites" should always exist.
    final prevList = (await allLibraries(db)).last;
    await db.insert(LibraryListTableNames.libraryList, {
      'name': libraryName,
      'prevList': prevList.name,
    });
    return LibraryList.byName(libraryName);
  }

  /// Delete this library from the database
  Future<void> delete(Database db) async {
    if (name == 'favourites') {
      throw IllegalDeletionError(
        tableName: LibraryListTableNames.libraryList,
        illegalArguments: {'name': name},
      );
    }

    await db.transaction((txn) async {
      await txn.delete(
        LibraryListTableNames.libraryListEntry,
        where: 'listName = ?',
        whereArgs: [name],
      );

      final String prevName = await txn
          .query(
            LibraryListTableNames.libraryList,
            columns: ['prevList'],
            where: 'name = ?',
            whereArgs: [name],
          )
          .then((rows) => rows.first['prevList']! as String);

      final String? nextName = await txn
          .query(
            LibraryListTableNames.libraryList,
            columns: ['name'],
            where: 'prevList = ?',
            whereArgs: [name],
          )
          .then((rows) => rows.firstOrNull?['name'] as String?);

      await txn.delete(
        LibraryListTableNames.libraryList,
        where: 'name = ?',
        whereArgs: [name],
      );

      if (nextName != null) {
        await txn.update(
          LibraryListTableNames.libraryList,
          {'prevList': prevName},
          where: 'name = ?',
          whereArgs: [nextName],
        );
      }

      if (!await verifyLibrariesLinkedList(txn)) {
        print(
            'Library list "$name" has a broken linked list after deletion, rolling back');
        txn.execute('ROLLBACK');
      }
    });
  }

  Future<bool> verifyLibrariesLinkedList(
    DatabaseExecutor db,
  ) async {
    final int allItemsCount = await db.query(
      LibraryListTableNames.libraryList,
      columns: ['COUNT(*) AS count'],
    ).then((rows) => rows.first['count']! as int);

    final int distinctPrevListCount = await db.query(
      LibraryListTableNames.libraryList,
      columns: ['COUNT(DISTINCT prevList) AS count'],
    ).then((rows) => (rows.first['count']! as int) + 1);

    final int recursiveCount = await db.query(
      LibraryListTableNames.libraryListOrdered,
      columns: ['COUNT(*) AS count'],
    ).then((rows) => rows.first['count']! as int);

    if (allItemsCount != distinctPrevListCount) {
      log(
        'Library list "$name" has a mismatch between all items count ($allItemsCount) and distinct prevList count ($distinctPrevListCount).',
      );
      return false;
    }

    if (recursiveCount != allItemsCount) {
      log(
        'Library list "$name" has a mismatch between recursive count ($recursiveCount) and all items count ($allItemsCount).',
      );
      return false;
    }

    return true;
  }
}
