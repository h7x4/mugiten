import 'package:get_it/get_it.dart';
import 'package:sembast/sembast.dart';

import './kanji_query.dart';
import './word_query.dart';

class Search {
  final WordQuery? wordQuery;
  final KanjiQuery? kanjiQuery;
  final List<DateTime> timestamps;

  Search.fromKanjiQuery({
    required KanjiQuery this.kanjiQuery,
    List<DateTime>? timestamps,
  })  : wordQuery = null,
        timestamps = timestamps ?? [DateTime.now()];

  Search.fromWordQuery({
    required WordQuery this.wordQuery,
    List<DateTime>? timestamps,
  })  : kanjiQuery = null,
        timestamps = timestamps ?? [DateTime.now()];

  bool get isKanji => wordQuery == null;

  DateTime get timestamp => timestamps.last;

  Map<String, Object?> toJson() => {
        'timestamps': [for (final ts in timestamps) ts.millisecondsSinceEpoch],
        'word': wordQuery?.toJson(),
        'kanji': kanjiQuery?.toJson(),
      };

  factory Search.fromJson(Map<String, Object?> json) {
    final List<DateTime> timestamps = [
      for (final ts in json['timestamps'] as List<dynamic>)
        DateTime.fromMillisecondsSinceEpoch(ts as int)
    ];

    if (json['word'] == null && json['kanji'] == null) {
      throw Exception('Search.fromJson: No word or kanji found');
    }

    if (json['word'] == null) {
      return Search.fromKanjiQuery(
        kanjiQuery: KanjiQuery.fromJson(json['kanji'] as Map<String, Object?>),
        timestamps: timestamps,
      );
    } else {
      return Search.fromWordQuery(
        wordQuery: WordQuery.fromJson(json['word'] as Map<String, Object?>),
        timestamps: timestamps,
      );
    }
  }

  static StoreRef<int, Object?> get store => intMapStoreFactory.store('search');
}

Future<void> addSearchToDatabase({
  required String searchTerm,
  required bool isKanji,
}) async {
  final DateTime now = DateTime.now();
  final db = GetIt.instance.get<Database>();
  final Filter filter = Filter.equals(
    isKanji ? 'kanjiQuery.kanji' : 'wordQuery.query',
    searchTerm,
  );

  final RecordSnapshot<int, Object?>? previousSearch =
      await Search.store.findFirst(db, finder: Finder(filter: filter));

  if (previousSearch != null) {
    final search =
        Search.fromJson(previousSearch.value! as Map<String, Object?>);
    search.timestamps.add(now);
    Search.store.record(previousSearch.key).put(db, search.toJson());
    return;
  }

  Search.store.add(
    db,
    isKanji
        ? Search.fromKanjiQuery(kanjiQuery: KanjiQuery(kanji: searchTerm))
            .toJson()
        : Search.fromWordQuery(wordQuery: WordQuery(query: searchTerm))
            .toJson(),
  );
}

List<Search> mergeSearches(List<Search> a, List<Search> b) {
  final List<Search> result = [...a];

  for (final Search search in b) {
    late final Iterable<Search> matchingEntry;
    if (search.isKanji) {
      matchingEntry =
          result.where((e) => e.kanjiQuery?.kanji == search.kanjiQuery!.kanji);
    } else {
      matchingEntry =
          result.where((e) => e.wordQuery?.query == search.wordQuery!.query);
    }

    if (matchingEntry.isEmpty) {
      result.add(search);
      continue;
    }

    final timestamps = [...matchingEntry.first.timestamps];
    matchingEntry.first.timestamps.clear();
    matchingEntry.first.timestamps.addAll(
      (timestamps
            ..addAll(search.timestamps)
            ..sort())
          .toSet()
          .toList(),
    );
  }

  return result;
}
