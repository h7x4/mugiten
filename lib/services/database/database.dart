import 'dart:developer';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:jadb/search.dart';
import 'package:jadb/version.dart';
import 'package:mugiten/libtamerye.dart';
import 'package:mugiten/models/verify_tables.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi, sqfliteFfiInit;
import 'package:sqlite3/sqlite3.dart' show sqlite3;

export 'package:mugiten/services/database/database_reset.dart'
    show resetDatabase;
export 'package:mugiten/services/database/schemas/v2/table_names.dart'
    show HistoryTableNames, LibraryListTableNames;

const int mugitenSchemaVersion = 2;
const int schemaVersion = mugitenSchemaVersion << 16 | jadbSchemaVersion;

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

/// Checks if the database needs to be reset.
///
/// This is the case if the database does not yet exist, or if it's using an old schema version.
Future<bool> databaseNeedsReset() async {
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

  if (databaseVersion < schemaVersion) {
    return true;
  }

  return false;
}

Future<void> quickInitializeDatabase() async {
  // TODO: Create more lightweight solution
  await setupDatabase();
}

Future<Database> openDatabaseWithoutMigrations(
  final String dbPath, {
  final bool readOnly = false,
  final bool verifyTables = true,
}) async {
  log('Opening database at $dbPath');

  sqfliteFfiInit();

  sqlite3.loadSqliteTameryeExtension();

  databaseFactory = databaseFactoryFfi;

  final Database database = await openDatabase(
    dbPath,
    version: schemaVersion,
    readOnly: readOnly,
    onConfigure: (final db) async {
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys=ON');
    },
    onOpen: (final db) async {
      if (verifyTables) {
        log('Verifying jadb tables...');
        await db.jadbVerifyTables();

        log('Verifying mugiten tables...');
        await verifyMugitenTablesWithDbConnection(db);

        log('Verifying libtamerye has been loaded correctly...');
        final result = await db.rawQuery("SELECT hiragana_to_katakana('ひらがな')");
        if (result.isEmpty || result.first.values.first != 'ヒラガナ') {
          throw Exception('libtamerye does not seem to be loaded correctly');
        }

        log('Database tables verified successfully');
      }
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
    await database.getVersion() == schemaVersion,
    'Database version should be $schemaVersion',
  );

  log('Registering database in GetIt...');
  GetIt.instance.registerSingleton<Database>(database);
}

/// Resets the database by closing it, deleting the file, and setting it up again.
Future<void> resetGetItDatabase() async {
  log('Closing database...');
  await GetIt.instance.get<Database>().close();

  log('Deleting mugiten.sqlite file...');
  File(await databasePath()).deleteSync();

  log('Unregistering database from GetIt...');
  GetIt.instance.unregister<Database>();

  log('Setting up database again...');
  await setupDatabase();
}
