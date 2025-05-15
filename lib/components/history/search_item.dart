import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';

import '../../models/history/search.dart';
import '../../routing/routes.dart';
import '../../services/datetime.dart';
import '../../settings.dart';
import 'kanji_box.dart';

class SearchItem extends StatelessWidget {
  final Search search;
  // final Widget search;
  final int objectKey;
  final void Function()? onDelete;
  final void Function()? onFavourite;

  const SearchItem({
    required this.search,
    required this.objectKey,
    this.onDelete,
    this.onFavourite,
    super.key,
  });

  Widget get _child => (search.isKanji)
      ? KanjiBox(kanji: search.kanjiQuery!.kanji)
      : Text(search.wordQuery!.query);

  void Function() _onTap(context) => search.isKanji
      ? () => Navigator.pushNamed(
            context,
            Routes.kanjiSearch,
            arguments: search.kanjiQuery!.kanji,
          )
      : () => Navigator.pushNamed(
            context,
            Routes.search,
            arguments: search.wordQuery!.query,
          );

  MaterialPageRoute get timestamps => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Last searched')),
          body: ListView(
            children: [
              for (final ts in search.timestamps.reversed)
                ListTile(title: Text('${formatDate(ts)}    ${formatTime(ts)}'))
            ],
          ),
        ),
      );

  List<SlidableAction> _actions(context) => [
        SlidableAction(
          backgroundColor: Colors.blue,
          icon: Icons.access_time,
          onPressed: (_) => Navigator.push(context, timestamps),
        ),
        SlidableAction(
          backgroundColor: Colors.yellow,
          icon: Icons.star,
          onPressed: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('TODO: implement favourites')),
            );
            onFavourite?.call();
          },
        ),
        SlidableAction(
          backgroundColor: Colors.red,
          icon: Icons.delete,
          onPressed: (_) {
            final Database db = GetIt.instance.get<Database>();
            Search.store.record(objectKey).delete(db);
            onDelete?.call();
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: _actions(context),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          onTap: _onTap(context),
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(formatTime(search.timestamp)),
              ),
              DefaultTextStyle.merge(
                style: japaneseFont.textStyle,
                child: _child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
