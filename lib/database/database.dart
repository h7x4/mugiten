import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/models/verify_tables.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

const int expectedDatabaseVersion = 2;

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

Future<bool> databaseNeedsInitialization() async {
  final String dbPath = await databasePath();

  if (!File(dbPath).existsSync()) {
    return true;
  }

  final Database database = await openDatabase(
    dbPath,
    readOnly: true,
    singleInstance: true,
  );
  final databaseVersion = await database.getVersion();
  await database.close();

  if (databaseVersion < expectedDatabaseVersion) {
    return true;
  }

  return false;
}

Future<void> quickInitializeDatabase() async {
  // TODO: Create more lightweight solution
  await setupDatabase();
}

/// Migration logic and heavy initialization

class DatabaseMigration {
  final String path;
  final String content;

  const DatabaseMigration({required this.path, required this.content});

  int get version {
    final String fileName = basenameWithoutExtension(path);
    return int.parse(fileName.split('_')[0]);
  }

  @override
  String toString() {
    return 'DatabaseMigration(path: $path, content: ${content.length} chars)';
  }
}

Future<List<DatabaseMigration>> readMigrationsFromAssets() async {
  log('Reading migrations from assets...');

  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);

  final List<String> migrations = assetManifest
      .listAssets()
      .where(
        (assetPath) =>
            RegExp(r'^migrations\/\d{4}.*\.sql$').hasMatch(assetPath),
      )
      .toList();

  assert(migrations.isNotEmpty, 'No migration files found in assets');

  migrations.sort();

  log('Found ${migrations.length} migration files:');
  for (final migration in migrations) {
    log(' - $migration');
  }

  return Future.wait(
    migrations.map((migration) async {
      final content = await rootBundle.loadString(migration, cache: false);
      return DatabaseMigration(path: migration, content: content);
    }),
  );
}

/// Migrates the database from version [oldVersion] to [newVersion].
Future<void> migrate(Database db, List<DatabaseMigration> migrations) async {
  for (final migration in migrations) {
    log('Running migration ${migration.version} from ${migration.path}');
    migration.content
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

Future<Database> openDatabaseWithoutMigrations(
  String dbPath, {
  bool readOnly = false,
  bool verifyTables = true,
}) async {
  log('Opening database at $dbPath');
  final Database database = await openDatabase(
    dbPath,
    version: expectedDatabaseVersion,
    readOnly: readOnly,
    onConfigure: (db) async {
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys=ON');
    },
    onOpen: (db) async {
      if (verifyTables) {
        log('Verifying jadb tables...');
        db.jadbVerifyTables();

        log('Verifying mugiten tables...');
        verifyMugitenTablesWithDbConnection(db);

        log('Database tables verified successfully');
      }
    },
  );
  return database;
}

Future<Database> openAndMigrateDatabase(
  String dbPath,
  List<DatabaseMigration> migrations,
) async {
  log('Opening database at $dbPath');
  final Database database = await openDatabase(
    dbPath,
    version: expectedDatabaseVersion,
    readOnly: false,
    onUpgrade: (db, oldVersion, newVersion) async {
      log('Migrating database from v$oldVersion to v$newVersion...');
      final migrationsToRun = migrations
          .where(
            (migration) =>
                migration.version > oldVersion &&
                migration.version <= newVersion,
          )
          .toList();

      await migrate(db, migrationsToRun);
    },
    onConfigure: (db) async {
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys=ON');
    },
    onOpen: (db) async {
      log('Verifying jadb tables...');
      db.jadbVerifyTables();

      log('Verifying jadb tables...');
      verifyMugitenTablesWithDbConnection(db);

      log('Database tables verified successfully');
    },
  );
  return database;
}

/// Sets up the database, creating it if it does not exist.
Future<void> setupDatabase() async {
  log('Setting up database...');

  final String dbPath = await databasePath();

  assert(File(dbPath).existsSync(), 'Database file should exist at this point');

  final database = await openDatabaseWithoutMigrations(
    dbPath,
    readOnly: false,
    verifyTables: true,
  );

  assert(
    await database.getVersion() == expectedDatabaseVersion,
    'Database version should be $expectedDatabaseVersion',
  );

  log('Registering database in GetIt...');
  GetIt.instance.registerSingleton<Database>(database);
}

/// Resets the database by closing it, deleting the file, and setting it up again.
Future<void> resetDatabase() async {
  log('Closing database...');
  await GetIt.instance.get<Database>().close();

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

  jadbFile.createSync();

  final ByteData data = await rootBundle.load('assets/jadb.sqlite');
  await jadbFile.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}
