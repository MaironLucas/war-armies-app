import 'package:flutter/material.dart';

class WarOutlinedButton extends StatelessWidget {
  const WarOutlinedButton({
    required this.onPressed,
    required this.label,
    super.key,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
