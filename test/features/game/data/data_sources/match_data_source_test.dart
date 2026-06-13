import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message_type.dart';
import 'package:war_armies_app/features/game/data/data_sources/match_data_source.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/models/player_territories.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

void main() {
  const dataSource = MatchDataSource();

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

  const matchState = MatchState(
    room: room,
    territoriesByPlayer: {
      'p1': PlayerTerritories(playerId: 'p1', count: 10),
    },
    version: 1,
  );

  // ---------------------------------------------------------------------------
  // Create methods
  // ---------------------------------------------------------------------------

  group('createMatchSnapshotMessage', () {
    test('produces a WireMessage with type match_snapshot', () {
      final message = dataSource.createMatchSnapshotMessage(matchState, 7);

      expect(message.type, WireMessageType.matchSnapshot);
      expect(message.seq, 7);
      expect(message.payload['version'], 1);
      expect(message.payload['room'], isA<Map<String, dynamic>>());
      expect(
        message.payload['territoriesByPlayer'],
        isA<Map<String, dynamic>>(),
      );
    });
  });

  group('createMatchDiffMessage', () {
    test('produces a WireMessage with type match_diff', () {
      final message = dataSource.createMatchDiffMessage(
        playerId: 'p1',
        count: 5,
        version: 2,
        seq: 1,
      );

      expect(message.type, WireMessageType.matchDiff);
      expect(message.seq, 1);
      expect(message.payload['playerId'], 'p1');
      expect(message.payload['count'], 5);
      expect(message.payload['version'], 2);
    });

    test('defaults seq to 0', () {
      final message = dataSource.createMatchDiffMessage(
        playerId: 'p1',
        count: 5,
        version: 2,
      );

      expect(message.seq, 0);
    });
  });

  group('createErrorMessage', () {
    test('produces a WireMessage with type error', () {
      final message = dataSource.createErrorMessage(
        reason: 'something went wrong',
        seq: 3,
      );

      expect(message.type, WireMessageType.error);
      expect(message.seq, 3);
      expect(message.payload['reason'], 'something went wrong');
    });

    test('defaults seq to 0', () {
      final message = dataSource.createErrorMessage(reason: 'error');

      expect(message.seq, 0);
    });
  });

  group('createIncrementTerritoriesMessage', () {
    test('produces a WireMessage with type increment_territories_request', () {
      final message = dataSource.createIncrementTerritoriesMessage(
        playerId: 'p1',
        seq: 2,
      );

      expect(message.type, WireMessageType.incrementTerritoriesRequest);
      expect(message.seq, 2);
      expect(message.payload['playerId'], 'p1');
    });

    test('defaults seq to 0', () {
      final message = dataSource.createIncrementTerritoriesMessage(
        playerId: 'p1',
      );

      expect(message.seq, 0);
    });
  });

  group('createDecrementTerritoriesMessage', () {
    test('produces a WireMessage with type decrement_territories_request', () {
      final message = dataSource.createDecrementTerritoriesMessage(
        playerId: 'p1',
        seq: 4,
      );

      expect(message.type, WireMessageType.decrementTerritoriesRequest);
      expect(message.seq, 4);
      expect(message.payload['playerId'], 'p1');
    });

    test('defaults seq to 0', () {
      final message = dataSource.createDecrementTerritoriesMessage(
        playerId: 'p1',
      );

      expect(message.seq, 0);
    });
  });

  group('createSetTerritoriesMessage', () {
    test('produces a WireMessage with type set_territories_request', () {
      final message = dataSource.createSetTerritoriesMessage(
        playerId: 'p1',
        count: 15,
        seq: 5,
      );

      expect(message.type, WireMessageType.setTerritoriesRequest);
      expect(message.seq, 5);
      expect(message.payload['playerId'], 'p1');
      expect(message.payload['count'], 15);
    });

    test('defaults seq to 0', () {
      final message = dataSource.createSetTerritoriesMessage(
        playerId: 'p1',
        count: 15,
      );

      expect(message.seq, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // is* methods
  // ---------------------------------------------------------------------------

  group('is* methods', () {
    const snapshotMsg = WireMessage(
      type: WireMessageType.matchSnapshot,
      seq: 0,
      payload: {},
    );
    const diffMsg = WireMessage(
      type: WireMessageType.matchDiff,
      seq: 0,
      payload: {},
    );
    const errorMsg = WireMessage(
      type: WireMessageType.error,
      seq: 0,
      payload: {},
    );
    const incMsg = WireMessage(
      type: WireMessageType.incrementTerritoriesRequest,
      seq: 0,
      payload: {},
    );
    const decMsg = WireMessage(
      type: WireMessageType.decrementTerritoriesRequest,
      seq: 0,
      payload: {},
    );
    const setMsg = WireMessage(
      type: WireMessageType.setTerritoriesRequest,
      seq: 0,
      payload: {},
    );
    const otherMsg = WireMessage(
      type: WireMessageType.roomState,
      seq: 0,
      payload: {},
    );

    test('isMatchSnapshot returns true for match_snapshot', () {
      expect(dataSource.isMatchSnapshot(snapshotMsg), isTrue);
      expect(dataSource.isMatchSnapshot(otherMsg), isFalse);
    });

    test('isMatchDiff returns true for match_diff', () {
      expect(dataSource.isMatchDiff(diffMsg), isTrue);
      expect(dataSource.isMatchDiff(otherMsg), isFalse);
    });

    test('isError returns true for error', () {
      expect(dataSource.isError(errorMsg), isTrue);
      expect(dataSource.isError(otherMsg), isFalse);
    });

    test(
      'isIncrementTerritories returns true for increment_territories_request',
      () {
        expect(dataSource.isIncrementTerritories(incMsg), isTrue);
        expect(dataSource.isIncrementTerritories(otherMsg), isFalse);
      },
    );

    test(
      'isDecrementTerritories returns true for decrement_territories_request',
      () {
        expect(dataSource.isDecrementTerritories(decMsg), isTrue);
        expect(dataSource.isDecrementTerritories(otherMsg), isFalse);
      },
    );

    test('isSetTerritories returns true for set_territories_request', () {
      expect(dataSource.isSetTerritories(setMsg), isTrue);
      expect(dataSource.isSetTerritories(otherMsg), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // TryParse methods
  // ---------------------------------------------------------------------------

  group('tryParseMatchSnapshot', () {
    test('parses a match_snapshot message back to MatchState', () {
      final message = dataSource.createMatchSnapshotMessage(matchState, 0);

      final result = dataSource.tryParseMatchSnapshot(message);

      expect(result, isNotNull);
      expect(result!.version, 1);
      expect(result.room.id, 'r1');
      expect(result.territoriesByPlayer['p1']!.playerId, 'p1');
      expect(result.territoriesByPlayer['p1']!.count, 10);
    });

    test('returns null for a non-match_snapshot message', () {
      const message = WireMessage(
        type: WireMessageType.matchDiff,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseMatchSnapshot(message);

      expect(result, isNull);
    });

    test('returns null when payload is malformed', () {
      const message = WireMessage(
        type: WireMessageType.matchSnapshot,
        seq: 0,
        payload: <String, dynamic>{'version': 1},
      );

      final result = dataSource.tryParseMatchSnapshot(message);

      expect(result, isNull);
    });
  });

  group('tryParseMatchDiff', () {
    test('parses a match_diff message to MatchDiffData', () {
      final message = dataSource.createMatchDiffMessage(
        playerId: 'p1',
        count: 5,
        version: 2,
      );

      final result = dataSource.tryParseMatchDiff(message);

      expect(result, isNotNull);
      expect(result!.playerId, 'p1');
      expect(result.count, 5);
      expect(result.version, 2);
    });

    test('returns null for a non-match_diff message', () {
      const message = WireMessage(
        type: WireMessageType.matchSnapshot,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseMatchDiff(message);

      expect(result, isNull);
    });

    test('returns null when payload is missing fields', () {
      const message = WireMessage(
        type: WireMessageType.matchDiff,
        seq: 0,
        payload: <String, dynamic>{'playerId': 'p1'},
      );

      final result = dataSource.tryParseMatchDiff(message);

      expect(result, isNull);
    });
  });

  group('tryParseErrorReason', () {
    test('parses an error message and returns the reason', () {
      final message = dataSource.createErrorMessage(
        reason: 'invalid move',
      );

      final result = dataSource.tryParseErrorReason(message);

      expect(result, 'invalid move');
    });

    test('returns null for a non-error message', () {
      const message = WireMessage(
        type: WireMessageType.matchSnapshot,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseErrorReason(message);

      expect(result, isNull);
    });

    test('returns null when payload is missing reason', () {
      const message = WireMessage(
        type: WireMessageType.error,
        seq: 0,
        payload: <String, dynamic>{},
      );

      final result = dataSource.tryParseErrorReason(message);

      expect(result, isNull);
    });
  });

  group('tryParseIncrementTerritoriesPlayerId', () {
    test(
      'parses an increment_territories_request and returns the playerId',
      () {
        final message = dataSource.createIncrementTerritoriesMessage(
          playerId: 'p1',
        );

        final result = dataSource.tryParseIncrementTerritoriesPlayerId(message);

        expect(result, 'p1');
      },
    );

    test('returns null for a non-increment message', () {
      const message = WireMessage(
        type: WireMessageType.matchSnapshot,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseIncrementTerritoriesPlayerId(message);

      expect(result, isNull);
    });

    test('returns null when payload is missing playerId', () {
      const message = WireMessage(
        type: WireMessageType.incrementTerritoriesRequest,
        seq: 0,
        payload: <String, dynamic>{},
      );

      final result = dataSource.tryParseIncrementTerritoriesPlayerId(message);

      expect(result, isNull);
    });
  });

  group('tryParseDecrementTerritoriesPlayerId', () {
    test('parses a decrement_territories_request and returns the playerId', () {
      final message = dataSource.createDecrementTerritoriesMessage(
        playerId: 'p1',
      );

      final result = dataSource.tryParseDecrementTerritoriesPlayerId(message);

      expect(result, 'p1');
    });

    test('returns null for a non-decrement message', () {
      const message = WireMessage(
        type: WireMessageType.matchSnapshot,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseDecrementTerritoriesPlayerId(message);

      expect(result, isNull);
    });

    test('returns null when payload is missing playerId', () {
      const message = WireMessage(
        type: WireMessageType.decrementTerritoriesRequest,
        seq: 0,
        payload: <String, dynamic>{},
      );

      final result = dataSource.tryParseDecrementTerritoriesPlayerId(message);

      expect(result, isNull);
    });
  });

  group('tryParseSetTerritories', () {
    test('parses a set_territories_request to SetTerritoriesData', () {
      final message = dataSource.createSetTerritoriesMessage(
        playerId: 'p1',
        count: 15,
      );

      final result = dataSource.tryParseSetTerritories(message);

      expect(result, isNotNull);
      expect(result!.playerId, 'p1');
      expect(result.count, 15);
    });

    test('returns null for a non-set-territories message', () {
      const message = WireMessage(
        type: WireMessageType.matchSnapshot,
        seq: 0,
        payload: {},
      );

      final result = dataSource.tryParseSetTerritories(message);

      expect(result, isNull);
    });

    test('returns null when payload is missing playerId', () {
      const message = WireMessage(
        type: WireMessageType.setTerritoriesRequest,
        seq: 0,
        payload: <String, dynamic>{'count': 15},
      );

      final result = dataSource.tryParseSetTerritories(message);

      expect(result, isNull);
    });

    test('returns null when payload is missing count', () {
      const message = WireMessage(
        type: WireMessageType.setTerritoriesRequest,
        seq: 0,
        payload: <String, dynamic>{'playerId': 'p1'},
      );

      final result = dataSource.tryParseSetTerritories(message);

      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip
  // ---------------------------------------------------------------------------

  group('MatchState round-trip', () {
    test('createMatchSnapshotMessage -> tryParseMatchSnapshot', () {
      final message = dataSource.createMatchSnapshotMessage(matchState, 1);

      final result = dataSource.tryParseMatchSnapshot(message);

      expect(result, isNotNull);
      expect(result!.version, matchState.version);
      expect(result.room.id, matchState.room.id);
      expect(result.room.hostPlayerId, matchState.room.hostPlayerId);
      expect(result.room.status, matchState.room.status);

      for (final entry in matchState.territoriesByPlayer.entries) {
        final actual = result.territoriesByPlayer[entry.key];
        expect(actual, isNotNull);
        expect(actual!.playerId, entry.value.playerId);
        expect(actual.count, entry.value.count);
      }
    });
  });
}
