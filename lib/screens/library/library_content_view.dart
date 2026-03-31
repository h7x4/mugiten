import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mugiten/components/library/library_list_entry_tile.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:sqflite/sqlite_api.dart';

const int pageSize = 50;
const int invisibleItemsThreshold = 25;

class LibraryContentView extends StatefulWidget {
  final LibraryList library;
  const LibraryContentView({super.key, required this.library});

  @override
  State<LibraryContentView> createState() => _LibraryContentViewState();
}

class _LibraryContentViewState extends State<LibraryContentView> {
  late final _pagingController = PagingController<int, LibraryListEntry>(
    getNextPageKey: (final state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (final pageKey) => GetIt.instance
        .get<Database>()
        .libraryListGetListEntries(
          widget.library.name,
          page: pageKey - 1,
          pageSize: pageSize,
          includeSearchResult: true,
        )
        .then((final page) => page?.entries ?? []),
  );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<bool> _confirm(
    final BuildContext context, {
    required final Widget content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (final context) => AlertDialog(
            content: content,
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name),
        actions: [
          IconButton(
            onPressed: () async {
              final entryCount = widget.library.totalCount;
              if (!context.mounted) return;
              final bool userIsSure = await _confirm(
                context,
                content: Text(
                  'Are you sure that you want to clear all $entryCount entries?',
                ),
              );
              if (!userIsSure) return;

              await GetIt.instance.get<Database>().libraryListDeleteAllEntries(
                widget.library.name,
              );

              _pagingController.refresh();
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: PagingListener(
        controller: _pagingController,
        builder: (final context, final state, final fetchNextPage) =>
            PagedListView<int, LibraryListEntry>.separated(
              state: state,
              fetchNextPage: fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate<LibraryListEntry>(
                invisibleItemsThreshold: invisibleItemsThreshold,
                itemBuilder: (final context, final entry, final index) =>
                    LibraryListEntryTile(
                      key: ValueKey(
                        entry.jmdictEntryId != null
                            ? 'jmdict-${entry.jmdictEntryId}'
                            : 'kanji-${entry.kanji}',
                      ),
                      index: index,
                      entry: entry,
                      library: widget.library,
                      onDelete: () => _pagingController.refresh(),
                      onUpdate: () => _pagingController.refresh(),
                    ),
                firstPageErrorIndicatorBuilder: (_) =>
                    ErrorWidget(_pagingController.error!),
                noItemsFoundIndicatorBuilder: (_) =>
                    const Center(child: Text('List is empty')),
              ),
              separatorBuilder: (_, _) =>
                  const Divider(height: 0, indent: 10, endIndent: 10),
            ),
      ),
    );
  }
}
