import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/services/database/database.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Extracts the `jadb.sqlite` file from the assets into a writable directory
/// and returns its path.
Future<void> extractJadbFromAssets(final String path) async {
  final File jadbFile = File(path)..createSync();

  final ByteData data = await rootBundle.load('assets/jadb.sqlite');
  await jadbFile.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

/// Dataclass representing a raw SQL migration file, containing its path and content.
class RawSQLMigration {
  final String path;
  final String content;

  const RawSQLMigration({required this.path, required this.content});

  String get name {
    final String fileName = basenameWithoutExtension(path);
    return fileName.split('_').sublist(1).join('_');
  }

  int get version {
    final String fileName = basenameWithoutExtension(path);
    return int.parse(fileName.split('_')[0]);
  }

  @override
  String toString() {
    return 'RawSQLMigration(version: $version, name: $name, size: ${content.length})';
  }
}

/// Reads all migration files for the given database version from the assets and returns them as a list of [RawSQLMigration]s.
Future<List<RawSQLMigration>> readMigrationsForDatabaseVersionFromAssets(
  final int databaseVersion,
) async {
  log(
    'Reading migrations for database version $databaseVersion from assets...',
  );

  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);

  final List<String> migrations = assetManifest
      .listAssets()
      .where(
        (final assetPath) => RegExp(
          '^lib/services/database/schemas/v$databaseVersion/\\d{4}.*\\.sql\$',
        ).hasMatch(assetPath),
      )
      .toList();

  assert(
    migrations.isNotEmpty,
    'No migration files found in assets for database version $databaseVersion',
  );

  migrations.sort();

  log('Found ${migrations.length} migration files:');
  for (final migration in migrations) {
    log(' - $migration');
  }

  return Future.wait(
    migrations.map((final migration) async {
      final content = await rootBundle.loadString(migration, cache: false);
      return RawSQLMigration(path: migration, content: content);
    }),
  );
}

/// Applies the given list of [RawSQLMigration]s to the provided [Database] in a single transaction.
Future<void> applyMigrations(
  final Database db,
  final List<RawSQLMigration> migrations,
) async {
  for (final migration in migrations) {
    log('Applying migration $migration');
    await db.transaction((final txn) async {
      migration.content
          .split(';')
          .map(
            (final s) => s
                .split('\n')
                .where((final l) => !l.startsWith(RegExp(r'\s*--')))
                .join('\n')
                .trim(),
          )
          .where((final s) => s != '')
          .forEach(txn.execute);
    });
  }
}

/// Resets the database at the given path by:
///
/// - Deleting the database file (if it exists)
/// - Extracting a fresh copy of `jadb.sqlite` from the assets
/// - Applying all schema migrations for the current schema version
Future<Database> resetDatabase(final String dbPath) async {
  log('Resetting database at $dbPath...');

  final File dbFile = File(dbPath);
  if (dbFile.existsSync()) {
    dbFile.delete();
    log('Deleted existing database file at $dbPath');
  }

  await extractJadbFromAssets(dbPath);
  log('Extracted jadb.sqlite to $dbPath');

  final migrations = await readMigrationsForDatabaseVersionFromAssets(
    mugitenSchemaVersion,
  );

  final Database database = await openDatabase(
    dbPath,
    version: schemaVersion,
    readOnly: false,
    onUpgrade: (final db, final oldVersion, final newVersion) async {
      assert(
        oldVersion == 0,
        'Expected oldVersion to be 0 during database reset, but got $oldVersion',
      );

      log('Setting up new database with schema version $newVersion...');
      await applyMigrations(db, migrations);
      log('Database upgrade complete');
    },
    onConfigure: (final db) async {
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys=ON');
    },
    onOpen: (final db) async {
      log('Verifying jadb tables...');
      await db.jadbVerifyTables();

      log('Verifying mugiten tables...');
      // TODO: verify mugiten tables for the exact schema version.
      // await verifyMugitenTablesWithDbConnection(db);

      log('Database tables verified successfully');
    },
  );

  return database;
}
