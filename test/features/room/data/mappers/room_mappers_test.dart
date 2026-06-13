import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:war_armies_app/features/room/data/mappers/room_mappers.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

void main() {
  group('RoomMappers', () {
    const red = Color(0xFFFF0000);
    const green = Color(0xFF00FF00);

    const player = Player(id: 'p1', name: 'Alice', color: red);

    const otherPlayer = Player(id: 'p2', name: 'Bob', color: green);

    const room = Room(
      id: 'r1',
      name: 'Test Room',
      hostPlayerId: 'p1',
      players: [player, otherPlayer],
      status: RoomStatus.lobby,
    );

    group('playerToMap', () {
      test('correctly serializes a Player including Color to int', () {
        final map = RoomMappers.playerToMap(player);

        expect(map, isA<Map<String, dynamic>>());
        expect(map['id'], equals('p1'));
        expect(map['name'], equals('Alice'));
        expect(map['colorValue'], equals(red.toARGB32()));
        expect(map['colorValue'], isA<int>());
      });
    });

    group('tryMapToPlayer', () {
      test('correctly deserializes a Player including int to Color', () {
        final map = <String, dynamic>{
          'id': 'p1',
          'name': 'Alice',
          'colorValue': red.toARGB32(),
        };

        final result = RoomMappers.tryMapToPlayer(map);

        expect(result, isNotNull);
        expect(result!.id, equals('p1'));
        expect(result.name, equals('Alice'));
        expect(result.color, equals(red));
      });

      test('returns null for missing id', () {
        final map = <String, dynamic>{
          'name': 'Alice',
          'colorValue': red.toARGB32(),
        };

        expect(RoomMappers.tryMapToPlayer(map), isNull);
      });

      test('returns null for missing name', () {
        final map = <String, dynamic>{'id': 'p1', 'colorValue': red.toARGB32()};

        expect(RoomMappers.tryMapToPlayer(map), isNull);
      });

      test('returns null for missing colorValue', () {
        final map = <String, dynamic>{'id': 'p1', 'name': 'Alice'};

        expect(RoomMappers.tryMapToPlayer(map), isNull);
      });

      test('throws TypeError for wrong colorValue type', () {
        final map = <String, dynamic>{
          'id': 'p1',
          'name': 'Alice',
          'colorValue': 'not_an_int',
        };

        expect(
          () => RoomMappers.tryMapToPlayer(map),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('roomToMap', () {
      test(
        'correctly serializes a Room with nested players and status enum',
        () {
          final map = RoomMappers.roomToMap(room);

          expect(map, isA<Map<String, dynamic>>());
          expect(map['id'], equals('r1'));
          expect(map['name'], equals('Test Room'));
          expect(map['hostPlayerId'], equals('p1'));
          expect(map['status'], equals('lobby'));

          final players = map['players'] as List<dynamic>;
          expect(players, hasLength(2));

          final firstPlayer = players[0] as Map<String, dynamic>;
          expect(firstPlayer['id'], equals('p1'));
          expect(firstPlayer['name'], equals('Alice'));
          expect(firstPlayer['colorValue'], equals(red.toARGB32()));

          final secondPlayer = players[1] as Map<String, dynamic>;
          expect(secondPlayer['id'], equals('p2'));
          expect(secondPlayer['name'], equals('Bob'));
          expect(secondPlayer['colorValue'], equals(green.toARGB32()));
        },
      );
    });

    group('tryMapToRoom', () {
      test('correctly deserializes a Room', () {
        final map = <String, dynamic>{
          'id': 'r1',
          'name': 'Test Room',
          'hostPlayerId': 'p1',
          'status': 'lobby',
          'players': [
            {'id': 'p1', 'name': 'Alice', 'colorValue': red.toARGB32()},
            {'id': 'p2', 'name': 'Bob', 'colorValue': green.toARGB32()},
          ],
        };

        final result = RoomMappers.tryMapToRoom(map);

        expect(result, isNotNull);
        expect(result!.id, equals('r1'));
        expect(result.name, equals('Test Room'));
        expect(result.hostPlayerId, equals('p1'));
        expect(result.status, equals(RoomStatus.lobby));
        expect(result.players, hasLength(2));
        expect(result.players[0].id, equals('p1'));
        expect(result.players[0].name, equals('Alice'));
        expect(result.players[0].color, equals(red));
        expect(result.players[1].id, equals('p2'));
        expect(result.players[1].name, equals('Bob'));
        expect(result.players[1].color, equals(green));
      });

      test('returns null for missing id', () {
        final map = <String, dynamic>{
          'name': 'Test Room',
          'hostPlayerId': 'p1',
          'status': 'lobby',
        };

        expect(RoomMappers.tryMapToRoom(map), isNull);
      });

      test('returns null for missing name', () {
        final map = <String, dynamic>{
          'id': 'r1',
          'hostPlayerId': 'p1',
          'status': 'lobby',
        };

        expect(RoomMappers.tryMapToRoom(map), isNull);
      });

      test('returns null for missing hostPlayerId', () {
        final map = <String, dynamic>{
          'id': 'r1',
          'name': 'Test Room',
          'status': 'lobby',
        };

        expect(RoomMappers.tryMapToRoom(map), isNull);
      });

      test('returns null for missing status', () {
        final map = <String, dynamic>{
          'id': 'r1',
          'name': 'Test Room',
          'hostPlayerId': 'p1',
        };

        expect(RoomMappers.tryMapToRoom(map), isNull);
      });

      test('returns null for invalid status string', () {
        final map = <String, dynamic>{
          'id': 'r1',
          'name': 'Test Room',
          'hostPlayerId': 'p1',
          'status': 'invalid_status',
          'players': [],
        };

        expect(RoomMappers.tryMapToRoom(map), isNull);
      });

      test('handles missing players list gracefully', () {
        final map = <String, dynamic>{
          'id': 'r1',
          'name': 'Test Room',
          'hostPlayerId': 'p1',
          'status': 'lobby',
        };

        final result = RoomMappers.tryMapToRoom(map);

        expect(result, isNotNull);
        expect(result!.players, isEmpty);
      });

      test('handles null players gracefully', () {
        final map = <String, dynamic>{
          'id': 'r1',
          'name': 'Test Room',
          'hostPlayerId': 'p1',
          'status': 'lobby',
          'players': null,
        };

        final result = RoomMappers.tryMapToRoom(map);

        expect(result, isNotNull);
        expect(result!.players, isEmpty);
      });
    });

    group('round-trip', () {
      test(
        'roomToMap followed by tryMapToRoom produces an equivalent Room',
        () {
          final serialized = RoomMappers.roomToMap(room);
          final deserialized = RoomMappers.tryMapToRoom(serialized);

          expect(deserialized, isNotNull);
          expect(deserialized!.id, equals(room.id));
          expect(deserialized.name, equals(room.name));
          expect(deserialized.hostPlayerId, equals(room.hostPlayerId));
          expect(deserialized.status, equals(room.status));
          expect(deserialized.players, hasLength(room.players.length));
          for (var i = 0; i < room.players.length; i++) {
            expect(deserialized.players[i].id, equals(room.players[i].id));
            expect(deserialized.players[i].name, equals(room.players[i].name));
            expect(
              deserialized.players[i].color,
              equals(room.players[i].color),
            );
          }
        },
      );

      test(
        'playerToMap followed by tryMapToPlayer produces an equivalent Player',
        () {
          final serialized = RoomMappers.playerToMap(player);
          final deserialized = RoomMappers.tryMapToPlayer(serialized);

          expect(deserialized, isNotNull);
          expect(deserialized!.id, equals(player.id));
          expect(deserialized.name, equals(player.name));
          expect(deserialized.color, equals(player.color));
        },
      );
    });
  });
}
