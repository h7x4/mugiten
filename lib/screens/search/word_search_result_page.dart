import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/models/word_search/word_search_result.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/models/history/search.dart';
// import 'package:unofficial_jisho_api/api.dart';

import '../../components/search/search_results_body/search_card.dart';

class WordSearchResultPage extends StatefulWidget {
  final String searchTerm;

  const WordSearchResultPage({
    required this.searchTerm,
    super.key,
  });

  @override
  State<WordSearchResultPage> createState() => _WordSearchResultPageState();
}

class _WordSearchResultPageState extends State<WordSearchResultPage> {
  final List<WordSearchResult> results = [];

  bool addedToDatabase = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        // future:
        //     GetIt.instance.get<JaDBConnection>().searchWord(widget.searchTerm),

        future: (() async {
          final jadbConnection = GetIt.instance.get<JaDBConnection>();

          final results = await Future.wait([
            jadbConnection.searchWordCount(widget.searchTerm),
            jadbConnection.searchWord(widget.searchTerm),
          ]);

          return (results[0] as int, results[1] as List<WordSearchResult>);
        })(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorWidget(snapshot.error!);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!addedToDatabase) {
            addSearchToDatabase(
              searchTerm: widget.searchTerm,
              isKanji: false,
            );
            addedToDatabase = true;
          }

          return ListView(
            children: [
              Center(
                child: Text(
                  'Found ${snapshot.data!.$1} results for "${widget.searchTerm}"',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
              for (final result in snapshot.data!.$2)
                SearchResultCard(result: result)
            ],
          );
        },
      ),
    );
  }
}
