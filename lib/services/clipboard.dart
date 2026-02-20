import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void copyToClipboard(BuildContext context, String? clipboardContent) {
  if (clipboardContent == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No text to copy'),
        duration: Duration(milliseconds: 500),
      ),
    );
    return;
  }

  Clipboard.setData(ClipboardData(text: clipboardContent));

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied \'$clipboardContent\''),
      duration: const Duration(milliseconds: 500),
    ),
  );
}
