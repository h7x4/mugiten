import 'package:flutter/foundation.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/settings.dart';
import 'package:sqflite/sqlite_api.dart';

class LibraryListsController extends ChangeNotifier {
  final Database _database;
  List<LibraryList>? _libraries;
  Future<void> _pendingOperation = Future.value();
  bool _isDisposed = false;

  LibraryListsController(this._database);

  List<LibraryList>? get libraries => _libraries;

  Future<void> _refresh() async {
    _libraries = await _database.libraryListGetLists();
  }

  Future<void> _runOperation(final Future<void> Function() operation) {
    final nextOperation = _pendingOperation.catchError((final _) {}).then((
      final _,
    ) async {
      await operation();
      if (!_isDisposed) {
        notifyListeners();
      }
    });

    _pendingOperation = nextOperation;
    return nextOperation;
  }

  Future<void> load() => _runOperation(_refresh);

  Future<void> create(final String name) => _runOperation(() async {
    await _database.libraryListInsertList(name);
    await _refresh();
  });

  Future<void> rename(final String oldName, final String newName) =>
      _runOperation(() async {
        await _database.libraryListRenameList(oldName, newName);
        if (quickAddLibraryList.value == oldName) {
          quickAddLibraryList.value = newName;
        }
        await _refresh();
      });

  Future<void> delete(final String name) => _runOperation(() async {
    await _database.libraryListDeleteList(name);
    if (quickAddLibraryList.value == name) {
      quickAddLibraryList.value = null;
    }
    await _refresh();
  });

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
