import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/search.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

export 'package:sqflite/sqlite_api.dart';

Database db() => GetIt.instance.get<Database>();

/// Returns the directory where mugiten's database file is stored.
Future<Directory> _databaseDir() async {
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  if (!appDocDir.existsSync()) appDocDir.createSync(recursive: true);
  return appDocDir;
}

/// Returns the expected path to mugiten's database file.
Future<String> databasePath() async {
  return join((await _databaseDir()).path, 'mugiten.sqlite');
}

/// Migrates the database from version [oldVersion] to [newVersion].
Future<void> migrate(Database db, int oldVersion, int newVersion) async {
  log('Migrating database from v$oldVersion to v$newVersion...');

  final String assetManifest =
      await rootBundle.loadString('AssetManifest.json');

  final List<String> migrations =
      (jsonDecode(assetManifest) as Map<String, Object?>)
          .keys
          .where(
            (assetPath) =>
                RegExp(r'^migrations\/\d{4}.*\.sql$').hasMatch(assetPath),
          )
          .toList();

  log('Found ${migrations.length} migration files:');
  for (final migration in migrations) {
    log(' - $migration');
  }

  migrations.sort();

  for (int i = oldVersion + 1; i <= newVersion; i++) {
    log(
      'Migrating database from v$i to v${i + 1} with File(${migrations[i - 1]})',
    );
    final migrationContent =
        await rootBundle.loadString(migrations[i - 1], cache: false);

    migrationContent
        .split(';')
        .map(
          (s) => s
              .split('\n')
              .where((l) => !l.startsWith(RegExp(r'\s*--')))
              .join('\n')
              .trim(),
        )
        .where((s) => s != '')
        .forEach(db.execute);
  }
}

/// Sets up the database, creating it if it does not exist.
Future<void> setupDatabase() async {
  log('Setting up database...');

  final String dbPath = await databasePath();

  if (!await File(dbPath).exists()) {
    log('Extracting jadb.sqlite from assets...');
    await extractJadbFromAssets(dbPath);
    log('jadb.sqlite extracted to $dbPath');
  }

  log('Opening database at $dbPath');
  final Database database = await openDatabase(
    dbPath,
    version: 2,
    readOnly: false,
    onUpgrade: migrate,
    onConfigure: (db) async {
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys=ON');
    },
    onOpen: (db) async {
      log('Verifying jadb tables...');

      db.jadbVerifyTables();

      log('jadb opened successfully');
    },
  );

  log('Registering database in GetIt...');
  GetIt.instance.registerSingleton<Database>(database);
}

/// Resets the database by closing it, deleting the file, and setting it up again.
Future<void> resetDatabase() async {
  log('Closing database...');
  await db().close();

  log('Deleting mugiten.sqlite file...');
  File(await databasePath()).deleteSync();

  log('Unregistering database from GetIt...');
  GetIt.instance.unregister<Database>();

  log('Setting up database again...');
  await setupDatabase();
}

/// Extracts the jadb.sqlite file from the assets into a writable directory
/// and returns its path.
Future<void> extractJadbFromAssets(String path) async {
  final File jadbFile = File(path);

  if (!await jadbFile.exists()) {
    jadbFile.createSync();
  }

  ByteData data = await rootBundle.load('assets/jadb.sqlite');
  await jadbFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}
