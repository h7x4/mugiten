import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

class JlptLevel extends StatelessWidget {
  final String? jlptLevel;
  final String ifNullChar;

  const JlptLevel({required this.jlptLevel, this.ifNullChar = '⨉', super.key});

  @override
  Widget build(final BuildContext context) {
    final colors = Theme.of(context).extension<KanjiResultThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.backgroundColor,
      ),
      child: Text(
        jlptLevel ?? ifNullChar,
        style: TextStyle(color: colors.foregroundColor, fontSize: 20.0),
      ),
    );
  }
}
