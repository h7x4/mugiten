import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<String> databasePath() async {
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  if (!appDocDir.existsSync()) appDocDir.createSync(recursive: true);
  return join(appDocDir.path, 'sembast.db');
}

Future<void> setupDatabase() async {
  final Database database =
      await databaseFactoryIo.openDatabase(await databasePath());
  GetIt.instance.registerSingleton<Database>(database);
}
