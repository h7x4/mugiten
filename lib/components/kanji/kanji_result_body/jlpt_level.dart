import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/theme/theme_bloc.dart';

class JlptLevel extends StatelessWidget {
  final String? jlptLevel;
  final String ifNullChar;

  const JlptLevel({required this.jlptLevel, this.ifNullChar = '⨉', super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeBloc, ThemeState>(
    builder: (context, state) {
      final colors = state.theme.kanjiResultColor;
      return Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.background,
        ),
        child: Text(
          jlptLevel ?? ifNullChar,
          style: TextStyle(color: colors.foreground, fontSize: 20.0),
        ),
      );
    },
  );
}
