import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../models/library/library_list.dart';
import '../../routing/routes.dart';
import '../common/loading.dart';

class LibraryListTile extends StatelessWidget {
  final Widget? leading;
  final LibraryList library;
  final void Function()? onDelete;
  final void Function()? onUpdate;
  final bool isEditable;

  const LibraryListTile({
    super.key,
    required this.library,
    this.leading,
    this.onDelete,
    this.onUpdate,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: !isEditable
            ? []
            : [
                SlidableAction(
                  backgroundColor: Colors.blue,
                  icon: Icons.edit,
                  onPressed: (_) async {
                    // TODO: update name
                    onUpdate?.call();
                  },
                ),
                SlidableAction(
                  backgroundColor: Colors.red,
                  icon: Icons.delete,
                  onPressed: (_) async {
                    await library.delete(
                      GetIt.instance.get<Database>(),
                    );
                    onDelete?.call();
                  },
                ),
              ],
      ),
      child: ListTile(
        leading: leading,
        onTap: () => Navigator.pushNamed(
          context,
          Routes.library,
          arguments: library,
        ),
        title: Row(
          children: [
            Expanded(child: Text(library.name)),
            FutureBuilder<int>(
              future: library.length(GetIt.instance.get<Database>()),
              builder: (context, snapshot) {
                if (snapshot.hasError) return ErrorWidget(snapshot.error!);
                if (!snapshot.hasData) return const LoadingScreen();
                return Text('${snapshot.data} items');
              },
            ),
          ],
        ),
      ),
    );
  }
}
