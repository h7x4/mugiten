import 'package:flutter/material.dart';
import 'package:mugiten/components/search/search_results_body/parts/circle_badge.dart';

class JLPTBadge extends StatelessWidget {
  final String? jlptLevel;

  const JLPTBadge({required this.jlptLevel, super.key});

  @override
  Widget build(final BuildContext context) {
    return CircleBadge(
      color: jlptLevel != null ? Colors.blue : Colors.transparent,
      child: Text(jlptLevel ?? '', style: const TextStyle(color: Colors.white)),
    );
  }
}
