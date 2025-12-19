import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

class SearchChip extends StatelessWidget {
  final String text;
  final ForegroundBackgroundThemeExtension colors;
  final TextStyle? extraTextStyle;

  const SearchChip({
    super.key,
    required this.text,
    required this.colors,
    this.extraTextStyle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: colors.backgroundColor,
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: Text(
      text,
      style: TextStyle(color: colors.foregroundColor).merge(extraTextStyle),
    ),
  );
}
