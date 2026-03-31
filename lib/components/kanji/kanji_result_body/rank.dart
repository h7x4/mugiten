import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

class Rank extends StatelessWidget {
  final int? rank;
  final String ifNullChar;

  const Rank({required this.rank, this.ifNullChar = '⨉', super.key});

  @override
  Widget build(final BuildContext context) {
    final colors = Theme.of(context).extension<KanjiResultThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        shape: (rank == null) ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: (rank == null) ? null : BorderRadius.circular(10.0),
        color: colors.backgroundColor,
      ),
      child: Text(
        rank != null ? '${rank.toString()} / 2500' : ifNullChar,
        style: TextStyle(color: colors.foregroundColor, fontSize: 20.0),
      ),
    );
  }
}
