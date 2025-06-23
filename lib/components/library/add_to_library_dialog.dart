import 'package:flutter/material.dart';
import 'package:mugiten/models/history/history_entry.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:sqflite/sqflite.dart';
import 'package:jadb/search.dart';

import '../../models/library/library_list.dart';
import '../common/kanji_box.dart';
import '../common/loading.dart';

Future<void> showAddToLibraryDialog({
  required BuildContext context,
  required int? jmdictEntryId,
  required String? kanji,
}) =>
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddToLibraryDialog(
        jmdictEntryId: jmdictEntryId,
        kanji: kanji,
      ),
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
  Map<LibraryList, bool>? librariesContainEntry;

  /// A lock to make sure that the local data and the database doesn't
  /// get out of sync.
  bool toggleLock = false;

  @override
  void initState() {
    super.initState();

    LibraryList.allListsContains(
      jmdictEntryId: widget.jmdictEntryId,
      kanji: widget.kanji,
    ).then((data) => setState(() => librariesContainEntry = data));
  }

  Future<void> toggleEntry({required LibraryList lib}) async {
    if (toggleLock) return;

    setState(() => toggleLock = true);

    await lib.toggleEntry(
      jmdictEntryId: widget.jmdictEntryId,
      kanji: widget.kanji,
    );

    setState(() {
      toggleLock = false;
      librariesContainEntry![lib] = !librariesContainEntry![lib]!;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      future: GetIt.instance
                          .get<Database>()
                          .jadbGetWordById(widget.jmdictEntryId!),
                      builder: (context, snapshot) {
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
                      children: librariesContainEntry!.entries.map((e) {
                        final lib = e.key;
                        final checked = e.value;
                        return ListTile(
                          onTap: () => toggleEntry(lib: lib),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 5),
                          title: Row(
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: (_) => toggleEntry(lib: lib),
                              ),
                              Text(lib.name),
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
