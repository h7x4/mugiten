import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/components/common/loading.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:sqflite/sqflite.dart';

Future<void> showAddToLibraryDialog({
  required final BuildContext context,
  required final int? jmdictEntryId,
  required final String? kanji,
}) => showDialog(
  context: context,
  barrierDismissible: true,
  builder: (_) =>
      AddToLibraryDialog(jmdictEntryId: jmdictEntryId, kanji: kanji),
);

class AddToLibraryDialog extends StatefulWidget {
  final int? jmdictEntryId;
  final String? kanji;

  const AddToLibraryDialog({
    super.key,
    required this.jmdictEntryId,
    required this.kanji,
  });

  @override
  State<AddToLibraryDialog> createState() => _AddToLibraryDialogState();
}

class _AddToLibraryDialogState extends State<AddToLibraryDialog> {
  Map<String, bool>? librariesContainEntry;

  /// A lock to make sure that the local data and the database doesn't
  /// get out of sync.
  bool toggleLock = false;

  @override
  void initState() {
    super.initState();

    unawaited(
      GetIt.instance
          .get<Database>()
          .libraryListAllListsContain(
            jmdictEntryId: widget.jmdictEntryId,
            kanji: widget.kanji,
          )
          .then((final data) => setState(() => librariesContainEntry = data)),
    );
  }

  Future<void> toggleEntry(final String libraryName) async {
    if (toggleLock) return;

    setState(() => toggleLock = true);

    await GetIt.instance.get<Database>().libraryListToggleEntry(
      libraryName,
      jmdictEntryId: widget.jmdictEntryId,
      kanji: widget.kanji,
    );

    setState(() {
      toggleLock = false;
      librariesContainEntry![libraryName] =
          !librariesContainEntry![libraryName]!;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return AlertDialog(
      title: const Text('Add to library'),
      contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      content: Column(
        children: [
          ListTile(
            title: Center(
              child: widget.kanji != null
                  // TODO: fix
                  // ? KanjiBox.headline4(
                  //     context: context,
                  //     kanji: widget.kanji!,
                  //   )
                  ? Text(
                      widget.kanji!,
                      style: Theme.of(context).textTheme.displayMedium,
                    )
                  : FutureBuilder(
                      future: GetIt.instance.get<Database>().jadbGetWordById(
                        widget.jmdictEntryId!,
                      ),
                      builder: (final context, final snapshot) {
                        if (snapshot.hasError) {
                          return ErrorWidget(snapshot.error!);
                        }

                        if (!snapshot.hasData) {
                          return const LoadingScreen();
                        }

                        final entry = snapshot.data!;
                        final japaneseWord = entry.japanese.firstOrNull;

                        assert(
                          japaneseWord != null,
                          'Japanese word should not be null',
                        );

                        if (japaneseWord == null) {
                          return const Text('???');
                        }

                        return RubySpanWidget(
                          RubyTextData(
                            japaneseWord.base,
                            ruby: japaneseWord.furigana,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(thickness: 3),
          Expanded(
            child: SizedBox(
              width: double.maxFinite,
              child: librariesContainEntry == null
                  ? const LoadingScreen()
                  : ListView(
                      children: librariesContainEntry!.entries.map((final e) {
                        final libraryName = e.key;
                        final checked = e.value;
                        return ListTile(
                          onTap: () => toggleEntry(libraryName),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 5,
                          ),
                          title: Row(
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: (_) => toggleEntry(libraryName),
                              ),
                              Text(libraryName),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
