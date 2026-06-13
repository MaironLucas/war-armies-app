import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message_type.dart';
import 'package:war_armies_app/features/room/data/data_sources/room_data_source.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

void main() {
  const dataSource = RoomDataSource();

  group('createRoomStateMessage', () {
    test(
      'produces a WireMessage with type room_state and the serialized room',
      () {
        const player = Player(
          id: 'p1',
          name: 'Alice',
          color: Color(0xFF00FF00),
        );
        const room = Room(
          id: 'r1',
          name: 'Test Room',
          hostPlayerId: 'p1',
          players: [player],
          status: RoomStatus.lobby,
        );

        final message = dataSource.createRoomStateMessage(room, 42);

        expect(message.type, WireMessageType.roomState);
        expect(message.seq, 42);
        expect(message.payload['id'], 'r1');
        expect(message.payload['name'], 'Test Room');
        expect(message.payload['hostPlayerId'], 'p1');
        expect(message.payload['status'], 'lobby');
        expect(message.payload['players'], isA<List<dynamic>>());
      },
    );
  });

  group('createJoinRequestMessage', () {
    test(
      'produces a WireMessage with type join_request and payload fields',
      () {
        final message = dataSource.createJoinRequestMessage(
          playerId: 'p1',
          playerName: 'Alice',
          colorValue: 0xFF00FF00,
          seq: 1,
        );

        expect(message.type, WireMessageType.joinRequest);
        expect(message.seq, 1);
        expect(message.payload['playerId'], 'p1');
        expect(message.payload['playerName'], 'Alice');
        expect(message.payload['colorValue'], 0xFF00FF00);
      },
    );

    test('defaults seq to 0', () {
      final message = dataSource.createJoinRequestMessage(
        playerId: 'p1',
        playerName: 'Alice',
        colorValue: 0xFF00FF00,
      );

      expect(message.seq, 0);
    });
  });

  group('createLeaveRequestMessage', () {
    test('produces a WireMessage with type leave_request and playerId', () {
      final message = dataSource.createLeaveRequestMessage(
        playerId: 'p1',
        seq: 2,
      );

      expect(message.type, WireMessageType.leaveRequest);
      expect(message.seq, 2);
      expect(message.payload['playerId'], 'p1');
    });

    test('defaults seq to 0', () {
      final message = dataSource.createLeaveRequestMessage(playerId: 'p1');

      expect(message.seq, 0);
    });
  });

  group('is* methods', () {
    const roomStateMsg = WireMessage(
      type: WireMessageType.roomState,
      seq: 0,
      payload: {},
    );
    const joinRequestMsg = WireMessage(
      type: WireMessageType.joinRequest,
      seq: 0,
      payload: {},
    );
    const leaveRequestMsg = WireMessage(
      type: WireMessageType.leaveRequest,
      seq: 0,
      payload: {},
    );
    const otherMsg = WireMessage(
      type: WireMessageType.matchSnapshot,
      seq: 0,
      payload: {},
    );

    test('isRoomState returns true for room_state', () {
      expect(dataSource.isRoomState(roomStateMsg), isTrue);
    });

    test('isRoomState returns false for other types', () {
      expect(dataSource.isRoomState(joinRequestMsg), isFalse);
      expect(dataSource.isRoomState(leaveRequestMsg), isFalse);
      expect(dataSource.isRoomState(otherMsg), isFalse);
    });

    test('isJoinRequest returns true for join_request', () {
      expect(dataSource.isJoinRequest(joinRequestMsg), isTrue);
    });

    test('isJoinRequest returns false for other types', () {
      expect(dataSource.isJoinRequest(roomStateMsg), isFalse);
      expect(dataSource.isJoinRequest(leaveRequestMsg), isFalse);
      expect(dataSource.isJoinRequest(otherMsg), isFalse);
    });

    test('isLeaveRequest returns true for leave_request', () {
      expect(dataSource.isLeaveRequest(leaveRequestMsg), isTrue);
    });

    test('isLeaveRequest returns false for other types', () {
      expect(dataSource.isLeaveRequest(roomStateMsg), isFalse);
      expect(dataSource.isLeaveRequest(joinRequestMsg), isFalse);
      expect(dataSource.isLeaveRequest(otherMsg), isFalse);
    });
  });

  group('tryParseRoomState', () {
    test('parses a room_state message back to Room', () {
      const player = Player(
        id: 'p1',
        name: 'Alice',
        color: Color(0xFF00FF00),
      );
      const room = Room(
        id: 'r1',
        name: 'Test Room',
        hostPlayerId: 'p1',
        players: [player],
        status: RoomStatus.lobby,
      );
      final message = dataSource.createRoomStateMessage(room, 0);

      final result = dataSource.tryParseRoomState(message);

      expect(result, isNotNull);
      expect(result!.id, 'r1');
      expect(result.name, 'Test Room');
      expect(result.hostPlayerId, 'p1');
      expect(result.status, RoomStatus.lobby);
      expect(result.players.length, 1);
      expect(result.players.first.id, 'p1');
      expect(result.players.first.name, 'Alice');
    });

    test('returns null for a non-room_state message', () {
      const message = WireMessage(
        type: WireMessageType.matchSnapshot,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseRoomState(message);

      expect(result, isNull);
    });

    test('returns null when payload is malformed', () {
      const message = WireMessage(
        type: WireMessageType.roomState,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseRoomState(message);

      expect(result, isNull);
    });
  });

  group('tryParseJoinRequest', () {
    test('parses a join_request message to JoinRequestData', () {
      final message = dataSource.createJoinRequestMessage(
        playerId: 'p1',
        playerName: 'Alice',
        colorValue: 0xFF00FF00,
      );

      final result = dataSource.tryParseJoinRequest(message);

      expect(result, isNotNull);
      expect(result!.playerId, 'p1');
      expect(result.playerName, 'Alice');
      expect(result.colorValue, 0xFF00FF00);
    });

    test('returns null for a non-join_request message', () {
      const message = WireMessage(
        type: WireMessageType.roomState,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseJoinRequest(message);

      expect(result, isNull);
    });

    test('returns null when payload is missing fields', () {
      const message = WireMessage(
        type: WireMessageType.joinRequest,
        seq: 0,
        payload: <String, dynamic>{'playerId': 'p1'},
      );

      final result = dataSource.tryParseJoinRequest(message);

      expect(result, isNull);
    });
  });

  group('tryParseLeaveRequestPlayerId', () {
    test('parses a leave_request message and returns the playerId', () {
      final message = dataSource.createLeaveRequestMessage(
        playerId: 'p1',
      );

      final result = dataSource.tryParseLeaveRequestPlayerId(message);

      expect(result, 'p1');
    });

    test('returns null for a non-leave_request message', () {
      const message = WireMessage(
        type: WireMessageType.roomState,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseLeaveRequestPlayerId(message);

      expect(result, isNull);
    });

    test('returns null when payload is missing playerId', () {
      const message = WireMessage(
        type: WireMessageType.leaveRequest,
        seq: 0,
        payload: <String, dynamic>{},
      );

      final result = dataSource.tryParseLeaveRequestPlayerId(message);

      expect(result, isNull);
    });
  });
}
