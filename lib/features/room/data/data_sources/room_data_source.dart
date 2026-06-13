import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message_type.dart';
import 'package:war_armies_app/features/room/data/mappers/room_mappers.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

/// Data source that creates and parses room-related [WireMessage]s.
///
/// This is a pure data-transformation layer — no I/O, no external
/// dependencies. All methods are deterministic and side-effect free, making
/// them straightforward to unit-test.
class RoomDataSource {
  const RoomDataSource();

  // ---------------------------------------------------------------------------
  // Host → Guest messages
  // ---------------------------------------------------------------------------

  /// Creates a `room_state` wire message from a [Room] domain model.
  WireMessage createRoomStateMessage(Room room, int seq) {
    return WireMessage(
      type: WireMessageType.roomState,
      seq: seq,
      payload: RoomMappers.roomToMap(room),
    );
  }

  // ---------------------------------------------------------------------------
  // Guest → Host messages
  // ---------------------------------------------------------------------------

  /// Creates a `join_request` wire message.
  WireMessage createJoinRequestMessage({
    required String playerId,
    required String playerName,
    required int colorValue,
    int seq = 0,
  }) {
    return WireMessage(
      type: WireMessageType.joinRequest,
      seq: seq,
      payload: {
        'playerId': playerId,
        'playerName': playerName,
        'colorValue': colorValue,
      },
    );
  }

  /// Creates a `leave_request` wire message.
  WireMessage createLeaveRequestMessage({
    required String playerId,
    int seq = 0,
  }) {
    return WireMessage(
      type: WireMessageType.leaveRequest,
      seq: seq,
      payload: {'playerId': playerId},
    );
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Returns `true` if [message] is a `room_state` message.
  bool isRoomState(WireMessage message) =>
      message.type == WireMessageType.roomState;

  /// Returns `true` if [message] is a `join_request` message.
  bool isJoinRequest(WireMessage message) =>
      message.type == WireMessageType.joinRequest;

  /// Returns `true` if [message] is a `leave_request` message.
  bool isLeaveRequest(WireMessage message) =>
      message.type == WireMessageType.leaveRequest;

  /// Parses a `room_state` message into a [Room].
  ///
  /// Returns `null` if [message] is not a `room_state` message or if the
  /// payload is malformed.
  Room? tryParseRoomState(WireMessage message) {
    if (!isRoomState(message)) return null;
    return RoomMappers.tryMapToRoom(message.payload);
  }

  /// Parses a `join_request` message payload.
  ///
  /// Returns `null` if [message] is not a `join_request` message or if the
  /// payload is missing required fields.
  JoinRequestData? tryParseJoinRequest(WireMessage message) {
    if (!isJoinRequest(message)) return null;

    final playerId = message.payload['playerId'] as String?;
    final playerName = message.payload['playerName'] as String?;
    final colorValue = message.payload['colorValue'] as int?;

    if (playerId == null || playerName == null || colorValue == null) {
      return null;
    }

    return JoinRequestData(
      playerId: playerId,
      playerName: playerName,
      colorValue: colorValue,
    );
  }

  /// Parses a `leave_request` message and returns the player ID.
  ///
  /// Returns `null` if [message] is not a `leave_request` message or if the
  /// payload is missing the `playerId` field.
  String? tryParseLeaveRequestPlayerId(WireMessage message) {
    if (!isLeaveRequest(message)) return null;
    return message.payload['playerId'] as String?;
  }
}

/// Data transfer object for a join request payload.
class JoinRequestData {
  const JoinRequestData({
    required this.playerId,
    required this.playerName,
    required this.colorValue,
  });

  final String playerId;
  final String playerName;
  final int colorValue;
}
