class PlayerTerritories {
  const PlayerTerritories({required this.playerId, required this.count});

  final String playerId;
  final int count;

  /// Troops the player will receive at the start of their next turn,
  /// derived from the number of territories they control: `count ~/ 2`.
  int get troops => count ~/ 2;
}
