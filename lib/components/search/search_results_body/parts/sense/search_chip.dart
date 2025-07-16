import 'package:flutter/material.dart';

import '../../../../../models/themes/theme.dart';

class SearchChip extends StatelessWidget {
  final String text;
  final ColorSet colors;
  final TextStyle? extraTextStyle;

  const SearchChip({
    super.key,
    required this.text,
    this.colors = LightTheme.defaultMenuGreyNormal,
    this.extraTextStyle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: colors.background,
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: Text(
      text,
      style: TextStyle(color: colors.foreground).merge(extraTextStyle),
    ),
  );
}
