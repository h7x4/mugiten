import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/components/common/async_text_form_field.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/services/library_lists_controller.dart';
import 'package:sqflite/sqlite_api.dart';

class LibraryListTile extends StatelessWidget {
  final Widget? leading;
  final LibraryList library;
  final void Function()? onDelete;
  final void Function(String, String)? onRename;
  final bool isEditable;

  const LibraryListTile({
    super.key,
    required this.library,
    this.leading,
    this.onDelete,
    this.onRename,
    this.isEditable = true,
  });

  @override
  Widget build(final BuildContext context) {
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
                    final String oldName = library.name;

                    final String? newName = await showDialog<String>(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => _RenameLibraryDialog(oldName: oldName),
                    );

                    if (newName == null) {
                      return;
                    }

                    await GetIt.instance.get<LibraryListsController>().rename(
                      oldName,
                      newName,
                    );
                    onRename?.call(oldName, newName);
                  },
                ),
                // TODO: ask for confirmation before deleting
                SlidableAction(
                  backgroundColor: Colors.red,
                  icon: Icons.delete,
                  onPressed: (_) async {
                    await GetIt.instance.get<LibraryListsController>().delete(
                      library.name,
                    );
                    onDelete?.call();
                  },
                ),
              ],
      ),
      child: ListTile(
        leading: leading,
        onTap: () =>
            Navigator.pushNamed(context, Routes.library, arguments: library),
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

class _RenameLibraryDialog extends StatefulWidget {
  final String oldName;

  const _RenameLibraryDialog({required this.oldName});

  @override
  State<_RenameLibraryDialog> createState() => _RenameLibraryDialogState();
}

class _RenameLibraryDialogState extends State<_RenameLibraryDialog> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.oldName;
  }

  @override
  Widget build(final BuildContext context) {
    return AlertDialog(
      title: const Text('Rename library'),
      content: AsyncTextFormField(
        controller: controller,
        asyncValidator: (final value) async {
          if (value == null || value.isEmpty) {
            return 'Please enter a name';
          }
          if (value == 'favourites') {
            return 'This name is reserved';
          }
          if (value != widget.oldName &&
              await GetIt.instance.get<Database>().libraryListExists(value)) {
            return 'A library with this name already exists';
          }
          return null;
        },
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
