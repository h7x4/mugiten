import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/database/database.dart';

class DebugView extends StatelessWidget {
  const DebugView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GetIt.instance.get<Database>().rawQuery(
        """
        SELECT name, type
        FROM sqlite_master
        WHERE name NOT LIKE 'sqlite_%'
        ORDER BY name
        """,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorWidget(snapshot.error!);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Debug View'),
          ),
          body: ListView.builder(
            itemCount: (snapshot.data as List<Map<String, dynamic>>).length,
            itemBuilder: (context, index) {
              final data = (snapshot.data as List<Map<String, dynamic>>)[index];
              final tableName = (data['name'] as String) +
                  (data['type'] == 'table' ? '' : ' (${data['type']})');
              return ListTile(
                title: Text(tableName),
                onTap: () {
                  // Handle table tap if needed
                },
              );
            },
          ),
        );
      },
    );
  }
}
