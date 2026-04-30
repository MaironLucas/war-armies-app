import 'package:war_armies_app/features/game/domain/models/player_troops.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

class MatchState {
  const MatchState({
    required this.room,
    required this.troopsByPlayer,
    required this.version,
  });

  final Room room;
  final Map<String, PlayerTroops> troopsByPlayer;
  final int version;
}
