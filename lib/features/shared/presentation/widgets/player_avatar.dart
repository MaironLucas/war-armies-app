import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.playerName,
    required this.color,
    this.radius = 20,
    super.key,
  });

  final String playerName;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = playerName.isNotEmpty ? playerName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          color: _contrastColor(color),
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  /// Returns white or black depending on the luminance of [color].
  Color _contrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
