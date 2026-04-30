import 'package:war_armies_app/features/game/domain/models/match_state.dart';

abstract class MatchRepository {
  Stream<MatchState> watchMatch();

  Future<void> requestIncrement(String playerId);

  Future<void> requestDecrement(String playerId);

  Future<void> setTroops(String playerId, int total);
}
