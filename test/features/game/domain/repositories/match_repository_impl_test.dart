import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message_type.dart';
import 'package:war_armies_app/common/transport/domain/repositories/game_transport.dart';
import 'package:war_armies_app/features/game/data/data_sources/match_data_source.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/models/player_territories.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository_impl.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

class MockGameTransport extends Mock implements GameTransport {}

/// Helper to flush pending asynchronous operations (microtasks).
Future<void> flushAsync() => Future<void>(() {});

void main() {
  setUpAll(() {
    registerFallbackValue(
      const WireMessage(type: 'fallback', seq: 0, payload: <String, dynamic>{}),
    );
  });
  late MockGameTransport transport;
  late StreamController<WireMessage> incomingController;
  late MatchRepositoryImpl repository;
  late MatchDataSource dataSource;

  // Test data
  const playerId1 = 'player-1';
  const playerId2 = 'player-2';
  const playerName1 = 'Alice';
  const playerName2 = 'Bob';
  const playerColor = Color(0xFF4CAF50);

  late Player player1;
  late Player player2;
  late Room room;

  setUp(() {
    transport = MockGameTransport();
    incomingController = StreamController<WireMessage>.broadcast();
    dataSource = const MatchDataSource();

    when(() => transport.incoming).thenAnswer((_) => incomingController.stream);
    when(() => transport.send(any())).thenAnswer((_) async {});

    repository = MatchRepositoryImpl(transport: transport);

    player1 = const Player(
      id: playerId1,
      name: playerName1,
      color: playerColor,
    );
    player2 = const Player(
      id: playerId2,
      name: playerName2,
      color: playerColor,
    );
    room = Room(
      id: 'room-1',
      name: 'Test Room',
      hostPlayerId: playerId1,
      players: [player1, player2],
      status: RoomStatus.lobby,
    );
  });

  tearDown(() {
    repository.dispose();
    incomingController.close();
  });

  // ---------------------------------------------------------------------------
  // Request methods — guest → host
  // ---------------------------------------------------------------------------

  group('requestIncrementTerritories', () {
    test('sends increment_territories_request message', () async {
      await repository.requestIncrementTerritories(playerId1);

      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.incrementTerritoriesRequest);
      expect(message.payload['playerId'], playerId1);
    });
  });

  group('requestDecrementTerritories', () {
    test('sends decrement_territories_request message', () async {
      await repository.requestDecrementTerritories(playerId1);

      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.decrementTerritoriesRequest);
      expect(message.payload['playerId'], playerId1);
    });
  });

  group('setTerritories', () {
    test('sends set_territories_request message', () async {
      await repository.setTerritories(playerId1, 10);

      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.setTerritoriesRequest);
      expect(message.payload['playerId'], playerId1);
      expect(message.payload['count'], 10);
    });
  });

  // ---------------------------------------------------------------------------
  // initializeMatch — host-side match setup
  // ---------------------------------------------------------------------------

  group('initializeMatch', () {
    test('creates MatchState with 0 territories per player and version 1', () {
      final matchState = repository.initializeMatch(room);

      expect(matchState.room, room);
      expect(matchState.version, 1);
      expect(matchState.territoriesByPlayer, hasLength(2));

      for (final player in room.players) {
        final entry = matchState.territoriesByPlayer[player.id];
        expect(entry, isNotNull);
        expect(entry!.playerId, player.id);
        expect(entry.count, 0);
      }
    });

    test('broadcasts a match_snapshot message via transport', () async {
      repository.initializeMatch(room);
      await flushAsync();

      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.matchSnapshot);
      expect(message.payload['version'], 1);
      expect(message.payload['room'], isA<Map<String, dynamic>>());
      expect(
        message.payload['territoriesByPlayer'],
        isA<Map<String, dynamic>>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // watchMatch — state stream
  // ---------------------------------------------------------------------------

  group('watchMatch', () {
    test('emits MatchState when a match_snapshot is received', () async {
      repository.startListening();

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      final initialState = MatchState(
        room: room,
        territoriesByPlayer: {
          playerId1: const PlayerTerritories(playerId: playerId1, count: 5),
          playerId2: const PlayerTerritories(playerId: playerId2, count: 3),
        },
        version: 1,
      );
      final snapshotMsg = dataSource.createMatchSnapshotMessage(
        initialState,
        1,
      );
      incomingController.add(snapshotMsg);
      await flushAsync();

      expect(states, hasLength(1));
      expect(states.first.version, 1);
      expect(states.first.territoriesByPlayer[playerId1]!.count, 5);
      expect(states.first.territoriesByPlayer[playerId2]!.count, 3);

      await subscription.cancel();
    });
  });

  // ---------------------------------------------------------------------------
  // Incoming territory requests — host-side processing
  // ---------------------------------------------------------------------------

  group('incoming increment_territories_request (host side)', () {
    test('increments territory count and broadcasts match_diff', () async {
      repository.initializeMatch(room);
      await flushAsync();
      clearInteractions(transport);

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      const incMsg = WireMessage(
        type: WireMessageType.incrementTerritoriesRequest,
        seq: 1,
        payload: <String, dynamic>{'playerId': playerId1},
      );
      incomingController.add(incMsg);
      await flushAsync();

      // State updated via watchMatch
      expect(states, hasLength(1));
      expect(states.first.territoriesByPlayer[playerId1]!.count, 1);
      expect(states.first.territoriesByPlayer[playerId2]!.count, 0);
      expect(states.first.version, 2);

      // Diff broadcast
      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.matchDiff);
      expect(message.payload['playerId'], playerId1);
      expect(message.payload['count'], 1);

      await subscription.cancel();
    });

    test('ignores increment for unknown playerId', () async {
      repository.initializeMatch(room);
      await flushAsync();
      clearInteractions(transport);

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      const incMsg = WireMessage(
        type: WireMessageType.incrementTerritoriesRequest,
        seq: 1,
        payload: <String, dynamic>{'playerId': 'unknown-player'},
      );
      incomingController.add(incMsg);
      await flushAsync();

      expect(states, isEmpty);

      await subscription.cancel();
    });
  });

  group('incoming decrement_territories_request (host side)', () {
    test('decrements territory count and broadcasts match_diff', () async {
      // Initialize match, then set player1 to 5 territories
      repository.initializeMatch(room);
      await flushAsync();

      const setMsg = WireMessage(
        type: WireMessageType.setTerritoriesRequest,
        seq: 1,
        payload: <String, dynamic>{'playerId': playerId1, 'count': 5},
      );
      incomingController.add(setMsg);
      await flushAsync();
      clearInteractions(transport);

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      const decMsg = WireMessage(
        type: WireMessageType.decrementTerritoriesRequest,
        seq: 2,
        payload: <String, dynamic>{'playerId': playerId1},
      );
      incomingController.add(decMsg);
      await flushAsync();

      // 5 → 4
      expect(states, hasLength(1));
      expect(states.first.territoriesByPlayer[playerId1]!.count, 4);
      expect(states.first.version, 3); // init(1) → set(2) → decrement(3)

      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.matchDiff);
      expect(message.payload['playerId'], playerId1);
      expect(message.payload['count'], 4);

      await subscription.cancel();
    });

    test('clamps territory count at 0 (does not go negative)', () async {
      repository.initializeMatch(room);
      await flushAsync();
      clearInteractions(transport);

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      // Player already at 0
      const decMsg = WireMessage(
        type: WireMessageType.decrementTerritoriesRequest,
        seq: 1,
        payload: <String, dynamic>{'playerId': playerId1},
      );
      incomingController.add(decMsg);
      await flushAsync();

      expect(states, hasLength(1));
      expect(states.first.territoriesByPlayer[playerId1]!.count, 0);
      expect(states.first.version, 2);

      await subscription.cancel();
    });
  });

  group('incoming set_territories_request (host side)', () {
    test('sets territory count and broadcasts match_diff', () async {
      repository.initializeMatch(room);
      await flushAsync();
      clearInteractions(transport);

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      const setMsg = WireMessage(
        type: WireMessageType.setTerritoriesRequest,
        seq: 1,
        payload: <String, dynamic>{'playerId': playerId1, 'count': 10},
      );
      incomingController.add(setMsg);
      await flushAsync();

      expect(states, hasLength(1));
      expect(states.first.territoriesByPlayer[playerId1]!.count, 10);
      expect(states.first.version, 2);

      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.matchDiff);
      expect(message.payload['playerId'], playerId1);
      expect(message.payload['count'], 10);

      await subscription.cancel();
    });

    test('clamps negative count to 0', () async {
      repository.initializeMatch(room);
      await flushAsync();
      clearInteractions(transport);

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      const setMsg = WireMessage(
        type: WireMessageType.setTerritoriesRequest,
        seq: 1,
        payload: <String, dynamic>{'playerId': playerId1, 'count': -5},
      );
      incomingController.add(setMsg);
      await flushAsync();

      expect(states, hasLength(1));
      expect(states.first.territoriesByPlayer[playerId1]!.count, 0);

      await subscription.cancel();
    });
  });

  // ---------------------------------------------------------------------------
  // Incoming messages — guest-side processing
  // ---------------------------------------------------------------------------

  group('incoming match_snapshot (guest side)', () {
    test('updates match state and emits via watchMatch', () async {
      repository.startListening();

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      final snapshotState = MatchState(
        room: room,
        territoriesByPlayer: {
          playerId1: const PlayerTerritories(playerId: playerId1, count: 8),
          playerId2: const PlayerTerritories(playerId: playerId2, count: 3),
        },
        version: 2,
      );
      final snapshotMsg = dataSource.createMatchSnapshotMessage(
        snapshotState,
        1,
      );
      incomingController.add(snapshotMsg);
      await flushAsync();

      expect(states, hasLength(1));
      expect(states.first.version, 2);
      expect(states.first.room.id, 'room-1');
      expect(states.first.territoriesByPlayer[playerId1]!.count, 8);
      expect(states.first.territoriesByPlayer[playerId2]!.count, 3);

      await subscription.cancel();
    });
  });

  group('incoming match_diff (guest side)', () {
    test('applies diff to existing match state', () async {
      repository.startListening();

      // Establish initial state via snapshot
      final initial = MatchState(
        room: room,
        territoriesByPlayer: {
          playerId1: const PlayerTerritories(playerId: playerId1, count: 5),
          playerId2: const PlayerTerritories(playerId: playerId2, count: 3),
        },
        version: 1,
      );
      incomingController.add(dataSource.createMatchSnapshotMessage(initial, 1));
      await flushAsync();

      final states = <MatchState>[];
      final subscription = repository.watchMatch().listen(states.add);

      // Apply diff: player1 goes to 10, version bumps to 2
      const diffMsg = WireMessage(
        type: WireMessageType.matchDiff,
        seq: 2,
        payload: <String, dynamic>{
          'playerId': playerId1,
          'count': 10,
          'version': 2,
        },
      );
      incomingController.add(diffMsg);
      await flushAsync();

      expect(states, hasLength(1));
      expect(states.first.version, 2);
      expect(states.first.territoriesByPlayer[playerId1]!.count, 10);
      // player2 unchanged
      expect(states.first.territoriesByPlayer[playerId2]!.count, 3);

      await subscription.cancel();
    });
  });
}
