import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/database/history/table_names.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/services/archive/v1/format.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../../testutils.dart';

void main() {
  late final String libsqlitePath;
  late final String jadbPath;
  late Directory tmpdir;
  late Database database;

  setUpAll(() {
    if (!Platform.environment.containsKey('LIBSQLITE_PATH')) {
      throw Exception('LIBSQLITE_PATH environment variable is not set.');
    }

    if (!Platform.environment.containsKey('JADB_PATH')) {
      throw Exception('JADB_PATH environment variable is not set.');
    }

    libsqlitePath = File(
      Platform.environment['LIBSQLITE_PATH']!,
    ).resolveSymbolicLinksSync();
    jadbPath = File(
      Platform.environment['JADB_PATH']!,
    ).resolveSymbolicLinksSync();
  });

  // Setup sqflite_common_ffi for flutter test
  setUp(() async {
    database = await createDatabaseCopy(
      libsqlitePath: libsqlitePath,
      jadbPath: jadbPath,
    );

    GetIt.instance.registerSingleton<Database>(database);

    tmpdir = await test_tmpdir();
  });

  tearDown(() async {
    await database.close();

    GetIt.instance.unregister<Database>();

    final jadbCopyPath = database.path;

    if (File(jadbCopyPath).existsSync()) {
      await File(jadbCopyPath).delete();
    }

    if (tmpdir.existsSync()) {
      await tmpdir.delete(recursive: true);
    }
  });

  test('Archive V1 export to and import from zip archive', () async {
    // Insert data
    final historyEntries = await createRandomHistoryEntries(
      db: database,
      count: 300,
    );
    await database.historyEntryInsertEntries(historyEntries);

    final libraryEntriesF = await createRandomLibraryListEntries(
      db: database,
      kanjiCount: 400,
      jmdictEntryCount: 440,
    );
    final libraryEntries1 = await createRandomLibraryListEntries(
      db: database,
      kanjiCount: 150,
      jmdictEntryCount: 150,
    );
    final libraryEntries2 = await createRandomLibraryListEntries(
      db: database,
      kanjiCount: 150,
      jmdictEntryCount: 300,
    );
    final libraryEntries3 = await createRandomLibraryListEntries(
      db: database,
      kanjiCount: 150,
      jmdictEntryCount: 150,
    );

    await database.libraryListInsertList('Test List 1');
    await database.libraryListInsertList('Test List 2');
    await database.libraryListInsertList('Test List 3');

    await database.libraryListInsertEntries('favourites', libraryEntriesF);
    await database.libraryListInsertEntries('Test List 1', libraryEntries1);
    await database.libraryListInsertEntries('Test List 2', libraryEntries2);
    await database.libraryListInsertEntries('Test List 3', libraryEntries3);

    // Export to zip
    final zipFile = await exportData(database);

    // Delete all data
    await database.delete(HistoryTableNames.historyEntry);
    await database.libraryListDeleteAllEntries('favourites');
    await database.libraryListDeleteList('Test List 1');
    await database.libraryListDeleteList('Test List 2');
    await database.libraryListDeleteList('Test List 3');

    // Import from zip
    await importData(database, zipFile);

    // Verify data
    final int historyEntryAmount = await database.historyEntryAmount();
    assert(
      historyEntryAmount == historyEntries.length,
      'History entry amount should be ${historyEntries.length} after import, but got $historyEntryAmount',
    );

    final favourites = (await database.libraryListGetLists()).firstWhere(
      (final list) => list.name == 'favourites',
    );
    assert(
      favourites.totalCount == libraryEntriesF.length,
      'Favourites entry count should be ${libraryEntriesF.length} after import, but got ${favourites.totalCount}',
    );

    final listCount = await database.libraryListAmount();
    assert(
      listCount == 4,
      'Library list amount should be 4 after import, but got $listCount',
    );
  });
}
