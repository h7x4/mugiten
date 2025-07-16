import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/theme/theme_bloc.dart';
import '../../../settings.dart';

class Grade extends StatelessWidget {
  final String? grade;
  final String ifNullChar;

  const Grade({required this.grade, this.ifNullChar = '⨉', super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeBloc, ThemeState>(
    builder: (context, state) {
      final colors = state.theme.kanjiResultColor;

      return Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: colors.background,
          shape: BoxShape.circle,
        ),
        child: Text(
          grade ?? ifNullChar,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 20.0,
          ).merge(japaneseFont.textStyle),
        ),
      );
    },
  );
}
