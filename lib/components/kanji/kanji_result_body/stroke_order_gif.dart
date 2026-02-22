import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kanimaji/kanimaji.dart';

import '../../../bloc/theme/theme_bloc.dart';

class StrokeOrderGif extends StatelessWidget {
  final String kanji;

  const StrokeOrderGif({required this.kanji, super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeBloc, ThemeState>(
    builder: (context, state) {
      return Container(
        height: MediaQuery.of(context).size.width * 0.40,
        width: MediaQuery.of(context).size.width * 0.40,
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          color: state.theme.menuGreyLight.background,
          borderRadius: BorderRadius.circular(15.0),
          border: BoxBorder.all(
            color: state.theme.kanjiResultColor.background,
            width: 4.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Kanimaji(
            kanji: kanji,
            strokeColor: state.theme.foreground,
            strokeUnfilledColor: state.theme.menuGreyLight.foreground.withAlpha(0x40),
          ),
        ),
      );
    },
  );
}
