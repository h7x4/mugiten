import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

import '../../../routing/routes.dart';
import '../../../settings.dart';

class Radical extends StatelessWidget {
  final String radical;

  const Radical({required this.radical, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KanjiResultThemeExtension>()!;

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.kanjiSearchRadicals,
        arguments: radical,
      ),
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.backgroundColor,
        ),
        child: Text(
          radical,
          style: TextStyle(
            color: colors.foregroundColor,
            fontSize: 40.0,
          ).merge(japaneseFont.value.textStyle),
        ),
      ),
    );
  }
}
