import 'package:war_armies_app/features/game/domain/models/match_state.dart';

abstract class MatchRepository {
  Stream<MatchState> watchMatch();

  Future<void> requestIncrementTerritories(String playerId);

  Future<void> requestDecrementTerritories(String playerId);

  Future<void> setTerritories(String playerId, int count);
}
