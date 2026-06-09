import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/models/word_search/word_search_match_span.dart';
import 'package:jadb/models/word_search/word_search_result.dart';
import 'package:jadb/util/text_filtering.dart';
import 'package:mugiten/components/library/add_to_library_dialog.dart';
import 'package:mugiten/components/search/search_results_body/parts/common_badge.dart';
import 'package:mugiten/components/search/search_results_body/parts/header.dart';
import 'package:mugiten/components/search/search_results_body/parts/jlpt_badge.dart';
import 'package:mugiten/components/search/search_results_body/parts/kanji.dart';
import 'package:mugiten/components/search/search_results_body/parts/other_forms.dart';
import 'package:mugiten/components/search/search_results_body/parts/senses.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/services/clipboard.dart';
import 'package:mugiten/settings.dart';
import 'package:sqflite/sqlite_api.dart';

class SearchResultCard extends StatefulWidget {
  final WordSearchResult result;
  final List<SlidableAction>? slidableActions;
  final Widget? leading;
  final Color? backgroundColor;
  final bool allowQuickAddLibraryList;
  final bool initiallyExpanded;

  const SearchResultCard({
    required this.result,
    this.slidableActions,
    this.leading,
    this.backgroundColor,
    this.allowQuickAddLibraryList = true,
    this.initiallyExpanded = false,
    super.key,
  });

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> {
  final ExpansibleController expansionController = ExpansibleController();

  bool get hasAttribution =>
      widget.result.sources.jmdict || widget.result.sources.jmnedict;

  bool isFavourited = false;
  bool isQuickListed = false;

  // TODO: only fetch data from the lists we actually care about
  Future<void> fetchFavouriteAndQuickListStatus() => GetIt.instance
      .get<Database>()
      .libraryListAllListsContain(jmdictEntryId: widget.result.entryId)
      .then(
        (final data) => setState(() {
          isFavourited = data['favourites'] ?? false;
          isQuickListed =
              quickAddLibraryList.value != null &&
              (data[quickAddLibraryList.value!] ?? false);
        }),
      );

  @override
  void initState() {
    super.initState();
    unawaited(fetchFavouriteAndQuickListStatus());
  }

  List<String> get kanji => kanjiRegex
      .allMatches(
        widget.result.japanese
            .map((final w) => '${w.base}${w.furigana ?? ""}')
            .join(),
      )
      .map((final match) => match.group(0)!)
      .toSet()
      .toList();

  Widget get _header {
    final firstMatchSpans =
        widget.result.matchSpans
            ?.where((final span) => span.index == 0)
            .toList(growable: false) ??
        [];
    final colorSpanBase = firstMatchSpans
        .where((final span) => span.spanType == WordSearchMatchSpanType.kanji)
        .map((final span) => (span.start, span.end))
        .firstOrNull;
    final colorSpanFurigana = firstMatchSpans
        .where((final span) => span.spanType == WordSearchMatchSpanType.kana)
        .map((final span) => (span.start, span.end))
        .firstOrNull;

    return IntrinsicWidth(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // TODO: draw sizedbox to take up space instead
              if (!quickAddLibraryList.contains('favourites'))
                Icon(
                  Icons.bookmark,
                  color: isQuickListed ? Colors.blue : Colors.transparent,
                  size: 20,
                ),
              Icon(
                Icons.star,
                color: isFavourited ? Colors.yellow : Colors.transparent,
                size: 20,
              ),
            ],
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => expansionController.isExpanded
                  ? expansionController.collapse()
                  : expansionController.expand(),
              onLongPress: () => copyToClipboard(
                context,
                widget.result.japanese.firstOrNull?.base,
              ),
              onDoubleTap: widget.allowQuickAddLibraryList
                  ? () {
                      if (isQuickListed && quickAddLibraryList.value != null) {
                        unawaited(
                          GetIt.instance
                              .get<Database>()
                              .libraryListDeleteEntry(
                                quickAddLibraryList.value!,
                                jmdictEntryId: widget.result.entryId,
                              )
                              .then((_) => fetchFavouriteAndQuickListStatus()),
                        );
                      } else {
                        unawaited(
                          GetIt.instance
                              .get<Database>()
                              .libraryListInsertEntry(
                                quickAddLibraryList.value!,
                                jmdictEntryId: widget.result.entryId,
                              )
                              .then((_) => fetchFavouriteAndQuickListStatus()),
                        );
                      }
                    }
                  : null,
              child: JapaneseHeader(
                baseWord: widget.result.japanese[0].base,
                furigana: widget.result.japanese[0].furigana,
                dimBase: widget.result.hasUnusualKanji,
                colorSpanBase: colorSpanBase,
                colorSpanFurigana: colorSpanFurigana,
              ),
            ),
          ),
          Row(
            children: [
              JLPTBadge(jlptLevel: widget.result.jlptLevel.toNullableString()),
              CommonBadge(isCommon: widget.result.isCommon),
            ],
          ),
        ],
      ),
    );
  }

  static const _margin = SizedBox(height: 20);

  List<Widget> _withMargin(final Widget w) => [_margin, w];

  Widget _body() {
    final List<WordSearchMatchSpan>? matchSpans = widget.result.matchSpans
        ?.where((final span) => span.index != 0)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Senses(senses: widget.result.senses),

          if (widget.result.japanese.length > 1)
            ..._withMargin(
              OtherForms(
                forms: widget.result.japanese.sublist(1),
                matchSpans: matchSpans,
              ),
            ),

          // TODO:
          // if (extendedData != null && extendedData.notes.isNotEmpty)
          //   ..._withMargin(Notes(notes: extendedData.notes)),
          if (kanji.isNotEmpty) ..._withMargin(KanjiRow(kanji: kanji)),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final backgroundColor =
        widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Slidable(
      key: ValueKey('slidable-${widget.result.entryId}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children:
            widget.slidableActions ??
            [
              SlidableAction(
                backgroundColor: Colors.yellow,
                icon: Icons.star,
                onPressed: (_) => GetIt.instance
                    .get<Database>()
                    .libraryListToggleEntry(
                      'favourites',
                      jmdictEntryId: widget.result.entryId,
                    )
                    .then((_) => setState(() => isFavourited = !isFavourited)),
              ),
              SlidableAction(
                backgroundColor: Colors.blue,
                icon: Icons.bookmark,
                onPressed: (final context) => showAddToLibraryDialog(
                  context: context,
                  jmdictEntryId: widget.result.entryId,
                  kanji: null,
                ).then((_) => fetchFavouriteAndQuickListStatus()),
              ),
            ],
      ),
      child: ExpansionTile(
        controller: expansionController,
        leading: widget.leading,
        collapsedBackgroundColor: backgroundColor,
        backgroundColor: backgroundColor,
        initiallyExpanded: widget.initiallyExpanded,
        title: _header,
        children: [_body()],
      ),
    );
  }
}
