import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:war_armies_app/features/game/data/mappers/match_mappers.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/models/player_territories.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

void main() {
  group('PlayerTerritories mappers', () {
    const playerTerritories = PlayerTerritories(
      playerId: 'player-1',
      count: 10,
    );

    group('playerTerritoriesToMap', () {
      test('returns a map with playerId and count', () {
        final map = MatchMappers.playerTerritoriesToMap(playerTerritories);

        expect(map, {'playerId': 'player-1', 'count': 10});
      });
    });

    group('tryMapToPlayerTerritories', () {
      test('parses a valid map', () {
        final map = <String, dynamic>{'playerId': 'player-1', 'count': 10};

        final result = MatchMappers.tryMapToPlayerTerritories(map);

        expect(result, isNotNull);
        expect(result!.playerId, 'player-1');
        expect(result.count, 10);
      });

      test('returns null when playerId is missing', () {
        final result = MatchMappers.tryMapToPlayerTerritories(<String, dynamic>{
          'count': 10,
        });

        expect(result, isNull);
      });

      test('returns null when count is missing', () {
        final result = MatchMappers.tryMapToPlayerTerritories(<String, dynamic>{
          'playerId': 'player-1',
        });

        expect(result, isNull);
      });

      test('throws TypeError when playerId is not a String', () {
        expect(
          () => MatchMappers.tryMapToPlayerTerritories(<String, dynamic>{
            'playerId': 123,
            'count': 10,
          }),
          throwsA(isA<TypeError>()),
        );
      });

      test('throws TypeError when count is not an int', () {
        expect(
          () => MatchMappers.tryMapToPlayerTerritories(<String, dynamic>{
            'playerId': 'player-1',
            'count': 'ten',
          }),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('PlayerTerritories round-trip', () {
      test('playerTerritoriesToMap -> tryMapToPlayerTerritories', () {
        final map = MatchMappers.playerTerritoriesToMap(playerTerritories);
        final result = MatchMappers.tryMapToPlayerTerritories(map);

        expect(result, isNotNull);
        expect(result!.playerId, playerTerritories.playerId);
        expect(result.count, playerTerritories.count);
      });
    });
  });

  group('MatchState mappers', () {
    const player1 = Player(
      id: 'player-1',
      name: 'Alice',
      color: Color(0xFF00FF00),
    );
    const player2 = Player(
      id: 'player-2',
      name: 'Bob',
      color: Color(0xFFFF0000),
    );

    const room = Room(
      id: 'room-1',
      name: 'Test Room',
      hostPlayerId: 'player-1',
      players: [player1, player2],
      status: RoomStatus.lobby,
    );

    const matchState = MatchState(
      room: room,
      territoriesByPlayer: {
        'player-1': PlayerTerritories(playerId: 'player-1', count: 10),
        'player-2': PlayerTerritories(playerId: 'player-2', count: 5),
      },
      version: 3,
    );

    group('matchStateToMap', () {
      test('produces a map with room, territoriesByPlayer, and version', () {
        final map = MatchMappers.matchStateToMap(matchState);

        expect(map['version'], 3);
        expect(map['room'], isA<Map<String, dynamic>>());
        expect(map['territoriesByPlayer'], isA<Map<String, dynamic>>());

        final territories = map['territoriesByPlayer'] as Map<String, dynamic>;
        expect(territories['player-1'], {'playerId': 'player-1', 'count': 10});
        expect(territories['player-2'], {'playerId': 'player-2', 'count': 5});
      });
    });

    group('tryMapToMatchState', () {
      test('parses a valid map', () {
        final map = MatchMappers.matchStateToMap(matchState);
        final result = MatchMappers.tryMapToMatchState(map);

        expect(result, isNotNull);
        expect(result!.version, 3);
        expect(result.room.id, 'room-1');
        expect(result.room.hostPlayerId, 'player-1');
        expect(result.room.status, RoomStatus.lobby);

        final pts = result.territoriesByPlayer;
        expect(pts['player-1']!.playerId, 'player-1');
        expect(pts['player-1']!.count, 10);
        expect(pts['player-2']!.playerId, 'player-2');
        expect(pts['player-2']!.count, 5);
      });

      test('returns null when room map is missing', () {
        final result = MatchMappers.tryMapToMatchState(<String, dynamic>{
          'version': 1,
          'territoriesByPlayer': <String, dynamic>{},
        });

        expect(result, isNull);
      });

      test('returns null when version is missing', () {
        final result = MatchMappers.tryMapToMatchState(<String, dynamic>{
          'room': <String, dynamic>{},
          'territoriesByPlayer': <String, dynamic>{},
        });

        expect(result, isNull);
      });

      test('returns null when territoriesByPlayer is missing', () {
        final result = MatchMappers.tryMapToMatchState(<String, dynamic>{
          'room': <String, dynamic>{},
          'version': 1,
        });

        expect(result, isNull);
      });

      test('returns null when room map is malformed', () {
        final result = MatchMappers.tryMapToMatchState(<String, dynamic>{
          'room': <String, dynamic>{},
          'version': 1,
          'territoriesByPlayer': <String, dynamic>{},
        });

        expect(result, isNull);
      });
    });

    group('MatchState round-trip', () {
      test('matchStateToMap -> tryMapToMatchState preserves all fields', () {
        final map = MatchMappers.matchStateToMap(matchState);
        final result = MatchMappers.tryMapToMatchState(map);

        expect(result, isNotNull);
        expect(result!.version, matchState.version);
        expect(result.room.id, matchState.room.id);
        expect(result.room.name, matchState.room.name);
        expect(result.room.hostPlayerId, matchState.room.hostPlayerId);
        expect(result.room.status, matchState.room.status);
        expect(result.room.players.length, matchState.room.players.length);

        for (final entry in matchState.territoriesByPlayer.entries) {
          final actual = result.territoriesByPlayer[entry.key];
          expect(actual, isNotNull);
          expect(actual!.playerId, entry.value.playerId);
          expect(actual.count, entry.value.count);
          expect(actual.troops, entry.value.troops);
        }
      });
    });
  });
}
