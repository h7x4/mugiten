import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:sqflite/sqlite_api.dart';

import '../testutils.dart';

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
  group('Merge history timestamps', () {
    test('Merge non-overlapping timestamps', () async {
      final historyEntry = await createRandomHistoryEntries(
        db: database,
        count: 1,
      ).then((final entries) => entries.first);
      historyEntry.timestamps.clear();
      historyEntry.timestamps.addAll([
        DateTime(2024, 1, 1),
        DateTime(2024, 2, 1),
        DateTime(2024, 3, 1),
      ]);
      await database.historyEntryInsertEntry(historyEntry);

      historyEntry.timestamps.clear();
      historyEntry.timestamps.addAll([
        DateTime(2024, 4, 1),
        DateTime(2024, 5, 1),
        DateTime(2024, 6, 1),
      ]);
      await database.historyEntryInsertEntry(historyEntry);

      final entries = await database.historyEntryGetAll();
      assert(
        entries.length == 1,
        'There should be only one history entry after merging, but got ${entries.length}',
      );
      final mergedTimestamps = entries.first.timestamps;
      assert(
        mergedTimestamps.length == 6,
        'Merged timestamps should have 6 entries, but got ${mergedTimestamps.length}',
      );
    });

    test('Merge partially overlapping timestamps', () async {
      final historyEntry = await createRandomHistoryEntries(
        db: database,
        count: 1,
      ).then((final entries) => entries.first);
      historyEntry.timestamps.clear();
      historyEntry.timestamps.addAll([
        DateTime(2024, 1, 1),
        DateTime(2024, 2, 1),
        DateTime(2024, 3, 1),
      ]);
      await database.historyEntryInsertEntry(historyEntry);

      historyEntry.timestamps.clear();
      historyEntry.timestamps.addAll([
        DateTime(2024, 2, 1),
        DateTime(2024, 3, 1),
        DateTime(2024, 4, 1),
      ]);
      await database.historyEntryInsertEntry(historyEntry);

      final entries = await database.historyEntryGetAll();
      assert(
        entries.length == 1,
        'There should be only one history entry after merging, but got ${entries.length}',
      );
      final mergedTimestamps = entries.first.timestamps;
      assert(
        mergedTimestamps.length == 4,
        'Merged timestamps should have 4 entries, but got ${mergedTimestamps.length}',
      );
    });

    test('Merge fully overlapping timestamps', () async {
      final historyEntry = await createRandomHistoryEntries(
        db: database,
        count: 1,
      ).then((final entries) => entries.first);
      historyEntry.timestamps.clear();
      historyEntry.timestamps.addAll([
        DateTime(2024, 1, 1),
        DateTime(2024, 2, 1),
        DateTime(2024, 3, 1),
      ]);
      await database.historyEntryInsertEntry(historyEntry);
      await database.historyEntryInsertEntry(historyEntry);

      final entries = await database.historyEntryGetAll();
      assert(
        entries.length == 1,
        'There should be only one history entry after merging, but got ${entries.length}',
      );
      final mergedTimestamps = entries.first.timestamps;
      assert(
        mergedTimestamps.length == 3,
        'Merged timestamps should have 3 entries, but got ${mergedTimestamps.length}',
      );
    });
  });
}
