import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

abstract class MatchRepository {
  Stream<MatchState> watchMatch();

  Future<void> requestIncrementTerritories(String playerId);

  Future<void> requestDecrementTerritories(String playerId);

  Future<void> setTerritories(String playerId, int count);

  /// Initializes a new match from the given [room] with 0 territories per
  /// player. The host calls this to create the authoritative match state.
  MatchState initializeMatch(Room room);

  /// Starts listening for incoming match-related wire messages.
  /// Call this after the room transitions to an active match state.
  void startListening();
}
