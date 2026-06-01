import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/components/common/loading.dart';
import 'package:mugiten/components/library/library_list_tile.dart';
import 'package:mugiten/services/library_lists_controller.dart';
import 'package:mugiten/settings.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryListsController controller = GetIt.instance
      .get<LibraryListsController>();
  late final Listenable listenable = Listenable.merge([
    controller,
    quickAddLibraryList,
  ]);

  @override
  void initState() {
    super.initState();
    unawaited(controller.load());
  }

  @override
  Widget build(final BuildContext context) => ListenableBuilder(
    listenable: listenable,
    builder: (final context, final child) {
      final libraries = controller.libraries;
      if (libraries == null) {
        return const LoadingScreen();
      }
      if (libraries.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          LibraryListTile(
            key: ValueKey(libraries.first.name),
            library: libraries.first,
            leading: const Icon(Icons.star),
            isEditable: false,
          ),
          Expanded(
            child: ListView(
              children: libraries
                  // Skip favourites
                  .skip(1)
                  .map(
                    (final e) => LibraryListTile(
                      key: ValueKey(e.name),
                      library: e,
                      leading: quickAddLibraryList.value == e.name
                          ? const Icon(Icons.bookmark, color: Colors.blue)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      );
    },
  );
}
