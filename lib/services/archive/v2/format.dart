import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:collection/collection.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/services/archive/archive_utils.dart';
import 'package:sqflite/sqlite_api.dart';

part './history.dart';
part './library_lists.dart';

const int expectedDataFormatVersion = 2;
const int historyChunkSize = 100;
const int libraryListChunkSize = defaultLibraryListPageSize;

typedef ArchiveV2HistoryEntryCountQuery =
    Future<int> Function(DatabaseExecutor db);

typedef ArchiveV2HistoryEntryGetAllQuery =
    Future<List<ArchiveV2HistoryEntry>> Function({
      required DatabaseExecutor db,
      required int page,
      required int pageSize,
    });

typedef ArchiveV2LibraryListGetLibraryMetadataQuery =
    Future<List<ArchiveV2LibraryListMetadata>> Function({
      required DatabaseExecutor db,
    });

typedef ArchiveV2LibraryListGetTotalCountsQuery =
    Future<Map<String, int>> Function({required DatabaseExecutor db});

typedef ArchiveV2LibraryListGetEntriesQuery =
    Future<List<ArchiveV2LibraryListEntry>> Function({
      required DatabaseExecutor db,
      required String listName,
      required int page,
    });

/// An adapter that provides the necessary functions to export data from the database
/// in the format expected by version 2 of the data archive.
class ArchiveV2ExportAdapter {
  final ArchiveV2HistoryEntryCountQuery historyEntryCount;
  final ArchiveV2HistoryEntryGetAllQuery historyEntryGetAll;
  final ArchiveV2LibraryListGetLibraryMetadataQuery
  libraryListGetLibraryMetadata;
  final ArchiveV2LibraryListGetTotalCountsQuery libraryListGetTotalCounts;
  final ArchiveV2LibraryListGetEntriesQuery libraryListGetEntries;

  const ArchiveV2ExportAdapter({
    required this.historyEntryCount,
    required this.historyEntryGetAll,
    required this.libraryListGetLibraryMetadata,
    required this.libraryListGetTotalCounts,
    required this.libraryListGetEntries,
  });
}

final ArchiveV2ExportAdapter latestSchemaExportAdapter = ArchiveV2ExportAdapter(
  historyEntryCount: (final db) => db.historyEntryAmount(),
  historyEntryGetAll:
      ({
        required final DatabaseExecutor db,
        required final int page,
        required final int pageSize,
      }) async {
        return (await db.historyEntryGetAll(
          page: page,
          pageSize: pageSize,
        )).map(ArchiveV2HistoryEntry.fromHistoryEntry).toList();
      },
  libraryListGetLibraryMetadata: ({required final DatabaseExecutor db}) async {
    return (await db.libraryListGetLists())
        .map((final list) => ArchiveV2LibraryListMetadata(name: list.name))
        .toList();
  },
  libraryListGetTotalCounts: ({required final DatabaseExecutor db}) async {
    final lists = await db.libraryListGetLists();
    return {for (final list in lists) list.name: list.totalCount};
  },
  libraryListGetEntries:
      ({
        required final DatabaseExecutor db,
        required final String listName,
        required final int page,
      }) async {
        final entryPage = await db.libraryListGetListEntries(
          listName,
          page: page,
        );
        if (entryPage == null) {
          return <ArchiveV2LibraryListEntry>[];
        }

        return entryPage.entries
            .map(ArchiveV2LibraryListEntry.fromLibraryListEntry)
            .toList();
      },
);

/// Functions and properties that makes up the format of version 2 of the data archive.
/// This archive is used to back up user data and optionally to transfer data between devices.
/// The main difference to version 1 is that the data is split into chunks, so that it can be
/// streamed and processed in parts, instead of having to load the entire data into memory at once.
/// This not only reduces the memory usage, but also allows for reporting progress and resuming interrupted imports/exports.
///
/// Example file Structure:
///
/// ```
/// - jisho_data_2022.01.01_1
///   - history/
///     - 1.json
///     - 2.json
///     - ...
///     - 99.json
///     - ...
///   - library/
///     - metadata.json
///     - lista/
///       - 1.json
///       - 2.json
///       - ...
///     - listb/
///       - 1.json
///       - 2.json
///       - ...
/// ```
extension ArchiveFormatV2 on Directory {
  File get versionFile => File(uri.resolve('version.txt').toFilePath());
  int get version => int.parse(versionFile.readAsStringSync());

  // History //

  Directory get historyDir => Directory(uri.resolve('history').toFilePath());

  List<File> get historyChunkFiles =>
      historyDir.listSync().whereType<File>().sortedBy(
        (final f) =>
            int.tryParse(
              f.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), ''),
            ) ??
            0,
      );

  File historyChunkFile(final int chunkIndex) =>
      File(historyDir.uri.resolve('$chunkIndex.json').toFilePath());

  int get historyChunkCount => historyDir.listSync().whereType<File>().length;

  // Library Lists //

  Directory get libraryDir => Directory(uri.resolve('library').toFilePath());

  /// See [libraryMetadata] for the expected content of this file.
  File get libraryMetadataFile =>
      File(libraryDir.uri.resolve('metadata.json').toFilePath());

  /// The metadata of all library lists.
  ///
  /// This is expected to be a list of objects, containing:
  ///  - *order*: implicitly from the order of the json list, the index of the library list
  ///  - name: the original name of the library list
  ///  - slug: the slugified name of the library list, used for the directory name
  List<Map<String, Object?>> get libraryMetadata =>
      (jsonDecode(libraryMetadataFile.readAsStringSync()) as List<dynamic>)
          .map((final entry) => entry as Map<String, Object?>)
          .toList();

  List<Directory> get libraryListDirs =>
      libraryDir.listSync().whereType<Directory>().toList();

  Directory libraryListDir(final String listName) => Directory(
    libraryDir.uri
        .resolve('${slugifyLibraryListFileName(listName)}/')
        .toFilePath(),
  );

  File libraryListChunkFile(final String listName, final int chunkIndex) =>
      File(
        libraryListDir(listName).uri.resolve('$chunkIndex.json').toFilePath(),
      );

  List<int> get libraryListEntryCounts => libraryListDirs
      .map((final d) => d.listSync().whereType<File>().length)
      .toList();
}

