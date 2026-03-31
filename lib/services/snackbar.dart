import 'package:flutter/material.dart';

void showSnackbar(final BuildContext context, final String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
