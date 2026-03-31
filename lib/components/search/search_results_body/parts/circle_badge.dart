import 'package:flutter/material.dart';

class CircleBadge extends StatelessWidget {
  final Widget? child;
  final Color color;

  const CircleBadge({super.key, this.child, required this.color});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      width: 30,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: FittedBox(child: child),
    );
  }
}
