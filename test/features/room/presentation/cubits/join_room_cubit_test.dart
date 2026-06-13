import 'dart:async';
import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';
import 'package:war_armies_app/features/room/presentation/cubits/join_room_cubit.dart';
import 'package:war_armies_app/features/room/presentation/cubits/join_room_state.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

void main() {
  group('JoinRoomCubit', () {
    const playerHost = Player(id: 'p1', name: 'Host', color: Color(0xFFFF0000));

    const playerGuest = Player(
      id: 'p2',
      name: 'Guest',
      color: Color(0xFF00FF00),
    );

    const roomDescriptor = RoomDescriptor(
      id: 'r1',
      name: 'Test Room',
      host: '192.168.1.10',
      port: 8080,
    );

    const room = Room(
      id: 'r1',
      name: 'Test Room',
      hostPlayerId: 'p1',
      players: [playerHost],
      status: RoomStatus.lobby,
    );

    const updatedRoom = Room(
      id: 'r1',
      name: 'Test Room',
      hostPlayerId: 'p1',
      players: [playerHost, playerGuest],
      status: RoomStatus.lobby,
    );

    late RoomRepository roomRepository;
    late StreamController<Room> watchRoomController;
    late StreamController<List<RoomDescriptor>> discoverController;

    setUpAll(() {
      registerFallbackValue(
        const RoomDescriptor(
          id: 'fallback',
          name: 'fallback',
          host: '0.0.0.0',
          port: 0,
        ),
      );
    });

    setUp(() {
      roomRepository = _MockRoomRepository();
      watchRoomController = StreamController<Room>.broadcast();
      discoverController = StreamController<List<RoomDescriptor>>.broadcast();

      when(
        () => roomRepository.watchRoom(),
      ).thenAnswer((_) => watchRoomController.stream);
      when(
        () => roomRepository.discoverRooms(),
      ).thenAnswer((_) => discoverController.stream);
    });

    tearDown(() {
      watchRoomController.close();
      discoverController.close();
    });

    test('initial state is JoinRoomState with status initial', () {
      expect(
        JoinRoomCubit(roomRepository: roomRepository).state,
        const JoinRoomState(),
      );
    });

    group('startDiscovery', () {
      blocTest<JoinRoomCubit, JoinRoomState>(
        'emits discovering and updates discoveredRooms',
        build: () => JoinRoomCubit(roomRepository: roomRepository),
        act: (cubit) {
          cubit.startDiscovery();
          discoverController.add([roomDescriptor]);
        },
        expect: () => [
          const JoinRoomState(status: JoinRoomStatus.discovering),
          const JoinRoomState(
            status: JoinRoomStatus.discovering,
            discoveredRooms: [roomDescriptor],
          ),
        ],
        wait: const Duration(milliseconds: 50),
      );
    });

    group('joinRoom', () {
      blocTest<JoinRoomCubit, JoinRoomState>(
        'emits [joining, lobby] on success',
        build: () => JoinRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.joinRoom(
              descriptor: any(named: 'descriptor'),
              playerName: any(named: 'playerName'),
            ),
          ).thenAnswer((_) async => room);
        },
        act: (cubit) =>
            cubit.joinRoom(descriptor: roomDescriptor, playerName: 'Player'),
        expect: () => [
          const JoinRoomState(status: JoinRoomStatus.joining),
          const JoinRoomState(status: JoinRoomStatus.lobby, joinedRoom: room),
        ],
      );

      blocTest<JoinRoomCubit, JoinRoomState>(
        'emits [joining, error] when repository throws',
        build: () => JoinRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.joinRoom(
              descriptor: any(named: 'descriptor'),
              playerName: any(named: 'playerName'),
            ),
          ).thenThrow(Exception('Join failed'));
        },
        act: (cubit) =>
            cubit.joinRoom(descriptor: roomDescriptor, playerName: 'Player'),
        expect: () => [
          const JoinRoomState(status: JoinRoomStatus.joining),
          const JoinRoomState(
            status: JoinRoomStatus.error,
            errorMessage: 'Exception: Join failed',
          ),
        ],
      );

      blocTest<JoinRoomCubit, JoinRoomState>(
        'subscribes to watchRoom and emits updated room state',
        build: () => JoinRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.joinRoom(
              descriptor: any(named: 'descriptor'),
              playerName: any(named: 'playerName'),
            ),
          ).thenAnswer((_) async => room);
        },
        act: (cubit) async {
          await cubit.joinRoom(
            descriptor: roomDescriptor,
            playerName: 'Player',
          );

          watchRoomController.add(updatedRoom);
        },
        expect: () => [
          const JoinRoomState(status: JoinRoomStatus.joining),
          const JoinRoomState(status: JoinRoomStatus.lobby, joinedRoom: room),
          const JoinRoomState(
            status: JoinRoomStatus.lobby,
            joinedRoom: updatedRoom,
          ),
        ],
        wait: const Duration(milliseconds: 50),
      );
    });

    group('leaveRoom', () {
      blocTest<JoinRoomCubit, JoinRoomState>(
        'resets state to initial and calls repository',
        build: () => JoinRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.joinRoom(
              descriptor: any(named: 'descriptor'),
              playerName: any(named: 'playerName'),
            ),
          ).thenAnswer((_) async => room);
          when(() => roomRepository.leaveRoom()).thenAnswer((_) async {});
        },
        act: (cubit) async {
          await cubit.joinRoom(
            descriptor: roomDescriptor,
            playerName: 'Player',
          );
          await cubit.leaveRoom();
        },
        expect: () => [
          const JoinRoomState(status: JoinRoomStatus.joining),
          const JoinRoomState(status: JoinRoomStatus.lobby, joinedRoom: room),
          const JoinRoomState(),
        ],
        verify: (_) {
          verify(() => roomRepository.leaveRoom()).called(1);
        },
      );

      blocTest<JoinRoomCubit, JoinRoomState>(
        'cancels subscriptions on leaveRoom',
        build: () => JoinRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.joinRoom(
              descriptor: any(named: 'descriptor'),
              playerName: any(named: 'playerName'),
            ),
          ).thenAnswer((_) async => room);
          when(() => roomRepository.leaveRoom()).thenAnswer((_) async {});
        },
        act: (cubit) async {
          // Start discovery to activate the discovery subscription
          await cubit.startDiscovery();
          expect(discoverController.hasListener, isTrue);

          // joinRoom internally calls stopDiscovery, so the discovery
          // subscription is stopped, and the room subscription starts
          await cubit.joinRoom(
            descriptor: roomDescriptor,
            playerName: 'Player',
          );

          // verify there is a listener on watchRoom after joining
          expect(watchRoomController.hasListener, isTrue);
          // discovery subscription was cancelled by joinRoom
          expect(discoverController.hasListener, isFalse);

          await cubit.leaveRoom();
        },
        expect: () => [
          const JoinRoomState(status: JoinRoomStatus.discovering),
          const JoinRoomState(status: JoinRoomStatus.joining),
          const JoinRoomState(status: JoinRoomStatus.lobby, joinedRoom: room),
          const JoinRoomState(),
        ],
        verify: (_) {
          expect(watchRoomController.hasListener, isFalse);
          expect(discoverController.hasListener, isFalse);
        },
      );
    });
  });
}
