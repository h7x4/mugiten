import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/models/word_search/word_search_result.dart';
import 'package:jadb/util/text_filtering.dart';
import 'package:mugiten/components/library/add_to_library_dialog.dart';
import 'package:mugiten/models/library/library_list.dart';
import 'package:sqflite/sqlite_api.dart';

import './parts/common_badge.dart';
import './parts/header.dart';
import './parts/jlpt_badge.dart';
import './parts/other_forms.dart';
import './parts/senses.dart';
import 'parts/kanji.dart';

class SearchResultCard extends StatefulWidget {
  final WordSearchResult result;
  final List<SlidableAction>? slidableActions;
  final Widget? leading;

  const SearchResultCard({
    required this.result,
    this.slidableActions,
    this.leading,
    super.key,
  });

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> {
  bool get hasAttribution =>
      widget.result.sources.jmdict || widget.result.sources.jmnedict;

  List<String> get kanji => kanjiRegex
      .allMatches(
        widget.result.japanese
            .map((w) => '${w.base}${w.furigana ?? ""}')
            .join(),
      )
      .map((match) => match.group(0)!)
      .toSet()
      .toList();

  Widget get _header => IntrinsicWidth(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            JapaneseHeader(
              baseWord: widget.result.japanese[0].base,
              furigana: widget.result.japanese[0].furigana,
            ),
            Row(
              children: [
                JLPTBadge(
                    jlptLevel: widget.result.jlptLevel.toNullableString()),
                CommonBadge(isCommon: widget.result.isCommon)
              ],
            )
          ],
        ),
      );

  static const _margin = SizedBox(height: 20);

  List<Widget> _withMargin(Widget w) => [_margin, w];

  Widget _body() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Senses(
              senses: widget.result.senses,
            ),

            if (widget.result.japanese.length > 1)
              ..._withMargin(
                  OtherForms(forms: widget.result.japanese.sublist(1))),

            // TODO:
            // if (extendedData != null && extendedData.notes.isNotEmpty)
            //   ..._withMargin(Notes(notes: extendedData.notes)),

            if (kanji.isNotEmpty) ..._withMargin(KanjiRow(kanji: kanji)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: widget.slidableActions ??
            [
              SlidableAction(
                backgroundColor: Colors.yellow,
                icon: Icons.star,
                onPressed: (_) => LibraryList.favourites.toggleEntry(
                  db: GetIt.instance.get<Database>(),
                  jmdictEntryId: widget.result.entryId,
                  kanji: null,
                ),
              ),
              SlidableAction(
                backgroundColor: Colors.blue,
                icon: Icons.bookmark,
                onPressed: (context) => showAddToLibraryDialog(
                  context: context,
                  jmdictEntryId: widget.result.entryId,
                  kanji: null,
                ),
              ),
            ],
      ),
      child: ExpansionTile(
        leading: widget.leading,
        collapsedBackgroundColor: backgroundColor,
        backgroundColor: backgroundColor,
        // onExpansionChanged: (b) async { },
        title: _header,
        children: [_body()],
      ),
    );
  }
}
