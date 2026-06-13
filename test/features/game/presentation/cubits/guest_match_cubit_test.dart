import 'dart:async';
import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/models/player_territories.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository.dart';
import 'package:war_armies_app/features/game/presentation/cubits/guest_match_cubit.dart';
import 'package:war_armies_app/features/game/presentation/cubits/guest_match_state.dart';
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
      hostPlayerId: otherPlayerId,
      players: [player1, player2],
      status: RoomStatus.active,
    );
    matchState = MatchState(
      room: room,
      territoriesByPlayer: {
        localPlayerId: const PlayerTerritories(
          playerId: localPlayerId,
          count: 3,
        ),
        otherPlayerId: const PlayerTerritories(
          playerId: otherPlayerId,
          count: 5,
        ),
      },
      version: 1,
    );
  });

  tearDown(() {
    watchController.close();
  });

  group('GuestMatchCubit', () {
    test('initial state has status initial and localPlayerId set', () {
      final cubit = GuestMatchCubit(
        matchRepository: mockRepository,
        localPlayerId: localPlayerId,
      );
      expect(cubit.state.status, GuestMatchStatus.initial);
      expect(cubit.state.localPlayerId, localPlayerId);
      cubit.close();
    });

    blocTest<GuestMatchCubit, GuestMatchState>(
      'emits [loading, active] when startListening receives a match state',
      build: () {
        when(
          () => mockRepository.watchMatch(),
        ).thenAnswer((_) => watchController.stream);
        return GuestMatchCubit(
          matchRepository: mockRepository,
          localPlayerId: localPlayerId,
        );
      },
      act: (cubit) {
        cubit.startListening();
        watchController.add(matchState);
      },
      expect: () => [
        const GuestMatchState(
          localPlayerId: localPlayerId,
          status: GuestMatchStatus.loading,
        ),
        GuestMatchState(
          localPlayerId: localPlayerId,
          status: GuestMatchStatus.active,
          matchState: matchState,
        ),
      ],
    );

    blocTest<GuestMatchCubit, GuestMatchState>(
      'incrementTerritories calls repository.requestIncrementTerritories '
      'with localPlayerId',
      build: () {
        when(
          () => mockRepository.requestIncrementTerritories(any()),
        ).thenAnswer((_) async {});
        return GuestMatchCubit(
          matchRepository: mockRepository,
          localPlayerId: localPlayerId,
        );
      },
      act: (cubit) => cubit.incrementTerritories(),
      verify: (_) {
        verify(
          () => mockRepository.requestIncrementTerritories(localPlayerId),
        ).called(1);
      },
    );

    blocTest<GuestMatchCubit, GuestMatchState>(
      'decrementTerritories calls repository.requestDecrementTerritories '
      'with localPlayerId',
      build: () {
        when(
          () => mockRepository.requestDecrementTerritories(any()),
        ).thenAnswer((_) async {});
        return GuestMatchCubit(
          matchRepository: mockRepository,
          localPlayerId: localPlayerId,
        );
      },
      act: (cubit) => cubit.decrementTerritories(),
      verify: (_) {
        verify(
          () => mockRepository.requestDecrementTerritories(localPlayerId),
        ).called(1);
      },
    );

    blocTest<GuestMatchCubit, GuestMatchState>(
      'setTerritories calls repository.setTerritories with localPlayerId '
      'and count',
      build: () {
        when(
          () => mockRepository.setTerritories(any(), any()),
        ).thenAnswer((_) async {});
        return GuestMatchCubit(
          matchRepository: mockRepository,
          localPlayerId: localPlayerId,
        );
      },
      act: (cubit) => cubit.setTerritories(7),
      verify: (_) {
        verify(() => mockRepository.setTerritories(localPlayerId, 7)).called(1);
      },
    );
  });
}
