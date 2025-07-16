import 'package:flutter/material.dart';

class OpaqueBox extends StatelessWidget {
  final Widget child;

  const OpaqueBox({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: child,
    );
  }
}
