import 'package:flutter/material.dart';
import '../../components/search/global_search_bar.dart';

class WordSearchView extends StatelessWidget {
  const WordSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[GlobalSearchBar()],
    );
  }
}
