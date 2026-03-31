import 'package:flutter/material.dart';
import 'package:mugiten/components/search/search_results_body/parts/circle_badge.dart';

class CommonBadge extends StatelessWidget {
  final bool isCommon;

  const CommonBadge({required this.isCommon, super.key});

  @override
  Widget build(final BuildContext context) {
    return CircleBadge(
      color: isCommon ? Colors.green : Colors.transparent,
      child: Text(
        'C',
        style: TextStyle(color: isCommon ? Colors.white : Colors.transparent),
      ),
    );
  }
}
