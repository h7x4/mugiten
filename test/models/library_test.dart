import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/database/database.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

Future<Database> createDatabaseCopy({
  required String libsqlitePath,
  required String jadbPath,
}) async {
  final jadbFile = File(jadbPath);
  if (!jadbFile.existsSync()) {
    throw Exception("JADB_PATH does not exist: $jadbPath");
  }

  // Make a copy of jadbPath
  final random_suffix = Random()
      .nextInt((pow(2, 32) - 1) as int)
      .toRadixString(16);
  final jadbCopyPath = jadbFile.parent.uri
      .resolve("jadb_copy_$random_suffix.sqlite")
      .path;

  await jadbFile.copy(jadbCopyPath);

  print("Using database copy: $jadbCopyPath");

  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = await createDatabaseFactoryFfi(
    ffiInit: () =>
        open.overrideForAll(() => DynamicLibrary.open(libsqlitePath)),
  );

  WidgetsFlutterBinding.ensureInitialized();

  return await openAndMigrateDatabase(
    jadbCopyPath,
    await readMigrationsFromAssets(),
  );
}

Future<void> insertTestData(Database db) async {
  final libraryList1 = await db.libraryListInsertList("Test Library 1");
  assert(libraryList1 == true);

  await db.libraryListInsertEntry(
    "Test Library 1",
    jmdictEntryId: null,
    kanji: "漢",
  );

  await db.libraryListInsertEntry(
    "Test Library 1",
    jmdictEntryId: null,
    kanji: "字",
  );
}

void main() {
  late final String libsqlitePath;
  late final String jadbPath;
  late final Database database;

  setUpAll(() {
    if (!Platform.environment.containsKey("LIBSQLITE_PATH")) {
      throw Exception("LIBSQLITE_PATH environment variable is not set.");
    }

    if (!Platform.environment.containsKey("JADB_PATH")) {
      throw Exception("JADB_PATH environment variable is not set.");
    }

    libsqlitePath = File(
      Platform.environment["LIBSQLITE_PATH"]!,
    ).resolveSymbolicLinksSync();
    jadbPath = File(
      Platform.environment["JADB_PATH"]!,
    ).resolveSymbolicLinksSync();
  });

  // Setup sqflite_common_ffi for flutter test
  setUp(() async {
    database = await createDatabaseCopy(
      libsqlitePath: libsqlitePath,
      jadbPath: jadbPath,
    );

    GetIt.instance.registerSingleton<Database>(database);

    await insertTestData(database);
  });

  tearDown(() async {
    await database.close();

    GetIt.instance.unregister<Database>();

    final jadbCopyPath = database.path;

    if (File(jadbCopyPath).existsSync()) {
      await File(jadbCopyPath).delete();
    }
  });

  test('Database is open', () async {
    expect(database.isOpen, isTrue);
  });
}
