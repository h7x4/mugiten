import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<String> extractJadbFromAssets() async {
  final Directory appDocDir = await getApplicationCacheDirectory();
  final String jadbPath = appDocDir.uri.resolve('jadb.sqlite').path;
  final File jadbFile = File(jadbPath);

  if (!await jadbFile.exists()) {
    jadbFile.createSync();
  }

  ByteData data = await rootBundle.load('assets/jadb.sqlite');
  await jadbFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

  return jadbPath;
}

Future<void> setupJadb() async {
  final jadbPath = await extractJadbFromAssets();

  final db = await openDatabase(
    jadbPath,
    onConfigure: (db) async {
      await db.execute("PRAGMA foreign_keys = ON");
    },
    readOnly: true,
  );

  GetIt.instance.registerSingleton<Database>(db);
}
