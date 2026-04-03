import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/database/database.dart';
import 'package:mugiten/models/library_list.dart';
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

Future<void> insertTestData(final Database db) async {
  const listNames = ['Test Library 1', 'Test Library 2', 'Test Library 3'];

  for (final listName in listNames) {
    await db.libraryListInsertList(listName);
    final exists = await db.libraryListExists(listName);
    assert(exists, 'Library list "$listName" does not exist after insertion');
  }

  for (final kanji in ['漢', '字', '学', '習']) {
    await db.libraryListInsertEntry(
      'Test Library 1',
      jmdictEntryId: null,
      kanji: kanji,
    );
  }
}

void main() {
  late final String libsqlitePath;
  late final String jadbPath;
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
  });

  tearDown(() async {
    await database.close();

    GetIt.instance.unregister<Database>();

    final jadbCopyPath = database.path;

    if (File(jadbCopyPath).existsSync()) {
      await File(jadbCopyPath).delete();
    }
  });

  test('Database is open', () {
    expect(database.isOpen, isTrue);
  });

  test('Can insert and query library list', () async {
    await insertTestData(database);

    final libraryExists = await database.libraryListExists('Test Library 1');
    expect(libraryExists, isTrue);

    final libraryLists = await database.libraryListGetLists();
    expect(libraryLists.length, 4);
    expect(libraryLists[0].name, 'favourites');
    expect(libraryLists[1].name, 'Test Library 1');
    expect(libraryLists[2].name, 'Test Library 2');
    expect(libraryLists[3].name, 'Test Library 3');

    final listPage = (await database.libraryListGetListEntries(
      'Test Library 1',
    ))!;
    expect(listPage.entries.length, 4);
    expect(listPage.entries[0].kanji, '漢');
    expect(listPage.entries[1].kanji, '字');
    expect(listPage.entries[2].kanji, '学');
    expect(listPage.entries[3].kanji, '習');
  });

  group('Library list CRUD', () {
    test('Can create another list', () async {
      await insertTestData(database);

      await database.libraryListInsertList('Test Library 4');

      final libraryExists = await database.libraryListExists('Test Library 4');
      expect(libraryExists, isTrue);

      final libraryLists = await database.libraryListGetLists();
      expect(libraryLists.length, 5);
    });

    test('Can delete middle list', () async {
      await insertTestData(database);

      await database.libraryListDeleteList('Test Library 2');

      final libraryExists = await database.libraryListExists('Test Library 2');
      expect(libraryExists, isFalse);

      final libraryLists = await database.libraryListGetLists();
      expect(libraryLists.length, 3);
    });
    test('Can delete last list', () async {
      await insertTestData(database);

      await database.libraryListDeleteList('Test Library 3');

      final libraryExists = await database.libraryListExists('Test Library 3');
      expect(libraryExists, isFalse);

      final libraryLists = await database.libraryListGetLists();
      expect(libraryLists.length, 3);
    });

    test('Can rename middle list', () async {
      await insertTestData(database);

      await database.libraryListRenameList(
        'Test Library 2',
        'Renamed Test Library 2',
      );

      final libraryExists = await database.libraryListExists(
        'Renamed Test Library 2',
      );
      expect(libraryExists, isTrue);

      final libraryLists = await database.libraryListGetLists();
      expect(libraryLists.length, 4);
      expect(libraryLists[2].name, 'Renamed Test Library 2');
    });
    test('Can rename last list', () async {
      await insertTestData(database);

      await database.libraryListRenameList(
        'Test Library 3',
        'Renamed Test Library 3',
      );

      final libraryExists = await database.libraryListExists(
        'Renamed Test Library 3',
      );
      expect(libraryExists, isTrue);

      final libraryLists = await database.libraryListGetLists();
      expect(libraryLists.length, 4);
      expect(libraryLists[3].name, 'Renamed Test Library 3');
    });

    test('Can not delete favourites list', () async {
      await insertTestData(database);

      try {
        await database.libraryListDeleteList('favourites');
        fail('Expected an exception when trying to delete the favourites list');
      } catch (e) {
        expect(e.toString(), contains('Cannot delete the "favourites" list'));
      }

      final libraryExists = await database.libraryListExists('favourites');
      expect(libraryExists, isTrue);
    });
    test('Can not rename favourites list', () async {
      await insertTestData(database);

      try {
        await database.libraryListRenameList(
          'favourites',
          'Renamed Favourites',
        );
        fail('Expected an exception when trying to rename the favourites list');
      } catch (e) {
        expect(e.toString(), contains('Cannot rename the "favourites" list'));
      }

      final libraryExists = await database.libraryListExists('favourites');
      expect(libraryExists, isTrue);
    });
  });

  group('Library list insert entries', () {
    test('Can insert entry into list', () async {
      await insertTestData(database);

      final result = await database.libraryListInsertEntry(
        'Test Library 1',
        jmdictEntryId: null,
        kanji: '新',
      );
      expect(result, isTrue);

      final listPage = (await database.libraryListGetListEntries(
        'Test Library 1',
      ))!;
      expect(listPage.entries.length, 5);
      expect(listPage.entries[4].kanji, '新');
    });

    test('Can insert entry into list at specific position', () async {
      await insertTestData(database);

      final result = await database.libraryListInsertEntry(
        'Test Library 1',
        jmdictEntryId: null,
        kanji: '新',
        position: 2,
      );
      expect(result, isTrue);

      final listPage = (await database.libraryListGetListEntries(
        'Test Library 1',
      ))!;
      expect(listPage.entries.length, 5);
      expect(listPage.entries[2].kanji, '新');
    });

    test('Cannot insert entry into non-existent list', () async {
      await insertTestData(database);

      final result = await database.libraryListInsertEntry(
        'Non-existent List',
        jmdictEntryId: null,
        kanji: '新',
      );

      expect(result, isFalse);
    });

    test('Cannot insert duplicate entry into list', () async {
      await insertTestData(database);

      final result = await database.libraryListInsertEntry(
        'Test Library 1',
        jmdictEntryId: null,
        kanji: '漢',
      );
      expect(result, isFalse);

      final listPage = (await database.libraryListGetListEntries(
        'Test Library 1',
      ))!;
      expect(listPage.entries.length, 4);
    });

    // test('Can bulk insert entries into list', () async {
    //   await insertTestData(database);

    //   final entriesToInsert = [
    //     LibraryListEntry(jmdictEntryId: null, kanji: '古'),
    //     LibraryListEntry(jmdictEntryId: null, kanji: '高'),
    //   ];

    //   await database.libraryListInsertEntries(
    //     'Test Library 1',
    //     entriesToInsert,
    //   );

    //   final listPage = (await database.libraryListGetListEntries(
    //     'Test Library 1',
    //   ))!;
    //   expect(listPage.entries.length, 6);
    //   expect(listPage.entries[4].kanji, '古');
    //   expect(listPage.entries[5].kanji, '高');
    // });

    // test('Bulk insert does not insert duplicates', () async {
    //   await insertTestData(database);

    //   final entriesToInsert = [
    //     LibraryListEntry(jmdictEntryId: null, kanji: '漢'),
    //     LibraryListEntry(jmdictEntryId: null, kanji: '新'),
    //   ];

    //   await database.libraryListInsertEntries(
    //     'Test Library 1',
    //     entriesToInsert,
    //   );

    //   final listPage = (await database.libraryListGetListEntries(
    //     'Test Library 1',
    //   ))!;
    //   expect(listPage.entries.length, 5);
    //   expect(listPage.entries[4].kanji, '新');
    // });
  });
}
