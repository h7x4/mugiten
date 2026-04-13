import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/services/archive/v1/format.dart'
    show tmpdir, packZip, unpackZipToTempDir;
import 'package:sqflite/sqlite_api.dart';

export 'package:mugiten/services/archive/v1/format.dart'
    show getExportFileNameNoSuffix;

part './history.dart';
part './library_lists.dart';

const int expectedDataFormatVersion = 2;
const int historyChunkSize = 100;
const int libraryListChunkSize = 100;

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

  /// The metadata of all library lists
  ///
  /// This is expected to be a list of objects, containing:
  ///  - *order*: implicitly from the order of the json list, the index of the library list
  ///  - name: the original name of the library list
  ///  - slug: the slugified name of the library list, used for the directory name
  Map<String, Object?> get libraryMetadata =>
      jsonDecode(libraryMetadataFile.readAsStringSync())
          as Map<String, Object?>;

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
      .map(
        (final d) =>
            d.listSync().whereType<File>().length -
            1, // Subtract 1 for metadata.json
      )
      .toList();
}

String slugifyLibraryListFileName(final String name) =>
    name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

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

Stream<ArchiveV2StreamEvent> exportData(
  final DatabaseExecutor db,
  final File archiveFile,
) async* {
  if (!archiveFile.existsSync()) {
    archiveFile.createSync();
  }

  final archiveRoot = await tmpdir();

  await ArchiveFormatV2(
    archiveRoot,
  ).versionFile.writeAsString(expectedDataFormatVersion.toString());

  yield* exportHistory(db, archiveRoot);
  yield* exportLibraryLists(db, archiveRoot);

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
