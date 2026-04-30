import 'package:war_armies_app/features/game/domain/models/player_territories.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

class MatchState {
  const MatchState({
    required this.room,
    required this.territoriesByPlayer,
    required this.version,
  });

  final Room room;
  final Map<String, PlayerTerritories> territoriesByPlayer;
  final int version;
}
