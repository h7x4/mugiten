import 'package:mugiten/services/archive/v2/format.dart';
import 'package:mugiten/services/database/schemas/v1/table_names.dart';
import 'package:sqflite/sqlite_api.dart';

const archiveExportAdapter = ArchiveV2ExportAdapter(
  historyEntryCount: historyEntryCount,
  historyEntryGetAll: historyEntryGetAll,
  libraryListGetLibraryMetadata: libraryListGetLibraryMetadata,
  libraryListGetTotalCounts: libraryListGetTotalCounts,
  libraryListGetEntries: libraryListGetEntries,
);

Future<int> historyEntryCount(final DatabaseExecutor db) async {
  final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT "entryId") AS "count"
      FROM "${HistoryTableNames.historyEntryOrderedByTimestamp}"
    ''');
  return result.first['count'] as int;
}

Future<List<ArchiveV2HistoryEntry>> historyEntryGetAll({
  required final DatabaseExecutor db,
  required final int page,
  required final int pageSize,
}) async {
  final result = await db.rawQuery(
    '''
      SELECT
        *,
        GROUP_CONCAT("${HistoryTableNames.historyEntryTimestamp}"."timestamp") AS "timestamps"
      FROM "${HistoryTableNames.historyEntryOrderedByTimestamp}"
      LEFT JOIN "${HistoryTableNames.historyEntryTimestamp}" USING ("entryId")
      GROUP BY "${HistoryTableNames.historyEntryOrderedByTimestamp}"."entryId"
      ORDER BY "${HistoryTableNames.historyEntryOrderedByTimestamp}"."timestamp" DESC
      LIMIT ?
      OFFSET ?
    ''',
    [pageSize, page * pageSize],
  );

  final List<ArchiveV2HistoryEntry> entries = result
      .map(
        (final e) => ArchiveV2HistoryEntry(
          id: e['entryId']! as int,
          searchInstances: (e['timestamps'] as String)
              .split(',')
              .map(
                (final ts) => ArchiveV2HistorySearchInstance(
                  timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(ts)),
                ),
              )
              .toList(),
          word: e['word'] as String?,
          kanji: e['kanji'] as String?,
        ),
      )
      .toList();

  return entries;
}

Future<List<ArchiveV2LibraryListMetadata>> libraryListGetLibraryMetadata({
  required final DatabaseExecutor db,
}) async {
  final result = await db.query(
    LibraryListTableNames.libraryListOrdered,
    columns: ['name'],
  );

  return result
      .map(
        (final row) =>
            ArchiveV2LibraryListMetadata(name: row['name'] as String),
      )
      .toList();
}

Future<Map<String, int>> libraryListGetTotalCounts({
  required final DatabaseExecutor db,
}) async {
  final result = await db.rawQuery('''
      SELECT
        "lists"."name" AS "listName",
        (
          SELECT COUNT(*)
          FROM "${LibraryListTableNames.libraryListEntry}" AS "entries"
          WHERE "entries"."listName" = "lists"."name"
        ) AS "count"
      FROM "${LibraryListTableNames.libraryListOrdered}" AS "lists"
    ''');

  final counts = {
    for (final row in result) row['listName'] as String: row['count'] as int,
  };

  return counts;
}

Future<List<ArchiveV2LibraryListEntry>> libraryListGetEntries({
  required final DatabaseExecutor db,
  required final String listName,
  required final int page,
}) async {
  final result = await db.rawQuery(
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
      LIMIT ?
      OFFSET ?
    ''',
    [listName, listName, libraryListChunkSize, page * libraryListChunkSize],
  );

  final entries = result
      .map(
        (final entry) => ArchiveV2LibraryListEntry(
          lastModified: DateTime.fromMillisecondsSinceEpoch(
            entry['lastModified'] as int,
          ),
          jmdictEntryId: entry['jmdictEntryId'] as int?,
          kanji: entry['kanji'] as String?,
        ),
      )
      .toList();

  return entries;
}
