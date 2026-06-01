import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jadb/search.dart';
import 'package:jadb/table_names/jmdict.dart';
import 'package:jadb/table_names/kanjidic.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/services/database/database.dart';
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

  final database = await resetDatabase(jadbCopyPath);

  assert(database.isOpen, 'Failed to open database copy at $jadbCopyPath');

  return database;
}

Future<List<LibraryListEntry>> createRandomLibraryListEntries({
  required final DatabaseExecutor db,
  final int kanjiCount = 10,
  final int jmdictEntryCount = 10,
}) async {
  final kanji = (await db.query(
    KANJIDICTableNames.character,
    columns: ['literal'],
    limit: kanjiCount,
    orderBy: 'RANDOM()',
  )).map((final row) => row['literal'] as String).toList();

  final jmdictEntries = (await db.query(
    JMdictTableNames.entry,
    columns: ['entryId'],
    limit: jmdictEntryCount,
    orderBy: 'RANDOM()',
  )).map((final row) => row['entryId'] as int).toList();

  final rng = Random();
  final result = <LibraryListEntry>[];
  for (int i = 0; i < kanjiCount + jmdictEntryCount; i++) {
    if (rng.nextBool() && kanji.isNotEmpty || jmdictEntries.isEmpty) {
      result.add(LibraryListEntry.fromKanji(kanji: kanji.removeLast()));
    } else {
      result.add(
        LibraryListEntry.fromJmdictId(
          jmdictEntryId: jmdictEntries.removeLast(),
        ),
      );
    }
  }

  return result;
}

// TODO: fix the timestamps so that they differ within each entry.

Future<List<HistoryEntry>> createRandomHistoryEntries({
  required final DatabaseExecutor db,
  final int count = 20,
}) async {
  final kanji = (await db.query(
    KANJIDICTableNames.character,
    columns: ['literal'],
    limit: (count / 2).ceil(),
    orderBy: 'RANDOM()',
  )).map((final row) => row['literal'] as String).toList();

  final jmdictIds = (await db.query(
    JMdictTableNames.entry,
    columns: ['entryId'],
    limit: (count / 2).ceil(),
    orderBy: 'RANDOM()',
  )).map((final row) => row['entryId'] as int).toList();

  final wordSearchResults = await db.jadbGetManyWordsByIds(jmdictIds.toSet());

  final rng = Random();
  final result = <HistoryEntry>[];
  for (int i = 0; i < count; i++) {
    if (rng.nextBool() && kanji.isNotEmpty || jmdictIds.isEmpty) {
      result.add(
        HistoryEntry(
          id: i,
          timestamps: [
            for (int j = 0; j < rng.nextInt(5) + 1; j++)
              DateTime.now().subtract(Duration(days: rng.nextInt(30))),
          ],
          word: null,
          kanji: kanji.removeLast(),
        ),
      );
    } else {
      final entryId = jmdictIds.removeLast();
      result.add(
        HistoryEntry(
          timestamps: [
            for (int j = 0; j < rng.nextInt(5) + 1; j++)
              DateTime.now().subtract(Duration(days: rng.nextInt(30))),
          ],
          id: i,
          word: wordSearchResults[entryId]!.japanese.first.base,
          kanji: null,
        ),
      );
    }
  }

  return result;
}

Future<Directory> testTmpdir() =>
    Directory.systemTemp.createTemp('mugiten_test_data_');
