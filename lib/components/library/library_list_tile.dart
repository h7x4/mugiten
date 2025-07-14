import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../routing/routes.dart';

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
                // TODO: ask for confirmation before deleting
                SlidableAction(
                  backgroundColor: Colors.red,
                  icon: Icons.delete,
                  onPressed: (_) async {
                    await GetIt.instance
                        .get<Database>()
                        .libraryListDeleteList(library.name);
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
            Text('${library.totalCount} items'),
          ],
        ),
      ),
    );
  }
}
