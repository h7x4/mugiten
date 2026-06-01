import 'package:mugiten/services/database/schemas/v2/table_names.dart';
import 'package:sqflite/sqflite.dart';

Future<void> verifyMugitenTablesWithDbConnection(
  final DatabaseExecutor db, {
  final Set<String> expectedTables = allSchemaV2TableNames,
}) async {
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
