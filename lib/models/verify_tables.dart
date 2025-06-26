import 'package:mugiten/database/history/table_names.dart';
import 'package:mugiten/database/library_list/table_names.dart';
import 'package:sqflite/sqflite.dart';

Future<void> verifyMugitenTablesWithDbConnection(DatabaseExecutor db) async {
  final Set<String> tables = await db
      .query(
    'sqlite_master',
    columns: ['name'],
    where: 'type = ?',
    whereArgs: ['table'],
  )
      .then((result) {
    return result.map((row) => row['name'] as String).toSet();
  });

  final Set<String> expectedTables = {
    ...HistoryTableNames.allTables,
    ...LibraryListTableNames.allTables,
  };

  final missingTables = expectedTables.difference(tables);

  if (missingTables.isNotEmpty) {
    throw Exception([
      'Missing tables:',
      missingTables.map((table) => '  - $table').join('\n'),
      '',
      'Found tables:\n',
      tables.map((table) => '  - $table').join('\n'),
      '',
      'Please ensure the database is correctly set up.',
    ].join('\n'));
  }
}
