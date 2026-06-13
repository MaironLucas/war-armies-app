import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/models/player_territories.dart';
import 'package:war_armies_app/features/room/data/mappers/room_mappers.dart';

/// Converts between domain models and JSON-compatible maps for the Game
/// feature.
class MatchMappers {
  const MatchMappers._();

  // ---------------------------------------------------------------------------
  // MatchState
  // ---------------------------------------------------------------------------

  /// Converts a [MatchState] to a JSON-compatible map.
  static Map<String, dynamic> matchStateToMap(MatchState state) {
    return {
      'room': RoomMappers.roomToMap(state.room),
      'territoriesByPlayer': state.territoriesByPlayer.map(
        (playerId, territories) =>
            MapEntry(playerId, playerTerritoriesToMap(territories)),
      ),
      'version': state.version,
    };
  }

  /// Converts a JSON-compatible map to a [MatchState].
  ///
  /// Returns `null` if the map is missing required fields.
  static MatchState? tryMapToMatchState(Map<String, dynamic> map) {
    final roomMap = map['room'] as Map<String, dynamic>?;
    final version = map['version'] as int?;
    final territoriesMap = map['territoriesByPlayer'] as Map<String, dynamic>?;

    if (roomMap == null || version == null || territoriesMap == null) {
      return null;
    }

    final room = RoomMappers.tryMapToRoom(roomMap);
    if (room == null) return null;

    final territoriesByPlayer = <String, PlayerTerritories>{};
    for (final entry in territoriesMap.entries) {
      if (entry.value is Map<String, dynamic>) {
        final territories = tryMapToPlayerTerritories(
          entry.value as Map<String, dynamic>,
        );
        if (territories != null) {
          territoriesByPlayer[entry.key] = territories;
        }
      }
    }

    return MatchState(
      room: room,
      territoriesByPlayer: territoriesByPlayer,
      version: version,
    );
  }

  // ---------------------------------------------------------------------------
  // PlayerTerritories
  // ---------------------------------------------------------------------------

  /// Converts a [PlayerTerritories] to a JSON-compatible map.
  static Map<String, dynamic> playerTerritoriesToMap(PlayerTerritories pt) {
    return {'playerId': pt.playerId, 'count': pt.count};
  }

  /// Converts a JSON-compatible map to a [PlayerTerritories].
  ///
  /// Returns `null` if the map is missing required fields.
  static PlayerTerritories? tryMapToPlayerTerritories(
    Map<String, dynamic> map,
  ) {
    final playerId = map['playerId'] as String?;
    final count = map['count'] as int?;

    if (playerId == null || count == null) return null;

    return PlayerTerritories(playerId: playerId, count: count);
  }
}
