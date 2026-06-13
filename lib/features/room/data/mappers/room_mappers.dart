import 'dart:ui';

import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

/// Converts between domain models and JSON-compatible maps for the Room
/// feature.
///
/// All mappers are pure functions exposed as static methods on a private
/// constructor class so they can be used without instantiation.
class RoomMappers {
  const RoomMappers._();

  // ---------------------------------------------------------------------------
  // Room
  // ---------------------------------------------------------------------------

  /// Converts a [Room] to a JSON-compatible map.
  static Map<String, dynamic> roomToMap(Room room) {
    return {
      'id': room.id,
      'name': room.name,
      'hostPlayerId': room.hostPlayerId,
      'players': room.players.map(playerToMap).toList(),
      'status': room.status.name,
    };
  }

  /// Converts a JSON-compatible map to a [Room].
  ///
  /// Returns `null` if the map is missing required fields.
  static Room? tryMapToRoom(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final name = map['name'] as String?;
    final hostPlayerId = map['hostPlayerId'] as String?;
    final statusStr = map['status'] as String?;
    final playersList = map['players'] as List<dynamic>?;

    if (id == null ||
        name == null ||
        hostPlayerId == null ||
        statusStr == null) {
      return null;
    }

    final status = RoomStatus.values
        .where((s) => s.name == statusStr)
        .firstOrNull;
    if (status == null) return null;

    final players = <Player>[];
    if (playersList != null) {
      for (final p in playersList) {
        if (p is Map<String, dynamic>) {
          final player = tryMapToPlayer(p);
          if (player != null) {
            players.add(player);
          }
        }
      }
    }

    return Room(
      id: id,
      name: name,
      hostPlayerId: hostPlayerId,
      players: players,
      status: status,
    );
  }

  // ---------------------------------------------------------------------------
  // Player
  // ---------------------------------------------------------------------------

  /// Converts a [Player] to a JSON-compatible map.
  ///
  /// The [Color] is serialized as its 32-bit ARGB integer value.
  static Map<String, dynamic> playerToMap(Player player) {
    return {
      'id': player.id,
      'name': player.name,
      'colorValue': player.color.toARGB32(),
    };
  }

  /// Converts a JSON-compatible map to a [Player].
  ///
  /// Returns `null` if the map is missing required fields.
  static Player? tryMapToPlayer(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final name = map['name'] as String?;
    final colorValue = map['colorValue'] as int?;

    if (id == null || name == null || colorValue == null) {
      return null;
    }

    return Player(id: id, name: name, color: Color(colorValue));
  }
}
