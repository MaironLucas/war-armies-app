import 'dart:async';
import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/models/player_territories.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository.dart';
import 'package:war_armies_app/features/game/presentation/cubits/host_match_cubit.dart';
import 'package:war_armies_app/features/game/presentation/cubits/host_match_state.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  const localPlayerId = 'player-1';
  const otherPlayerId = 'player-2';
  const playerColor = Color(0xFF4CAF50);

  late Player player1;
  late Player player2;
  late Room room;
  late MatchState matchState;

  late MockMatchRepository mockRepository;
  late StreamController<MatchState> watchController;

  setUp(() {
    mockRepository = MockMatchRepository();
    watchController = StreamController<MatchState>.broadcast();

    player1 = const Player(
      id: localPlayerId,
      name: 'Alice',
      color: playerColor,
    );
    player2 = const Player(id: otherPlayerId, name: 'Bob', color: playerColor);
    room = Room(
      id: 'room-1',
      name: 'Test Room',
      hostPlayerId: localPlayerId,
      players: [player1, player2],
      status: RoomStatus.lobby,
    );
    matchState = MatchState(
      room: room,
      territoriesByPlayer: {
        localPlayerId: const PlayerTerritories(
          playerId: localPlayerId,
          count: 0,
        ),
        otherPlayerId: const PlayerTerritories(
          playerId: otherPlayerId,
          count: 0,
        ),
      },
      version: 1,
    );
  });

  tearDown(() {
    watchController.close();
  });

  group('HostMatchCubit', () {
    test('initial state has status initial', () {
      final cubit = HostMatchCubit(matchRepository: mockRepository);
      expect(cubit.state, const HostMatchState());
      cubit.close();
    });

    blocTest<HostMatchCubit, HostMatchState>(
      'emits [starting, active] when initializeMatch succeeds',
      build: () {
        when(() => mockRepository.initializeMatch(room)).thenReturn(matchState);
        when(
          () => mockRepository.watchMatch(),
        ).thenAnswer((_) => watchController.stream);
        return HostMatchCubit(matchRepository: mockRepository);
      },
      act: (cubit) => cubit.initializeMatch(room),
      expect: () => [
        const HostMatchState(status: HostMatchStatus.starting),
        HostMatchState(status: HostMatchStatus.active, matchState: matchState),
      ],
    );

    blocTest<HostMatchCubit, HostMatchState>(
      'emits [starting, error] when initializeMatch throws',
      build: () {
        when(
          () => mockRepository.initializeMatch(room),
        ).thenThrow(Exception('init failed'));
        when(
          () => mockRepository.watchMatch(),
        ).thenAnswer((_) => watchController.stream);
        return HostMatchCubit(matchRepository: mockRepository);
      },
      act: (cubit) => cubit.initializeMatch(room),
      expect: () => [
        const HostMatchState(status: HostMatchStatus.starting),
        const HostMatchState(
          status: HostMatchStatus.error,
          errorMessage: 'Exception: init failed',
        ),
      ],
    );

    blocTest<HostMatchCubit, HostMatchState>(
      'emits updated match state when watchMatch emits after initializeMatch',
      build: () {
        when(() => mockRepository.initializeMatch(room)).thenReturn(matchState);
        when(
          () => mockRepository.watchMatch(),
        ).thenAnswer((_) => watchController.stream);
        return HostMatchCubit(matchRepository: mockRepository);
      },
      act: (cubit) async {
        await cubit.initializeMatch(room);

        final updatedMatchState = MatchState(
          room: room,
          territoriesByPlayer: {
            localPlayerId: const PlayerTerritories(
              playerId: localPlayerId,
              count: 5,
            ),
            otherPlayerId: const PlayerTerritories(
              playerId: otherPlayerId,
              count: 3,
            ),
          },
          version: 2,
        );
        watchController.add(updatedMatchState);
      },
      expect: () => [
        const HostMatchState(status: HostMatchStatus.starting),
        HostMatchState(status: HostMatchStatus.active, matchState: matchState),
        isA<HostMatchState>()
            .having((s) => s.status, 'status', HostMatchStatus.active)
            .having((s) => s.matchState?.version, 'version', 2)
            .having(
              (s) => s.matchState?.territoriesByPlayer[localPlayerId]?.count,
              'player-1 count',
              5,
            )
            .having(
              (s) => s.matchState?.territoriesByPlayer[otherPlayerId]?.count,
              'player-2 count',
              3,
            ),
      ],
    );

    blocTest<HostMatchCubit, HostMatchState>(
      'incrementTerritories calls repository.requestIncrementTerritories',
      build: () {
        when(
          () => mockRepository.requestIncrementTerritories(any()),
        ).thenAnswer((_) async {});
        return HostMatchCubit(matchRepository: mockRepository);
      },
      act: (cubit) => cubit.incrementTerritories(localPlayerId),
      verify: (_) {
        verify(
          () => mockRepository.requestIncrementTerritories(localPlayerId),
        ).called(1);
      },
    );

    blocTest<HostMatchCubit, HostMatchState>(
      'decrementTerritories calls repository.requestDecrementTerritories',
      build: () {
        when(
          () => mockRepository.requestDecrementTerritories(any()),
        ).thenAnswer((_) async {});
        return HostMatchCubit(matchRepository: mockRepository);
      },
      act: (cubit) => cubit.decrementTerritories(localPlayerId),
      verify: (_) {
        verify(
          () => mockRepository.requestDecrementTerritories(localPlayerId),
        ).called(1);
      },
    );

    blocTest<HostMatchCubit, HostMatchState>(
      'setTerritories calls repository.setTerritories',
      build: () {
        when(
          () => mockRepository.setTerritories(any(), any()),
        ).thenAnswer((_) async {});
        return HostMatchCubit(matchRepository: mockRepository);
      },
      act: (cubit) => cubit.setTerritories(localPlayerId, 7),
      verify: (_) {
        verify(() => mockRepository.setTerritories(localPlayerId, 7)).called(1);
      },
    );
  });
}
