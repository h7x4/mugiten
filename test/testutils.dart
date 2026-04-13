import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mugiten/database/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> createDatabaseCopy({
  required final String libsqlitePath,
  required final String jadbPath,
}) async {
  final jadbFile = File(jadbPath);
  if (!jadbFile.existsSync()) {
    throw Exception('JADB_PATH does not exist: $jadbPath');
  }

  // Make a copy of jadbPath
  final randomSuffix = Random()
      .nextInt((pow(2, 32) - 1) as int)
      .toRadixString(16);
  final jadbCopyPath = jadbFile.parent.uri
      .resolve('jadb_copy_$randomSuffix.sqlite')
      .path;

  await jadbFile.copy(jadbCopyPath);

  print('Using database copy: $jadbCopyPath');

  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = createDatabaseFactoryFfi();

  WidgetsFlutterBinding.ensureInitialized();

  return await openAndMigrateDatabase(
    jadbCopyPath,
    await readMigrationsFromAssets(),
  );
}
