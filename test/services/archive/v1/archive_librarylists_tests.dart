import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../../testutils.dart';

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
}
