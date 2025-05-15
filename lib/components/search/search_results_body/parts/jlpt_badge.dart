import 'package:flutter/material.dart';
import 'circle_badge.dart';

class JLPTBadge extends StatelessWidget {
  final String? jlptLevel;

  const JLPTBadge({
    required this.jlptLevel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CircleBadge(
      color: jlptLevel != null ? Colors.blue : Colors.transparent,
      child: Text(
        jlptLevel ?? '',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
