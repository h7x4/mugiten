import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqlite_api.dart';
import '../../models/library/library_list.dart';

void Function() showNewLibraryDialog(context) => () async {
      final String? listName = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const NewLibraryDialog(),
      );
      if (listName == null) return;
      LibraryList.insert(
        GetIt.instance.get<Database>(),
        listName,
      );
    };

class NewLibraryDialog extends StatefulWidget {
  const NewLibraryDialog({super.key});

  @override
  State<NewLibraryDialog> createState() => _NewLibraryDialogState();
}

enum _NameState {
  initial,
  currentlyChecking,
  invalid,
  alreadyExists,
  valid,
}

class _NewLibraryDialogState extends State<NewLibraryDialog> {
  final controller = TextEditingController();
  _NameState nameState = _NameState.initial;

  Future<void> onNameUpdate(proposedListName) async {
    setState(() => nameState = _NameState.currentlyChecking);
    if (proposedListName == '') {
      setState(() => nameState = _NameState.invalid);
      return;
    }

    final nameAlreadyExists = await LibraryList.exists(
      GetIt.instance.get<Database>(),
      proposedListName,
    );
    if (nameAlreadyExists) {
      setState(() => nameState = _NameState.alreadyExists);
    } else {
      setState(() => nameState = _NameState.valid);
    }
  }

  bool get errorStatus =>
      nameState == _NameState.invalid || nameState == _NameState.alreadyExists;
  String? get statusLabel => {
        _NameState.invalid: 'Invalid Name',
        _NameState.alreadyExists: 'Already Exists',
      }[nameState];
  bool get confirmButtonActive => nameState == _NameState.valid;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add new library'),
      content: TextField(
        decoration: InputDecoration(
          hintText: 'Library name',
          errorText: statusLabel,
        ),
        controller: controller,
        onChanged: onNameUpdate,
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: confirmButtonActive
              ? null
              : ElevatedButton.styleFrom(foregroundColor: Colors.grey),
          onPressed: confirmButtonActive
              ? () => Navigator.pop(context, controller.text)
              : () {},
          child: const Text('Add'),
        ),
      ],
    );
  }
}
