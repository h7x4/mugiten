import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/database/history/table_names.dart';
import 'package:mugiten/models/history_entry.dart';
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

  group('Export-import history', () {
    test('Full reimport', () async {
      final historyEntries = await createRandomHistoryEntries(
        db: database,
        count: 300,
      );
      await database.historyEntryInsertEntries(historyEntries);
      final historyEntryAmount = await database.historyEntryAmount();
      assert(
        historyEntryAmount == historyEntries.length,
        'History entry amount should be ${historyEntries.length}, but got $historyEntryAmount',
      );

      await exportHistoryTo(database, tmpdir);
      assert(
        tmpdir.historyFile.existsSync(),
        'History file should exist at ${tmpdir.historyFile.path}',
      );

      await database.delete(HistoryTableNames.historyEntry);
      final int emptyHistoryEntryAmount = await database.historyEntryAmount();
      assert(
        emptyHistoryEntryAmount == 0,
        'History entry amount should be 0 after deletion, but got $emptyHistoryEntryAmount',
      );

      await importHistoryFrom(database, tmpdir.historyFile);
      final int importedHistoryEntryAmount = await database
          .historyEntryAmount();
      assert(
        importedHistoryEntryAmount == historyEntries.length,
        'History entry amount should be ${historyEntries.length} after import, but got $importedHistoryEntryAmount',
      );
    });

    test('Partially delete, idempotent reimport', () async {
      final historyEntries = await createRandomHistoryEntries(
        db: database,
        count: 300,
      );
      await database.historyEntryInsertEntries(historyEntries);
      final historyEntryAmount = await database.historyEntryAmount();
      assert(
        historyEntryAmount == historyEntries.length,
        'History entry amount should be ${historyEntries.length}, but got $historyEntryAmount',
      );

      await exportHistoryTo(database, tmpdir);
      assert(
        tmpdir.historyFile.existsSync(),
        'History file should exist at ${tmpdir.historyFile.path}',
      );

      final List<HistoryEntry> entriesToDelete = historyEntries.sublist(
        0,
        historyEntries.length ~/ 2,
      );
      final b = database.batch()
        ..delete(
          HistoryTableNames.historyEntry,
          where:
              'id IN (${List.filled(entriesToDelete.length, '?').join(',')})',
          whereArgs: entriesToDelete.map((final e) => e.id).toList(),
        );
      await b.commit(noResult: true);

      await importHistoryFrom(database, tmpdir.historyFile);
      final int importedHistoryEntryAmount = await database
          .historyEntryAmount();
      assert(
        importedHistoryEntryAmount == historyEntries.length,
        'History entry amount should be ${historyEntries.length} after import, but got $importedHistoryEntryAmount',
      );
    });

    test('Do not delete, idempotent reimport', () async {
      final historyEntries = await createRandomHistoryEntries(
        db: database,
        count: 300,
      );
      await database.historyEntryInsertEntries(historyEntries);
      final historyEntryAmount = await database.historyEntryAmount();
      assert(
        historyEntryAmount == historyEntries.length,
        'History entry amount should be ${historyEntries.length}, but got $historyEntryAmount',
      );

      await exportHistoryTo(database, tmpdir);
      assert(
        tmpdir.historyFile.existsSync(),
        'History file should exist at ${tmpdir.historyFile.path}',
      );

      await importHistoryFrom(database, tmpdir.historyFile);
      final int importedHistoryEntryAmount = await database
          .historyEntryAmount();
      assert(
        importedHistoryEntryAmount == historyEntries.length,
        'History entry amount should be ${historyEntries.length} after import, but got $importedHistoryEntryAmount',
      );
    });
  });
}
