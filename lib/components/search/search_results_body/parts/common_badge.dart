import 'package:flutter/material.dart';
import 'circle_badge.dart';

class CommonBadge extends StatelessWidget {
  final bool isCommon;

  const CommonBadge({required this.isCommon, super.key});

  @override
  Widget build(BuildContext context) {
    return CircleBadge(
      color: isCommon ? Colors.green : Colors.transparent,
      child: Text(
        'C',
        style: TextStyle(color: isCommon ? Colors.white : Colors.transparent),
      ),
    );
  }
}
