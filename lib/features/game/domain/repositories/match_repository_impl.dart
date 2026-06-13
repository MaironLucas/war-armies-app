import 'dart:async';

import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/domain/repositories/game_transport.dart';
import 'package:war_armies_app/features/game/data/data_sources/match_data_source.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/models/player_territories.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl({
    required GameTransport transport,
    MatchDataSource? matchDataSource,
  }) : _transport = transport,
       _matchDataSource = matchDataSource ?? const MatchDataSource();

  final GameTransport _transport;
  final MatchDataSource _matchDataSource;

  MatchState? _matchState;
  StreamSubscription<WireMessage>? _incomingSubscription;

  final StreamController<MatchState> _matchStateController =
      StreamController<MatchState>.broadcast();

  int _seq = 0;
  int _nextSeq() => _seq++;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Stream<MatchState> watchMatch() => _matchStateController.stream;

  @override
  Future<void> requestIncrementTerritories(String playerId) async {
    final message = _matchDataSource.createIncrementTerritoriesMessage(
      playerId: playerId,
      seq: _nextSeq(),
    );
    await _transport.send(message);
  }

  @override
  Future<void> requestDecrementTerritories(String playerId) async {
    final message = _matchDataSource.createDecrementTerritoriesMessage(
      playerId: playerId,
      seq: _nextSeq(),
    );
    await _transport.send(message);
  }

  @override
  Future<void> setTerritories(String playerId, int count) async {
    final message = _matchDataSource.createSetTerritoriesMessage(
      playerId: playerId,
      count: count,
      seq: _nextSeq(),
    );
    await _transport.send(message);
  }

  // ---------------------------------------------------------------------------
  // Host-side: start listening for match messages
  // ---------------------------------------------------------------------------

  /// Starts listening for incoming match-related wire messages.
  ///
  /// Call this after the room transitions to an active match state.
  /// This is typically called by the host when starting a match.
  @override
  void startListening() {
    _incomingSubscription?.cancel();
    _incomingSubscription = _transport.incoming.listen(_handleIncomingMessage);
  }

  /// Initializes a new match from the given [room] and starts listening.
  ///
  /// Each player starts with 0 territories. Broadcasts the initial
  /// match snapshot to all connected guests.
  @override
  MatchState initializeMatch(Room room) {
    final territoriesByPlayer = <String, PlayerTerritories>{};
    for (final player in room.players) {
      territoriesByPlayer[player.id] = PlayerTerritories(
        playerId: player.id,
        count: 0,
      );
    }

    _matchState = MatchState(
      room: room,
      territoriesByPlayer: territoriesByPlayer,
      version: 1,
    );

    startListening();
    _broadcastMatchSnapshot();
    return _matchState!;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _handleIncomingMessage(WireMessage message) {
    if (_matchDataSource.isMatchSnapshot(message)) {
      final state = _matchDataSource.tryParseMatchSnapshot(message);
      if (state != null) {
        _matchState = state;
        _matchStateController.add(state);
      }
    } else if (_matchDataSource.isMatchDiff(message)) {
      final diff = _matchDataSource.tryParseMatchDiff(message);
      if (diff != null && _matchState != null) {
        _applyDiff(diff);
      }
    } else if (_matchDataSource.isIncrementTerritories(message)) {
      // Host receives increment request from a guest
      final playerId = _matchDataSource.tryParseIncrementTerritoriesPlayerId(
        message,
      );
      if (playerId != null && _matchState != null) {
        _incrementTerritories(playerId);
      }
    } else if (_matchDataSource.isDecrementTerritories(message)) {
      // Host receives decrement request from a guest
      final playerId = _matchDataSource.tryParseDecrementTerritoriesPlayerId(
        message,
      );
      if (playerId != null && _matchState != null) {
        _decrementTerritories(playerId);
      }
    } else if (_matchDataSource.isSetTerritories(message)) {
      // Host receives set request from a guest (or host sets for any player)
      final data = _matchDataSource.tryParseSetTerritories(message);
      if (data != null && _matchState != null) {
        _setTerritoriesForPlayer(data.playerId, data.count);
      }
    } else if (_matchDataSource.isError(message)) {
      final reason = _matchDataSource.tryParseErrorReason(message);
      // TODO(MaironLucas): Surface error to presentation layer via
      // a dedicated stream. For now, we just log it. The presentation
      // layer can subscribe to watchMatch() and handle state changes.
      // ignore: avoid_print
      print('MatchRepository: received error: $reason');
    }
  }

  void _incrementTerritories(String playerId) {
    if (_matchState == null) return;

    final current = _matchState!.territoriesByPlayer[playerId];
    if (current == null) return;

    final updated = PlayerTerritories(
      playerId: playerId,
      count: current.count + 1,
    );

    final newTerritories = Map<String, PlayerTerritories>.from(
      _matchState!.territoriesByPlayer,
    )..[playerId] = updated;

    _matchState = MatchState(
      room: _matchState!.room,
      territoriesByPlayer: newTerritories,
      version: _matchState!.version + 1,
    );

    _matchStateController.add(_matchState!);
    _broadcastMatchDiff(updated);
  }

  void _decrementTerritories(String playerId) {
    if (_matchState == null) return;

    final current = _matchState!.territoriesByPlayer[playerId];
    if (current == null) return;

    final newCount = current.count > 0 ? current.count - 1 : 0;
    final updated = PlayerTerritories(playerId: playerId, count: newCount);

    final newTerritories = Map<String, PlayerTerritories>.from(
      _matchState!.territoriesByPlayer,
    )..[playerId] = updated;

    _matchState = MatchState(
      room: _matchState!.room,
      territoriesByPlayer: newTerritories,
      version: _matchState!.version + 1,
    );

    _matchStateController.add(_matchState!);
    _broadcastMatchDiff(updated);
  }

  void _setTerritoriesForPlayer(String playerId, int count) {
    if (_matchState == null) return;

    final updated = PlayerTerritories(
      playerId: playerId,
      count: count < 0 ? 0 : count,
    );

    final newTerritories = Map<String, PlayerTerritories>.from(
      _matchState!.territoriesByPlayer,
    )..[playerId] = updated;

    _matchState = MatchState(
      room: _matchState!.room,
      territoriesByPlayer: newTerritories,
      version: _matchState!.version + 1,
    );

    _matchStateController.add(_matchState!);
    _broadcastMatchDiff(updated);
  }

  void _applyDiff(MatchDiffData diff) {
    if (_matchState == null) return;

    final updated = PlayerTerritories(
      playerId: diff.playerId,
      count: diff.count,
    );

    final newTerritories = Map<String, PlayerTerritories>.from(
      _matchState!.territoriesByPlayer,
    )..[diff.playerId] = updated;

    _matchState = MatchState(
      room: _matchState!.room,
      territoriesByPlayer: newTerritories,
      version: diff.version,
    );

    _matchStateController.add(_matchState!);
  }

  void _broadcastMatchSnapshot() {
    if (_matchState == null) return;
    final message = _matchDataSource.createMatchSnapshotMessage(
      _matchState!,
      _nextSeq(),
    );
    _transport.send(message);
  }

  void _broadcastMatchDiff(PlayerTerritories updated) {
    if (_matchState == null) return;
    final message = _matchDataSource.createMatchDiffMessage(
      playerId: updated.playerId,
      count: updated.count,
      version: _matchState!.version,
      seq: _nextSeq(),
    );
    _transport.send(message);
  }

  /// Stops listening and cleans up resources.
  void dispose() {
    _incomingSubscription?.cancel();
    _incomingSubscription = null;
    _matchStateController.close();
  }
}
