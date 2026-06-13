import 'package:flutter/material.dart';
import 'package:war_armies_app/theme/theme.dart';

class WarCard extends StatelessWidget {
  const WarCard({required this.child, super.key, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: WarSpacing.md,
        vertical: WarSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(WarSpacing.md),
          child: child,
        ),
      ),
    );
  }
}
