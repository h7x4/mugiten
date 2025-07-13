import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/theme/theme_bloc.dart';

class Rank extends StatelessWidget {
  final int? rank;
  final String ifNullChar;

  const Rank({
    required this.rank,
    this.ifNullChar = '⨉',
    super.key,
  });

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          final colors = state.theme.kanjiResultColor;

          return Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              shape: (rank == null) ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: (rank == null) ? null : BorderRadius.circular(10.0),
              color: colors.background,
            ),
            child: Text(
              rank != null ? '${rank.toString()} / 2500' : ifNullChar,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 20.0,
              ),
            ),
          );
        },
      );
}
