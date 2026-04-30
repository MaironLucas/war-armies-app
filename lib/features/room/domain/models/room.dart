import 'package:war_armies_app/features/room/domain/models/player.dart';

enum RoomStatus { lobby, active, ended }

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.hostPlayerId,
    required this.players,
    required this.status,
  });

  final String id;
  final String name;
  final String hostPlayerId;
  final List<Player> players;
  final RoomStatus status;
}
