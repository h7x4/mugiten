import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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

  test('Full reimport', () async {
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

    await database.libraryListInsertEntries('Test List 1', libraryEntries1);
    await database.libraryListInsertEntries('Test List 2', libraryEntries2);
    await database.libraryListInsertEntries('Test List 3', libraryEntries3);

    final listCount1 = await database.libraryListAmount();
    assert(
      listCount1 == 4,
      'Library list amount should be 3 after insertion, but got $listCount1',
    );

    tmpdir.libraryDir.createSync();
    await exportLibraryListsTo(database, tmpdir.libraryDir);

    await database.libraryListDeleteList('Test List 1');
    await database.libraryListDeleteList('Test List 2');
    await database.libraryListDeleteList('Test List 3');

    final listCount2 = await database.libraryListAmount();
    assert(
      listCount2 == 1,
      'Library list amount should be 0 after deletion, but got $listCount2',
    );

    await importLibraryListsFrom(database, tmpdir);

    final listCount3 = await database.libraryListAmount();
    assert(
      listCount3 == 4,
      'Library list amount should be 3 after import, but got $listCount3',
    );
  });

  test('Full reimport favourites', () async {
    final libraryEntries = await createRandomLibraryListEntries(
      db: database,
      kanjiCount: 150,
      jmdictEntryCount: 150,
    );

    await database.libraryListInsertEntries('favourites', libraryEntries);
    final favourites = (await database.libraryListGetLists()).first;
    assert(
      favourites.totalCount == libraryEntries.length,
      'Favourites entry count should be ${libraryEntries.length} after insertion, but got ${favourites.totalCount}',
    );

    tmpdir.libraryDir.createSync();
    await exportLibraryListsTo(database, tmpdir.libraryDir);

    await database.libraryListDeleteAllEntries('favourites');
    final emptyFavourites = (await database.libraryListGetLists()).first;
    assert(
      emptyFavourites.totalCount == 0,
      'Favourites entry count should be 0 after deletion, but got ${emptyFavourites.totalCount}',
    );

    await importLibraryListsFrom(database, tmpdir);

    final importedFavourites = (await database.libraryListGetLists()).first;
    assert(
      importedFavourites.totalCount == libraryEntries.length,
      'Favourites entry count should be ${libraryEntries.length} after import, but got ${importedFavourites.totalCount}',
    );
  });
}
