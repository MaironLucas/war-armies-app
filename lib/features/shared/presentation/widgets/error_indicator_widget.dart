import 'package:flutter/material.dart';

class ErrorIndicatorWidget extends StatelessWidget {
  const ErrorIndicatorWidget({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
