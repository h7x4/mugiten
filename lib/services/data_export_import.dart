import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:mugiten/database/history/table_names.dart';
import 'package:mugiten/models/history/history_entry.dart';
import 'package:mugiten/models/library/library_list.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Example file Structure:
//   jisho_data_2022.01.01_1
//   - history.json
//   - library/
//     - lista.json
//     - listb.json

extension ArchiveFormat on Directory {
  File get historyFile => File(uri.resolve('history.json').path);
  Directory get libraryDir => Directory(uri.resolve('library').path);
}

Future<Directory> tmpdir() async =>
    Directory.systemTemp.createTemp('mugiten_data_');

Future<Directory> unpackZipToTempDir(String zipFilePath) async {
  final outputDir = await tmpdir();
  await extractFileToDisk(
    zipFilePath,
    outputDir.path,
  );
  return outputDir;
}

Future<File> packZip(
  Directory dir, {
  File? outputFile,
}) async {
  if (outputFile == null || !outputFile.existsSync()) {
    final outputDir = await tmpdir();
    outputFile = File(outputDir.uri.resolve('mugiten_data.zip').path);
    outputFile.createSync();
  }

  final archive = createArchiveFromDirectory(
    dir,
    includeDirName: false,
  );

  final outputStream = OutputFileStream(outputFile.path);
  ZipEncoder().encodeStream(
    archive,
    outputStream,
    autoClose: true,
  );

  return outputFile;
}

String getExportFileNameNoSuffix() {
  final DateTime today = DateTime.now();
  final String formattedDate = '${today.year}'
      '.${today.month.toString().padLeft(2, '0')}'
      '.${today.day.toString().padLeft(2, '0')}';

  return 'mugiten_data_$formattedDate';
}

Future<File> exportData(DatabaseExecutor db) async {
  final dir = await tmpdir();

  final libraryDir = Directory(dir.uri.resolve('library').path);
  libraryDir.createSync();

  await Future.wait([
    exportHistoryTo(db, dir),
    exportLibraryListsTo(libraryDir),
  ]);

  final zipFile = await packZip(dir);

  return zipFile;
}

Future<void> importData(DatabaseExecutor db, File zipFile) async {
  final dir = await unpackZipToTempDir(zipFile.path);

  await Future.wait([
    importHistoryFrom(dir.historyFile),
    importLibraryListsFrom(dir.libraryDir),
  ]);

  dir.deleteSync(recursive: true);
}

/////////////
// HISTORY //
/////////////

Future<void> exportHistoryTo(
  DatabaseExecutor db,
  Directory dir,
) async {
  final file = dir.historyFile;
  file.createSync();

  final query =
      await db.query(HistoryTableNames.historyEntryOrderedByTimestamp);

  final List<HistoryEntry> entries =
      query.map((e) => HistoryEntry.fromDBMap(e)).toList();

  /// TODO: This creates a ton of sql statements. Ideally, the whole export
  /// should be done in only one query.
  ///
  /// On second thought, is that even possible? It's a doubly nested list structure.
  final List<Map<String, Object?>> jsonEntries = await Future.wait(
      entries.map((historyEntry) async => historyEntry.toJson()));

  file.writeAsStringSync(jsonEncode(jsonEntries));
}

Future<void> importHistoryFrom(File file) async {
  final String content = file.readAsStringSync();
  final List<Map<String, Object?>> json = (jsonDecode(content) as List)
      .map((h) => h as Map<String, Object?>)
      .toList();
  // log('Importing ${json.length} entries from ${file.path}');
  await HistoryEntry.insertJsonEntries(json);
}

///////////////////
// LIBRARY LISTS //
///////////////////

Future<void> exportLibraryListsTo(
  // DatabaseExecutor db,
  Directory dir,
) async =>
    Future.wait(
      (await LibraryList.allLibraries).map((lib) async {
        final file = File(dir.uri.resolve('${lib.name}.json').path);
        file.createSync();
        final entries = await lib.entries;
        file.writeAsStringSync(jsonEncode(entries));
      }),
    );

// TODO: how do we handle lists that already exist? There seems to be no good way to merge them?
Future<void> importLibraryListsFrom(Directory libraryListsDir) async {
  for (final file in libraryListsDir.listSync()) {
    if (file is! File) continue;

    assert(file.path.endsWith('.json'));

    final libraryName =
        file.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), '');

    if (await LibraryList.exists(libraryName)) {
      if ((await LibraryList.byName(libraryName).length) > 0) {
        print(
            'Library list "$libraryName" already exists and is not empty. Skipping import.');
        continue;
      } else {
        print('Library list "$libraryName" already exists but is empty. '
            'Importing entries from file ${file.path}.');
      }
    } else {
      LibraryList.insert(libraryName);
    }

    final content = await file.readAsString();
    final List<Map<String, Object?>> jsonEntries = (jsonDecode(content) as List)
        .map((e) => e as Map<String, Object?>)
        .toList();

    final libraryList = LibraryList.byName(libraryName);
    await libraryList.insertJsonEntries(jsonEntries);
  }
}
