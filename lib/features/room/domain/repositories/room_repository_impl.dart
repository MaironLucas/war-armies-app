import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/common/transport/domain/repositories/game_transport.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  RoomRepositoryImpl({required GameTransport transport})
      : _transport = transport;

  // ignore: unused_field
  final GameTransport _transport;

  @override
  Future<Room> hostRoom({
    required String roomName,
    required String hostPlayerName,
  }) =>
      throw UnimplementedError();

  @override
  Future<Room> joinRoom({
    required RoomDescriptor descriptor,
    required String playerName,
  }) =>
      throw UnimplementedError();

  @override
  Stream<List<RoomDescriptor>> discoverRooms() => throw UnimplementedError();

  @override
  Stream<Room> watchRoom() => throw UnimplementedError();

  @override
  Future<void> leaveRoom() => throw UnimplementedError();
}
