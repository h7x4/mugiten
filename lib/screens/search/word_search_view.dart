import 'package:flutter/material.dart';
import 'package:mugiten/components/search/global_search_bar.dart';

class WordSearchView extends StatelessWidget {
  const WordSearchView({super.key});

  @override
  Widget build(final BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[GlobalSearchBar()],
    );
  }
}
