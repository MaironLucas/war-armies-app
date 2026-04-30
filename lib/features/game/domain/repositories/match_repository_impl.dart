import 'package:war_armies_app/common/transport/domain/repositories/game_transport.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl({required GameTransport transport})
      : _transport = transport;

  // ignore: unused_field
  final GameTransport _transport;

  @override
  Stream<MatchState> watchMatch() => throw UnimplementedError();

  @override
  Future<void> requestIncrement(String playerId) => throw UnimplementedError();

  @override
  Future<void> requestDecrement(String playerId) => throw UnimplementedError();

  @override
  Future<void> setTroops(String playerId, int total) =>
      throw UnimplementedError();
}
