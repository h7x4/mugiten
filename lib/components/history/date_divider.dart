import 'package:flutter/material.dart';
import 'package:mugiten/theme.dart';

class TextDivider extends StatelessWidget {
  final String text;

  const TextDivider({super.key, required this.text});

  @override
  Widget build(final BuildContext context) {
    final colors = Theme.of(context).extension<MenuGreyNormalThemeExtension>()!;

    return Container(
      decoration: BoxDecoration(color: colors.backgroundColor),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: DefaultTextStyle.merge(
        child: Text(text),
        style: TextStyle(color: colors.foregroundColor),
      ),
    );
  }
}
