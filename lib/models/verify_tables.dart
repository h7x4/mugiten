import 'package:mugiten/services/database/history/table_names.dart';
import 'package:mugiten/services/database/library_list/table_names.dart';
import 'package:sqflite/sqflite.dart';

Future<void> verifyMugitenTablesWithDbConnection(
  final DatabaseExecutor db,
) async {
  final Set<String> tables = await db
      .query(
        'sqlite_master',
        columns: ['name'],
        where: 'type IN (?, ?)',
        whereArgs: ['table', 'view'],
      )
      .then((final result) {
        return result.map((final row) => row['name'] as String).toSet();
      });

  final Set<String> expectedTables = {
    ...HistoryTableNames.allTables,
    ...LibraryListTableNames.allTables,
  };

  final missingTables = expectedTables.difference(tables);

  if (missingTables.isNotEmpty) {
    throw Exception(
      [
        'Missing tables:',
        missingTables.map((final table) => '  - $table').join('\n'),
        '',
        'Found tables:\n',
        tables.map((final table) => '  - $table').join('\n'),
        '',
        'Please ensure the database is correctly set up.',
      ].join('\n'),
    );
  }
}
