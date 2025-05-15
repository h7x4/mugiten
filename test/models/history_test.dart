import 'package:mugiten/models/history/kanji_query.dart';
import 'package:mugiten/models/history/search.dart';
import 'package:mugiten/models/history/word_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Search', () {
    final List<Search> searches = [
      Search.fromKanjiQuery(kanjiQuery: KanjiQuery(kanji: '何')),
      Search.fromWordQuery(wordQuery: WordQuery(query: 'テスト')),
      Search.fromJson({'timestamps':[1648658269960],'lastTimestamp':1648658269960,'wordQuery':null,'kanjiQuery':{'kanji':'日'}}),
      Search.fromJson({'timestamps':[1648674967535],'lastTimestamp':1648674967535,'wordQuery':{'query':'黙る'},'kanjiQuery':null}),
      Search.fromJson({'timestamps':[1649079907766],'lastTimestamp':1649079907766,'wordQuery':{'query':'seal'},'kanjiQuery':null}),
      Search.fromJson({'timestamps':[1649082072981],'lastTimestamp':1649082072981,'wordQuery':{'query':'感涙屋'},'kanjiQuery':null}),
      Search.fromJson({'timestamps':[1644951726777,1644951732749],'lastTimestamp':1644951732749,'wordQuery':{'query':'呑める'},'kanjiQuery':null}),
    ];

    test("mergeSearches with empty lists doesn't add data", () {
      final List<Search> merged1 = mergeSearches(searches, []);
      final List<Search> merged2 = mergeSearches([], searches);
      for (int i = 0; i < searches.length; i++) {
        expect(merged1[i], searches[i]);
        expect(merged2[i], searches[i]);
      }
    });

    test("mergeSearches with the same list doesn't add data", () {
      final List<Search> merged = mergeSearches(searches, searches);
      for (int i = 0; i < searches.length; i++) {
        expect(merged[i], searches[i]);
      }
      expect(mergeSearches(searches, searches), searches);
    });
  });
}
