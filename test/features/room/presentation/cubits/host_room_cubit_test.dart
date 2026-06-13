import 'dart:async';
import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';
import 'package:war_armies_app/features/room/presentation/cubits/host_room_cubit.dart';
import 'package:war_armies_app/features/room/presentation/cubits/host_room_state.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

void main() {
  group('HostRoomCubit', () {
    const playerHost = Player(id: 'p1', name: 'Host', color: Color(0xFFFF0000));

    const playerGuest = Player(
      id: 'p2',
      name: 'Guest',
      color: Color(0xFF00FF00),
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

    setUp(() {
      roomRepository = _MockRoomRepository();
      watchRoomController = StreamController<Room>.broadcast();

      when(
        () => roomRepository.watchRoom(),
      ).thenAnswer((_) => watchRoomController.stream);
    });

    tearDown(() {
      watchRoomController.close();
    });

    test('initial state is HostRoomState with status initial', () {
      expect(
        HostRoomCubit(roomRepository: roomRepository).state,
        const HostRoomState(),
      );
    });

    group('hostRoom', () {
      blocTest<HostRoomCubit, HostRoomState>(
        'emits [hosting, lobby] on success',
        build: () => HostRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.hostRoom(
              roomName: any(named: 'roomName'),
              hostPlayerName: any(named: 'hostPlayerName'),
            ),
          ).thenAnswer((_) async => room);
        },
        act: (cubit) =>
            cubit.hostRoom(roomName: 'Test Room', hostPlayerName: 'Host'),
        expect: () => [
          const HostRoomState(status: HostRoomStatus.hosting),
          const HostRoomState(status: HostRoomStatus.lobby, room: room),
        ],
      );

      blocTest<HostRoomCubit, HostRoomState>(
        'emits [hosting, error] when repository throws',
        build: () => HostRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.hostRoom(
              roomName: any(named: 'roomName'),
              hostPlayerName: any(named: 'hostPlayerName'),
            ),
          ).thenThrow(Exception('Host failed'));
        },
        act: (cubit) =>
            cubit.hostRoom(roomName: 'Test Room', hostPlayerName: 'Host'),
        expect: () => [
          const HostRoomState(status: HostRoomStatus.hosting),
          const HostRoomState(
            status: HostRoomStatus.error,
            errorMessage: 'Exception: Host failed',
          ),
        ],
      );

      blocTest<HostRoomCubit, HostRoomState>(
        'subscribes to watchRoom and emits updated room state',
        build: () => HostRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.hostRoom(
              roomName: any(named: 'roomName'),
              hostPlayerName: any(named: 'hostPlayerName'),
            ),
          ).thenAnswer((_) async => room);
        },
        act: (cubit) async {
          await cubit.hostRoom(roomName: 'Test Room', hostPlayerName: 'Host');

          watchRoomController.add(updatedRoom);
        },
        expect: () => [
          const HostRoomState(status: HostRoomStatus.hosting),
          const HostRoomState(status: HostRoomStatus.lobby, room: room),
          const HostRoomState(status: HostRoomStatus.lobby, room: updatedRoom),
        ],
        wait: const Duration(milliseconds: 50),
      );
    });

    group('leaveRoom', () {
      blocTest<HostRoomCubit, HostRoomState>(
        'resets state to initial and calls repository',
        build: () => HostRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.hostRoom(
              roomName: any(named: 'roomName'),
              hostPlayerName: any(named: 'hostPlayerName'),
            ),
          ).thenAnswer((_) async => room);
          when(() => roomRepository.leaveRoom()).thenAnswer((_) async {});
        },
        act: (cubit) async {
          await cubit.hostRoom(roomName: 'Test Room', hostPlayerName: 'Host');
          await cubit.leaveRoom();
        },
        expect: () => [
          const HostRoomState(status: HostRoomStatus.hosting),
          const HostRoomState(status: HostRoomStatus.lobby, room: room),
          const HostRoomState(),
        ],
        verify: (_) {
          verify(() => roomRepository.leaveRoom()).called(1);
        },
      );

      blocTest<HostRoomCubit, HostRoomState>(
        'cancels the watchRoom subscription on leaveRoom',
        build: () => HostRoomCubit(roomRepository: roomRepository),
        setUp: () {
          when(
            () => roomRepository.hostRoom(
              roomName: any(named: 'roomName'),
              hostPlayerName: any(named: 'hostPlayerName'),
            ),
          ).thenAnswer((_) async => room);
          when(() => roomRepository.leaveRoom()).thenAnswer((_) async {});
        },
        act: (cubit) async {
          await cubit.hostRoom(roomName: 'Test Room', hostPlayerName: 'Host');

          // After hostRoom, a subscription on watchRoom should be active
          expect(watchRoomController.hasListener, isTrue);

          await cubit.leaveRoom();
        },
        expect: () => [
          const HostRoomState(status: HostRoomStatus.hosting),
          const HostRoomState(status: HostRoomStatus.lobby, room: room),
          const HostRoomState(),
        ],
        verify: (_) {
          expect(watchRoomController.hasListener, isFalse);
        },
      );
    });
  });
}
