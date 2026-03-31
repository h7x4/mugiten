import 'package:async/async.dart';
import 'package:flutter/material.dart';

class AsyncTextFormField extends StatefulWidget {
  final Future<String?> Function(String?) asyncValidator;
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;

  const AsyncTextFormField({
    super.key,
    required this.asyncValidator,
    required this.controller,
    this.labelText,
    this.hintText,
  });

  @override
  AsyncTextFormFieldState createState() => AsyncTextFormFieldState();
}

class AsyncTextFormFieldState extends State<AsyncTextFormField> {
  String? errorText;
  CancelableOperation? currentValidation;

  Future<void> validate(final String text) async {
    currentValidation?.cancel();
    setState(() {
      errorText = null;
      currentValidation = CancelableOperation.fromFuture(
        widget.asyncValidator(text).then((final newErrorText) {
          if (!mounted) return;
          setState(() {
            errorText = newErrorText;
            currentValidation = null;
          });
        }),
      );
    });
  }

  @override
  Widget build(final BuildContext context) {
    print(
      'Building AsyncTextFormField with errorText: $errorText and currentValidation: $currentValidation',
    );
    return TextFormField(
      key: widget.key,
      controller: widget.controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: errorText,
        // TODO: add a small timer, so that this doesn't flicker if the user is typing quickly and the validation is fast
        suffixIcon: currentValidation != null
            ? const CircularProgressIndicator(strokeWidth: 2)
            : errorText != null
            ? const Icon(Icons.error, color: Colors.red)
            : const Icon(Icons.check, color: Colors.green),
      ),
      onChanged: validate,
      forceErrorText: errorText,
    );
  }
}
