import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:mugiten/database/library_list/table_names.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Example file Structure:
//   jisho_data_2022.01.01_1
//   - history.json
//   - library/
//     - lista.json
//     - listb.json

extension ArchiveFormat on Directory {
  File get versionFile => File(uri.resolve('version.txt').toFilePath());
  File get historyFile => File(uri.resolve('history.json').toFilePath());
  Directory get libraryDir => Directory(uri.resolve('library').toFilePath());
}

Future<Directory> tmpdir() async =>
    Directory.systemTemp.createTemp('mugiten_data_');

Future<Directory> unpackZipToTempDir(String zipFilePath) async {
  final outputDir = await tmpdir();
  await extractFileToDisk(zipFilePath, outputDir.path);
  return outputDir;
}

Future<File> packZip(Directory dir, {File? outputFile}) async {
  if (outputFile == null || !outputFile.existsSync()) {
    final outputDir = await tmpdir();
    outputFile = File(outputDir.uri.resolve('mugiten_data.zip').toFilePath());
    outputFile.createSync();
  }

  final archive = createArchiveFromDirectory(dir, includeDirName: false);

  final outputStream = OutputFileStream(outputFile.path);
  ZipEncoder().encodeStream(archive, outputStream, autoClose: true);

  return outputFile;
}

String getExportFileNameNoSuffix() {
  final DateTime today = DateTime.now();
  final String formattedDate =
      '${today.year}'
      '.${today.month.toString().padLeft(2, '0')}'
      '.${today.day.toString().padLeft(2, '0')}';

  return 'mugiten_data_$formattedDate';
}

Future<File> exportData(DatabaseExecutor db) async {
  final dir = await tmpdir();

  final libraryDir = Directory(dir.uri.resolve('library').toFilePath());
  libraryDir.createSync();

  await Future.wait([
    exportDataFormatVersionTo(dir),
    exportHistoryTo(db, dir),
    exportLibraryListsTo(db, libraryDir),
  ]);

  final zipFile = await packZip(dir);

  return zipFile;
}

Future<void> importData(Database db, File zipFile) async {
  final dir = await unpackZipToTempDir(zipFile.path);

  await Future.wait([
    importHistoryFrom(db, dir.historyFile),
    importLibraryListsFrom(db, dir.libraryDir),
  ]);

  dir.deleteSync(recursive: true);
}

/////////////////////////
// DATA FORMAT VERSION //
/////////////////////////

const int expectedDataFormatVersion = 1;

Future<void> exportDataFormatVersionTo(Directory dir) async {
  final file = dir.versionFile;
  file.createSync();
  file.writeAsStringSync(expectedDataFormatVersion.toString());
}

Future<int> importDataFormatVersionFrom(File file) async {
  final String content = file.readAsStringSync();
  return int.parse(content);
}

/////////////
// HISTORY //
/////////////

Future<void> exportHistoryTo(DatabaseExecutor db, Directory dir) async {
  final file = dir.historyFile;
  file.createSync();

  final List<Map<String, Object?>> jsonEntries = (await db.historyEntryGetAll())
      .map((e) => e.toJson())
      .toList();

  file.writeAsStringSync(jsonEncode(jsonEntries));
}

Future<void> importHistoryFrom(Database db, File file) async {
  final String content = file.readAsStringSync();
  final List<Map<String, Object?>> json = (jsonDecode(content) as List)
      .map((h) => h as Map<String, Object?>)
      .toList();
  // log('Importing ${json.length} entries from ${file.path}');
  await db.transaction((txn) => txn.historyEntryInsertManyFromJson(json));
}

///////////////////
// LIBRARY LISTS //
///////////////////

Future<void> exportLibraryListsTo(DatabaseExecutor db, Directory dir) async {
  final libraryNames = await db
      .query(LibraryListTableNames.libraryList, columns: ['name'])
      .then((result) => result.map((row) => row['name'] as String).toList());

  await Future.wait([
    for (final libraryName in libraryNames)
      exportLibraryListTo(db, libraryName, dir),
  ]);
}

Future<void> exportLibraryListTo(
  DatabaseExecutor db,
  String libraryName,
  Directory dir,
) async {
  final file = File(dir.uri.resolve('$libraryName.json').toFilePath());
  await file.create();

  // TODO: properly null check
  final entries = (await db.libraryListGetListEntries(
    libraryName,
  ))!.entries.map((e) => e.toJson()).toList();

  await file.writeAsString(jsonEncode(entries));
}

// TODO: how do we handle lists that already exist? There seems to be no good way to merge them?
Future<void> importLibraryListsFrom(
  DatabaseExecutor db,
  Directory libraryListsDir,
) async {
  for (final file in libraryListsDir.listSync()) {
    if (file is! File) continue;

    assert(file.path.endsWith('.json'));

    final libraryName = file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.json$'),
      '',
    );

    if (await db.libraryListExists(libraryName)) {
      if ((await db.libraryListGetList(libraryName))!.totalCount > 0) {
        print(
          'Library list "$libraryName" already exists and is not empty. Skipping import.',
        );
        continue;
      } else {
        print(
          'Library list "$libraryName" already exists but is empty. '
          'Importing entries from file ${file.path}.',
        );
      }
    } else {
      await db.libraryListInsertList(libraryName);
    }

    final content = await file.readAsString();
    final List<Map<String, Object?>> jsonEntries = (jsonDecode(content) as List)
        .map((e) => e as Map<String, Object?>)
        .toList();

    await db.libraryListInsertJsonEntriesForSingleList(
      libraryName,
      jsonEntries,
    );
  }
}
