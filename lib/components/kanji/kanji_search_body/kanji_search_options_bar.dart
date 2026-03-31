import 'package:flutter/material.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/theme.dart';

class KanjiSearchOptionsBar extends StatelessWidget {
  const KanjiSearchOptionsBar({super.key});

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () =>
                Navigator.pushNamed(context, Routes.kanjiSearchRadicals),
          ),
          const SizedBox(width: 10),
          _IconButton(
            icon: const Icon(Icons.school),
            onPressed: () =>
                Navigator.pushNamed(context, Routes.kanjiSearchGrade),
          ),
          const SizedBox(width: 10),
          _IconButton(
            icon: const Icon(Icons.mode),
            onPressed: () =>
                Navigator.pushNamed(context, Routes.kanjiSearchDraw),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final Widget icon;
  final void Function()? onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(final BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: icon,
    iconSize: 30,
    color: Theme.of(
      context,
    ).extension<MenuGreyDarkThemeExtension>()!.backgroundColor,
  );
}
