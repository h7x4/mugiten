import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/theme/theme_bloc.dart';

class StrokeOrderGif extends StatelessWidget {
  final String uri;

  const StrokeOrderGif({required this.uri, super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeBloc, ThemeState>(
    builder: (context, state) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20.0),
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          color: state.theme.kanjiResultColor.background,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image.network(uri),
        ),
      );
    },
  );
}