String slugifyLibraryListFileName(final String name) =>
    name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

Future<int> totalAmountOfChunksFromDatabase(final DatabaseExecutor db) {
  return totalAmountOfChunksFromDatabaseWithAdapter(
    db,
    adapter: latestSchemaExportAdapter,
  );
}

Future<int> totalAmountOfChunksFromDatabaseWithAdapter(
  final DatabaseExecutor db, {
  required final ArchiveV2ExportAdapter adapter,
}) async {
  final historyCount = await adapter.historyEntryCount(db);
  final libraryMetadata = await adapter.libraryListGetLibraryMetadata(db: db);
  final libraryListCounts = await adapter.libraryListGetTotalCounts(db: db);

  final libraryChunks = libraryMetadata
      .map(
        (final list) =>
            ((libraryListCounts[list.name] ?? 0) / libraryListChunkSize).ceil(),
      )
      .sum;

  return (historyCount / historyChunkSize).ceil() + libraryChunks;
}

// TODO: skip counting chunks where the library list already exists
//       and has a non-zero entry count.
int totalAmountOfChunksFromArchive(final File archiveFile) {
  final Archive archive = ZipDecoder().decodeStream(
    InputFileStream(archiveFile.path),
  );
  int result = 0;
  for (final file in archive) {
    if (file.isFile &&
        file.name != 'metadata.json' &&
        file.name.endsWith('.json')) {
      result++;
    }
  }
  return result;
}

class ArchiveV2StreamEvent {
  final String type;
  final int progress;
  final int total;

  final String? name;
  final int? subProgress;
  final int? subTotal;

  const ArchiveV2StreamEvent({
    required this.type,
    required this.progress,
    required this.total,
    this.name,
    this.subProgress,
    this.subTotal,
  }) : assert(
         progress > 0 && total > 0 && progress <= total,
         '0 < progress <= total must hold',
       ),
       assert(
         type == 'history' || type == 'library',
         'Type must be either "history" or "library"',
       ),
       assert(
         type != 'history' ||
             (name == null && subProgress == null && subTotal == null),
         'history events must not have a name, subProgress or subTotal',
       ),
       assert(
         type != 'library' ||
             (name != null && subProgress != null && subTotal != null),
         'library events must have a name, subProgress and subTotal',
       ),
       assert(
         (subProgress == null && subTotal == null) ||
             (subProgress != null &&
                 subTotal != null &&
                 subProgress > 0 &&
                 subTotal > 0 &&
                 subProgress <= subTotal),
         'subProgress and subTotal must both be null or both be positive integers with subProgress <= subTotal',
       );

  @override
  String toString() {
    if (type == 'history') {
      return 'ArchiveV2StreamEvent.History($progress/$total)';
    } else {
      return 'ArchiveV2StreamEvent.Library("$name", $progress/$total, $subProgress/$subTotal)';
    }
  }
}

/// Packs the given directory into a zip file.
///
/// If [outputFile] is provided, it will be used as the output file. Otherwise, a new temporary file will be created.
Future<File> packZip(final Directory dir, {File? outputFile}) async {
  if (outputFile == null || !outputFile.existsSync()) {
    final outputDir = await tmpdir();
    outputFile = File(outputDir.uri.resolve('mugiten_data.zip').toFilePath())
      ..createSync();
  }

  final archive = createArchiveFromDirectory(dir, includeDirName: false);

  final outputStream = OutputFileStream(outputFile.path);
  ZipEncoder().encodeStream(archive, outputStream, autoClose: true);

  return outputFile;
}

Stream<ArchiveV2StreamEvent> exportData(
  final DatabaseExecutor db,
  final File archiveFile,
) {
  return exportDataWithAdapter(
    db,
    archiveFile,
    adapter: latestSchemaExportAdapter,
  );
}

Stream<ArchiveV2StreamEvent> exportDataWithAdapter(
  final DatabaseExecutor db,
  final File archiveFile, {
  required final ArchiveV2ExportAdapter adapter,
}) async* {
  if (!archiveFile.existsSync()) {
    archiveFile.createSync();
  }

  final archiveRoot = await tmpdir();

  await ArchiveFormatV2(
    archiveRoot,
  ).versionFile.writeAsString(expectedDataFormatVersion.toString());

  yield* exportHistory(db, archiveRoot, adapter: adapter);
  yield* exportLibraryLists(db, archiveRoot, adapter: adapter);

  await packZip(archiveRoot, outputFile: archiveFile);

  archiveRoot.deleteSync(recursive: true);
}

Stream<ArchiveV2StreamEvent> importData(
  final DatabaseExecutor db,
  final File archiveFile,
) async* {
  if (!archiveFile.existsSync()) {
    throw Exception('Archive file does not exist: ${archiveFile.path}');
  }

  final archiveRoot = await unpackZipToTempDir(archiveFile.path);

  yield* importHistory(db, archiveRoot);
  yield* importLibraryLists(db, archiveRoot);

  archiveRoot.deleteSync(recursive: true);
}
