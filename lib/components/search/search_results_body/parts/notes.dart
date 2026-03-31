import 'package:flutter/material.dart';

class Notes extends StatelessWidget {
  final List<String> notes;
  const Notes({super.key, required this.notes});

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
      Text(notes.join(', ')),
    ],
  );
}
