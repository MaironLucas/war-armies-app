import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message_type.dart';
import 'package:war_armies_app/common/transport/domain/models/connection_state.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/common/transport/domain/repositories/game_transport.dart';
import 'package:war_armies_app/features/room/data/data_sources/room_data_source.dart';
import 'package:war_armies_app/features/room/data/exceptions/room_exceptions.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository_impl.dart';

class MockGameTransport extends Mock implements GameTransport {}

/// Helper to create a [RoomDescriptor] for testing.
RoomDescriptor createDescriptor({
  String id = 'room-1',
  String name = 'Test Room',
  String host = '192.168.1.1',
  int port = 12345,
}) {
  return RoomDescriptor(id: id, name: name, host: host, port: port);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const WireMessage(type: '', seq: 0, payload: {}));
    registerFallbackValue(const RoomDescriptor(id: '', name: '', host: '', port: 0));
  });

  const roomDataSource = RoomDataSource();

  late MockGameTransport transport;
  late StreamController<WireMessage> incomingController;
  late StreamController<ConnectionState> connectionStateController;
  late StreamController<List<RoomDescriptor>> discoverController;
  late RoomRepositoryImpl repository;

  setUp(() {
    transport = MockGameTransport();
    incomingController = StreamController<WireMessage>.broadcast();
    connectionStateController = StreamController<ConnectionState>.broadcast();
    discoverController = StreamController<List<RoomDescriptor>>.broadcast();

    when(() => transport.incoming).thenAnswer((_) => incomingController.stream);
    when(
      () => transport.connectionState,
    ).thenAnswer((_) => connectionStateController.stream);
    when(
      () => transport.discover(),
    ).thenAnswer((_) => discoverController.stream);
    when(() => transport.send(any())).thenAnswer((_) async {});
    when(() => transport.close()).thenAnswer((_) async {});

    repository = RoomRepositoryImpl(transport: transport);
  });

  tearDown(() async {
    await incomingController.close();
    await connectionStateController.close();
    await discoverController.close();
  });

  // ---------------------------------------------------------------------------
  // hostRoom
  // ---------------------------------------------------------------------------
  group('hostRoom', () {
    test(
      'calls transport.host() and returns a Room with correct properties',
      () async {
        final descriptor = createDescriptor();
        when(
          () => transport.host(roomName: any(named: 'roomName')),
        ).thenAnswer((_) async => descriptor);

        final room = await repository.hostRoom(
          roomName: 'Test Room',
          hostPlayerName: 'Alice',
        );

        // Delegates to transport
        verify(() => transport.host(roomName: 'Test Room')).called(1);

        // Room properties
        expect(room.id, descriptor.id);
        expect(room.name, 'Test Room');
        expect(room.status, RoomStatus.lobby);
        expect(room.players, hasLength(1));
        expect(room.players[0].name, 'Alice');
        expect(room.hostPlayerId, room.players[0].id);
      },
    );

    test('throws RoomException when already in a room', () async {
      final descriptor = createDescriptor();
      when(
        () => transport.host(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => descriptor);

      await repository.hostRoom(roomName: 'Test Room', hostPlayerName: 'Alice');

      expect(
        () =>
            repository.hostRoom(roomName: 'Attempt 2', hostPlayerName: 'Alice'),
        throwsA(isA<RoomException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // joinRoom
  // ---------------------------------------------------------------------------
  group('joinRoom', () {
    test(
      'calls transport.join(), sends join_request, and returns a Room',
      () async {
        final descriptor = createDescriptor();
        when(() => transport.join(any())).thenAnswer((_) async {});

        final room = await repository.joinRoom(
          descriptor: descriptor,
          playerName: 'Bob',
        );

        // Delegates to transport
        verify(() => transport.join(descriptor)).called(1);

        // Sends a join_request message
        final captured = verify(() => transport.send(captureAny())).captured;
        expect(captured, hasLength(1));
        final message = captured.first as WireMessage;
        expect(message.type, WireMessageType.joinRequest);
        expect(message.payload['playerName'], 'Bob');

        // Room properties
        expect(room.id, descriptor.id);
        expect(room.name, descriptor.name);
        expect(room.status, RoomStatus.lobby);
        expect(room.players, hasLength(1));
        expect(room.players[0].name, 'Bob');
      },
    );

    test('throws RoomException when already in a room', () async {
      final descriptor = createDescriptor();
      when(
        () => transport.host(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => descriptor);
      when(() => transport.join(any())).thenAnswer((_) async {});

      await repository.hostRoom(roomName: 'Test Room', hostPlayerName: 'Alice');

      expect(
        () => repository.joinRoom(descriptor: descriptor, playerName: 'Bob'),
        throwsA(isA<RoomException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // discoverRooms
  // ---------------------------------------------------------------------------
  group('discoverRooms', () {
    test('delegates to transport.discover()', () async {
      final stream = repository.discoverRooms();

      verify(() => transport.discover()).called(1);
      expect(stream, isA<Stream<List<RoomDescriptor>>>());
    });
  });

  // ---------------------------------------------------------------------------
  // watchRoom
  // ---------------------------------------------------------------------------
  group('watchRoom', () {
    test('emits room state when a room is hosted', () async {
      final descriptor = createDescriptor();
      when(
        () => transport.host(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => descriptor);

      // Subscribe to watchRoom BEFORE calling hostRoom
      final roomFuture = repository.watchRoom().first;

      await repository.hostRoom(roomName: 'Test Room', hostPlayerName: 'Alice');

      final room = await roomFuture;
      expect(room.name, 'Test Room');
      expect(room.players, hasLength(1));
    });

    test('emits room state when joining a room', () async {
      final descriptor = createDescriptor();
      when(() => transport.join(any())).thenAnswer((_) async {});

      // Subscribe to watchRoom BEFORE calling joinRoom
      final roomFuture = repository.watchRoom().first;

      await repository.joinRoom(descriptor: descriptor, playerName: 'Bob');

      final room = await roomFuture;
      expect(room.name, descriptor.name);
    });
  });

  // ---------------------------------------------------------------------------
  // leaveRoom
  // ---------------------------------------------------------------------------
  group('leaveRoom', () {
    test(
      'sends leave_request when guest and calls transport.close()',
      () async {
        final descriptor = createDescriptor();
        when(() => transport.join(any())).thenAnswer((_) async {});

        await repository.joinRoom(descriptor: descriptor, playerName: 'Bob');

        // Clear recorded send calls from joinRoom so we only track the leave
        clearInteractions(transport);

        await repository.leaveRoom();

        // Sends leave_request
        final captured = verify(() => transport.send(captureAny())).captured;
        expect(captured, hasLength(1));
        final message = captured.first as WireMessage;
        expect(message.type, WireMessageType.leaveRequest);

        // Closes transport
        verify(() => transport.close()).called(1);
      },
    );

    test(
      'does not send leave_request when host and calls transport.close()',
      () async {
        final descriptor = createDescriptor();
        when(
          () => transport.host(roomName: any(named: 'roomName')),
        ).thenAnswer((_) async => descriptor);

        await repository.hostRoom(
          roomName: 'Test Room',
          hostPlayerName: 'Alice',
        );

        await repository.leaveRoom();

        // No messages sent to transport
        verifyNever(() => transport.send(any()));

        // Closes transport
        verify(() => transport.close()).called(1);
      },
    );

    test('is safe to call when not in a room', () async {
      await repository.leaveRoom();

      verifyNever(() => transport.send(any()));
      verifyNever(() => transport.close());
    });
  });

  // ---------------------------------------------------------------------------
  // Incoming messages (host side)
  // ---------------------------------------------------------------------------
  group('incoming join_request (host side)', () {
    test('adds player to room and broadcasts room_state', () async {
      final descriptor = createDescriptor();
      when(
        () => transport.host(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => descriptor);

      // Subscribe to watchRoom BEFORE hostRoom
      final roomStates = <Room>[];
      repository.watchRoom().listen(roomStates.add);

      await repository.hostRoom(roomName: 'Test Room', hostPlayerName: 'Alice');

      // Wait for initial room event to be received by the listener
      await Future<void>.delayed(Duration.zero);

      // Verify initial state
      expect(roomStates, hasLength(1));

      // Send a join_request for a second player
      final joinMessage = roomDataSource.createJoinRequestMessage(
        playerId: 'guest-1',
        playerName: 'Bob',
        colorValue: const Color(0xFF2196F3).toARGB32(),
      );
      incomingController.add(joinMessage);

      // Wait for the incoming message handler and room update
      await Future<void>.delayed(Duration.zero);

      // Room now has 2 players
      expect(roomStates, hasLength(2));
      expect(roomStates[1].players, hasLength(2));
      expect(roomStates[1].players[1].name, 'Bob');

      // Host broadcast a room_state message to all guests
      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.roomState);
    });
  });

  group('incoming leave_request (host side)', () {
    test('removes player from room and broadcasts room_state', () async {
      final descriptor = createDescriptor();
      when(
        () => transport.host(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => descriptor);

      // Subscribe to watchRoom BEFORE hostRoom
      final roomStates = <Room>[];
      repository.watchRoom().listen(roomStates.add);

      await repository.hostRoom(roomName: 'Test Room', hostPlayerName: 'Alice');

      // Wait for initial room event
      await Future<void>.delayed(Duration.zero);

      // Add a guest player first
      final joinMessage = roomDataSource.createJoinRequestMessage(
        playerId: 'guest-1',
        playerName: 'Bob',
        colorValue: const Color(0xFF2196F3).toARGB32(),
      );
      incomingController.add(joinMessage);
      await Future<void>.delayed(Duration.zero);

      expect(roomStates, hasLength(2));
      expect(roomStates[1].players, hasLength(2));

      // Clear the recorded interactions so we only track the leave broadcast
      clearInteractions(transport);

      // Send a leave_request from the guest
      final leaveMessage = roomDataSource.createLeaveRequestMessage(
        playerId: 'guest-1',
      );
      incomingController.add(leaveMessage);
      await Future<void>.delayed(Duration.zero);

      // Room now has 1 player again
      expect(roomStates, hasLength(3));
      expect(roomStates[2].players, hasLength(1));
      expect(roomStates[2].players.every((p) => p.id != 'guest-1'), isTrue);

      // An additional room_state broadcast happened for the leave
      final captured = verify(() => transport.send(captureAny())).captured;
      expect(captured, hasLength(1));
      final message = captured.first as WireMessage;
      expect(message.type, WireMessageType.roomState);
    });
  });

  // ---------------------------------------------------------------------------
  // Incoming messages (guest side)
  // ---------------------------------------------------------------------------
  group('incoming room_state (guest side)', () {
    test('updates current room with host data', () async {
      final descriptor = createDescriptor();
      when(() => transport.join(any())).thenAnswer((_) async {});

      // Subscribe to watchRoom BEFORE joinRoom
      final roomStates = <Room>[];
      repository.watchRoom().listen(roomStates.add);

      await repository.joinRoom(descriptor: descriptor, playerName: 'Bob');

      // Wait for initial room event
      await Future<void>.delayed(Duration.zero);

      // Placeholder room has no hostPlayerId
      expect(roomStates, hasLength(1));
      expect(roomStates[0].hostPlayerId, '');

      // Simulate host sending a room_state with the full room
      const hostPlayer = Player(
        id: 'host-1',
        name: 'Alice',
        color: Color(0xFF4CAF50),
      );
      const guestPlayer = Player(
        id: 'guest-1',
        name: 'Bob',
        color: Color(0xFF2196F3),
      );
      final updatedRoom = Room(
        id: descriptor.id,
        name: descriptor.name,
        hostPlayerId: 'host-1',
        players: [hostPlayer, guestPlayer],
        status: RoomStatus.lobby,
      );

      final roomStateMessage = roomDataSource.createRoomStateMessage(
        updatedRoom,
        0,
      );
      incomingController.add(roomStateMessage);

      // Wait for the incoming message to be processed
      await Future<void>.delayed(Duration.zero);

      // Room updated with host data
      expect(roomStates, hasLength(2));
      expect(roomStates[1].hostPlayerId, 'host-1');
      expect(roomStates[1].players, hasLength(2));
      expect(roomStates[1].players[0].name, 'Alice');
    });
  });
}
