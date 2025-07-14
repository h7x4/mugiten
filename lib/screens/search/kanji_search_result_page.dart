import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/models/kanji_search/kanji_search_result.dart';
import 'package:jadb/search.dart';
import 'package:mdi/mdi.dart';
import 'package:mugiten/components/library/add_to_library_dialog.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/services/snackbar.dart';
import 'package:mugiten/settings.dart';
import 'package:sqflite/sqflite.dart';

import '../../components/kanji/kanji_result_body/grade.dart';
import '../../components/kanji/kanji_result_body/header.dart';
import '../../components/kanji/kanji_result_body/jlpt_level.dart';
import '../../components/kanji/kanji_result_body/radical.dart';
import '../../components/kanji/kanji_result_body/rank.dart';
import '../../components/kanji/kanji_result_body/stroke_order_gif.dart';
import '../../components/kanji/kanji_result_body/yomi_chips.dart';

class KanjiSearchResultPage extends StatefulWidget {
  final String kanji;

  const KanjiSearchResultPage({required this.kanji, super.key});

  @override
  State<KanjiSearchResultPage> createState() => _KanjiSearchResultPageState();
}

class _KanjiSearchResultPageState extends State<KanjiSearchResultPage> {
  bool addedToDatabase = false;
  bool isFavourite = false;

  // TODO: add compart link
  Widget _headerRow(KanjiSearchResult result) => Container(
        margin: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Flexible(
              fit: FlexFit.tight,
              child: SizedBox(),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: Center(child: Header(kanji: result.kanji)),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: Center(
                child: (result.radical != null)
                    ? Radical(radical: result.radical!.symbol)
                    : const SizedBox(),
              ),
            ),
          ],
        ),
      );

  Widget _rankingColumn(KanjiSearchResult result) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('JLPT: ', style: TextStyle(fontSize: 20.0)),
              JlptLevel(jlptLevel: result.jlptLevel ?? '⨉'),
            ],
          ),
          Row(
            children: [
              const Text('Grade: ', style: TextStyle(fontSize: 20.0)),
              Grade(
                  grade: {
                1: '小1',
                2: '小2',
                3: '小3',
                4: '小4',
                5: '小5',
                6: '小6',
                8: '中',
                9: '名',
                10: '名',
                null: null,
              }[result.taughtIn]),
            ],
          ),
          Row(
            children: [
              const Text('Rank: ', style: TextStyle(fontSize: 20.0)),
              Rank(rank: result.newspaperFrequencyRank),
            ],
          ),
        ],
      );

  String _gifUri(String kanji) {
    final String charcode =
        kanji.characters.first.codeUnits.map((c) => c.toRadixString(16)).join();
    return "https://raw.githubusercontent.com/mistval/kanji_images/master/gifs/$charcode.gif";
  }

  Widget _body(KanjiSearchResult result) {
    return Scaffold(
      appBar: AppBar(actions: [
        if (incognitoModeEnabled)
          IconButton(
            icon: const Icon(Mdi.incognito),
            onPressed: () =>
                showSnackbar(context, 'History tracking is disabled'),
          ),
        IconButton(
          icon: const Icon(Icons.star),
          color: isFavourite ? Colors.yellow : null,
          onPressed: () {
            GetIt.instance
                .get<Database>()
                .libraryListToggleEntry(
                  "favourites",
                  jmdictEntryId: null,
                  kanji: result.kanji,
                )
                .then((state) => setState(() => isFavourite = state));
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark),
          onPressed: () => showAddToLibraryDialog(
            context: context,
            jmdictEntryId: null,
            kanji: result.kanji,
          ),
        ),
      ]),
      body: ListView(
        children: [
          _headerRow(result),
          YomiChips(yomi: result.meanings, type: YomiType.meaning),
          (result.onyomi.isNotEmpty)
              ? YomiChips(yomi: result.onyomi, type: YomiType.onyomi)
              : const SizedBox.shrink(),
          (result.kunyomi.isNotEmpty)
              ? YomiChips(yomi: result.kunyomi, type: YomiType.kunyomi)
              : const SizedBox.shrink(),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StrokeOrderGif(uri: _gifUri(result.kanji)),
                _rankingColumn(result),
              ],
            ),
          ),

          // TODO:
          // Examples(
          //   onyomi: resultData.onyomiExamples,
          //   kunyomi: resultData.kunyomiExamples,
          // ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    GetIt.instance
        .get<Database>()
        .libraryListListContains(
          "favourites",
          kanji: widget.kanji,
        )
        .then((value) => setState(() => isFavourite = value));

    if (!incognitoModeEnabled && !addedToDatabase) {
      GetIt.instance
          .get<Database>()
          .historyEntryInsertKanji(widget.kanji)
          .then((_) => setState(() => addedToDatabase = true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GetIt.instance.get<Database>().jadbSearchKanji(widget.kanji),
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorWidget(snapshot.error!);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return ErrorWidget(snapshot.error!);

        return _body(snapshot.data!);
      },
    );
  }
}
