import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message_type.dart';
import 'package:war_armies_app/features/game/data/mappers/match_mappers.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';

/// Data source that creates and parses match-related [WireMessage]s.
///
/// Pure data-transformation layer — no I/O, no external dependencies.
class MatchDataSource {
  const MatchDataSource();

  // ---------------------------------------------------------------------------
  // Host → Guest messages
  // ---------------------------------------------------------------------------

  /// Creates a `match_snapshot` wire message from a [MatchState] domain model.
  WireMessage createMatchSnapshotMessage(MatchState state, int seq) {
    return WireMessage(
      type: WireMessageType.matchSnapshot,
      seq: seq,
      payload: MatchMappers.matchStateToMap(state),
    );
  }

  /// Creates a `match_diff` wire message for a single territory-count
  /// change.
  WireMessage createMatchDiffMessage({
    required String playerId,
    required int count,
    required int version,
    int seq = 0,
  }) {
    return WireMessage(
      type: WireMessageType.matchDiff,
      seq: seq,
      payload: {'playerId': playerId, 'count': count, 'version': version},
    );
  }

  /// Creates an `error` wire message.
  WireMessage createErrorMessage({required String reason, int seq = 0}) {
    return WireMessage(
      type: WireMessageType.error,
      seq: seq,
      payload: {'reason': reason},
    );
  }

  // ---------------------------------------------------------------------------
  // Guest → Host messages
  // ---------------------------------------------------------------------------

  /// Creates an `increment_territories_request` wire message.
  WireMessage createIncrementTerritoriesMessage({
    required String playerId,
    int seq = 0,
  }) {
    return WireMessage(
      type: WireMessageType.incrementTerritoriesRequest,
      seq: seq,
      payload: {'playerId': playerId},
    );
  }

  /// Creates a `decrement_territories_request` wire message.
  WireMessage createDecrementTerritoriesMessage({
    required String playerId,
    int seq = 0,
  }) {
    return WireMessage(
      type: WireMessageType.decrementTerritoriesRequest,
      seq: seq,
      payload: {'playerId': playerId},
    );
  }

  /// Creates a `set_territories_request` wire message.
  WireMessage createSetTerritoriesMessage({
    required String playerId,
    required int count,
    int seq = 0,
  }) {
    return WireMessage(
      type: WireMessageType.setTerritoriesRequest,
      seq: seq,
      payload: {'playerId': playerId, 'count': count},
    );
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Returns `true` if [message] is a `match_snapshot` message.
  bool isMatchSnapshot(WireMessage message) =>
      message.type == WireMessageType.matchSnapshot;

  /// Returns `true` if [message] is a `match_diff` message.
  bool isMatchDiff(WireMessage message) =>
      message.type == WireMessageType.matchDiff;

  /// Returns `true` if [message] is an `error` message.
  bool isError(WireMessage message) => message.type == WireMessageType.error;

  /// Returns `true` if [message] is an `increment_territories_request`.
  bool isIncrementTerritories(WireMessage message) =>
      message.type == WireMessageType.incrementTerritoriesRequest;

  /// Returns `true` if [message] is a `decrement_territories_request`.
  bool isDecrementTerritories(WireMessage message) =>
      message.type == WireMessageType.decrementTerritoriesRequest;

  /// Returns `true` if [message] is a `set_territories_request`.
  bool isSetTerritories(WireMessage message) =>
      message.type == WireMessageType.setTerritoriesRequest;

  /// Parses a `match_snapshot` message into a [MatchState].
  ///
  /// Requires the room because the wire payload may not include the full room
  /// context; pass the current room from the room state.
  ///
  /// Returns `null` if [message] is not a `match_snapshot` or if the
  /// payload is malformed.
  MatchState? tryParseMatchSnapshot(WireMessage message) {
    if (!isMatchSnapshot(message)) return null;
    return MatchMappers.tryMapToMatchState(message.payload);
  }

  /// Parses a `match_diff` message payload.
  ///
  /// Returns `null` if [message] is not a `match_diff` or if the payload
  /// is missing required fields.
  MatchDiffData? tryParseMatchDiff(WireMessage message) {
    if (!isMatchDiff(message)) return null;

    final playerId = message.payload['playerId'] as String?;
    final count = message.payload['count'] as int?;
    final version = message.payload['version'] as int?;

    if (playerId == null || count == null || version == null) return null;

    return MatchDiffData(playerId: playerId, count: count, version: version);
  }

  /// Parses an `error` message and returns the reason string.
  ///
  /// Returns `null` if [message] is not an `error` message.
  String? tryParseErrorReason(WireMessage message) {
    if (!isError(message)) return null;
    return message.payload['reason'] as String?;
  }

  /// Parses an `increment_territories_request` and returns the player ID.
  ///
  /// Returns `null` if [message] is not an increment request or if the
  /// payload is missing the `playerId` field.
  String? tryParseIncrementTerritoriesPlayerId(WireMessage message) {
    if (!isIncrementTerritories(message)) return null;
    return message.payload['playerId'] as String?;
  }

  /// Parses a `decrement_territories_request` and returns the player ID.
  ///
  /// Returns `null` if [message] is not a decrement request or if the
  /// payload is missing the `playerId` field.
  String? tryParseDecrementTerritoriesPlayerId(WireMessage message) {
    if (!isDecrementTerritories(message)) return null;
    return message.payload['playerId'] as String?;
  }

  /// Parses a `set_territories_request` and returns the data.
  ///
  /// Returns `null` if [message] is not a set request or if the payload
  /// is missing required fields.
  SetTerritoriesData? tryParseSetTerritories(WireMessage message) {
    if (!isSetTerritories(message)) return null;

    final playerId = message.payload['playerId'] as String?;
    final count = message.payload['count'] as int?;

    if (playerId == null || count == null) return null;

    return SetTerritoriesData(playerId: playerId, count: count);
  }
}

/// Data transfer object for a `match_diff` payload.
class MatchDiffData {
  const MatchDiffData({
    required this.playerId,
    required this.count,
    required this.version,
  });

  final String playerId;
  final int count;
  final int version;
}

/// Data transfer object for a `set_territories_request` payload.
class SetTerritoriesData {
  const SetTerritoriesData({required this.playerId, required this.count});

  final String playerId;
  final int count;
}
