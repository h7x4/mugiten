import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

import '../../../settings.dart';

class Grade extends StatelessWidget {
  final String? grade;
  final String ifNullChar;

  const Grade({required this.grade, this.ifNullChar = '⨉', super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KanjiResultThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        grade ?? ifNullChar,
        style: TextStyle(
          color: colors.foregroundColor,
          fontSize: 20.0,
        ).merge(japaneseFont.textStyle),
      ),
    );
  }
}
