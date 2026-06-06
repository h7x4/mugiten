import 'dart:io';

import 'package:archive/archive_io.dart';

/// Creates a temporary directory for storing exported data files before zipping them.
Future<Directory> tmpdir() => Directory.systemTemp.createTemp('mugiten_data_');

/// Unpacks the given zip file to a temporary directory and returns the directory.
Future<Directory> unpackZipToTempDir(final String zipFilePath) async {
  final outputDir = await tmpdir();
  await extractFileToDisk(zipFilePath, outputDir.path);
  return outputDir;
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
