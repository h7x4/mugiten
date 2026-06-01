import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/services/database/history/table_names.dart';
import 'package:mugiten/services/database/library_list/table_names.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

part './history.dart';
part './library_lists.dart';

const int expectedDataFormatVersion = 1;

/// Functions and properties that makes up the format of version 1 of the data archive.
/// This archive is used to back up user data and optionally to transfer data between devices.
///
/// Example file Structure:
///
/// ```
/// - jisho_data_2022.01.01_1
///   - history.json
///   - library/
///     - lista.json
///     - listb.json
/// ```
extension ArchiveFormatV1 on Directory {
  File get versionFile => File(uri.resolve('version.txt').toFilePath());
  int get version => int.parse(versionFile.readAsStringSync());
  File get historyFile => File(uri.resolve('history.json').toFilePath());
  Directory get libraryDir => Directory(uri.resolve('library').toFilePath());

  Iterable<File> get libraryListFiles => libraryDir
      .listSync()
      .whereType<File>()
      .where((final f) => f.path.endsWith('.json'));

  Iterable<String> get libraryListNames => libraryListFiles.map(
    (final f) => f.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), ''),
  );
}

/// Creates a temporary directory for storing exported data files before zipping them.
Future<Directory> tmpdir() => Directory.systemTemp.createTemp('mugiten_data_');

/// Unpacks the given zip file to a temporary directory and returns the directory.
Future<Directory> unpackZipToTempDir(final String zipFilePath) async {
  final outputDir = await tmpdir();
  await extractFileToDisk(zipFilePath, outputDir.path);
  return outputDir;
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

/// Generates a file name for the exported data file based on the current date, without the file extension.
String getExportFileNameNoSuffix() {
  final DateTime today = DateTime.now();
  final String formattedDate =
      '${today.year}'
      '.${today.month.toString().padLeft(2, '0')}'
      '.${today.day.toString().padLeft(2, '0')}';

  return 'mugiten_data_$formattedDate';
}

Future<File> exportData(final DatabaseExecutor db) async {
  final archiveRoot = await tmpdir();
  archiveRoot.libraryDir.createSync();

  await Future.wait([
    exportDataFormatVersionTo(archiveRoot),
    exportHistoryTo(db, archiveRoot),
    exportLibraryListsTo(db, archiveRoot),
  ]);

  final zipFile = await packZip(archiveRoot);

  archiveRoot.deleteSync(recursive: true);

  return zipFile;
}

Future<void> importData(final Database db, final File zipFile) async {
  final archiveRoot = await unpackZipToTempDir(zipFile.path);

  await Future.wait([
    importHistoryFrom(db, archiveRoot.historyFile),
    importLibraryListsFrom(db, archiveRoot),
  ]);

  archiveRoot.deleteSync(recursive: true);
}

Future<void> exportDataFormatVersionTo(final Directory dir) async {
  dir.versionFile
    ..createSync()
    ..writeAsStringSync(expectedDataFormatVersion.toString());
}
