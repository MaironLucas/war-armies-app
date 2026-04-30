import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

abstract class RoomRepository {
  Future<Room> hostRoom({
    required String roomName,
    required String hostPlayerName,
  });

  Future<Room> joinRoom({
    required RoomDescriptor descriptor,
    required String playerName,
  });

  Stream<List<RoomDescriptor>> discoverRooms();

  Stream<Room> watchRoom();

  Future<void> leaveRoom();
}
