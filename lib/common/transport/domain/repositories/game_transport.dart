import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/domain/models/connection_state.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';

abstract class GameTransport {
  Stream<ConnectionState> get connectionState;
  Stream<WireMessage> get incoming;

  Future<RoomDescriptor> host({required String roomName});
  Future<void> join(RoomDescriptor descriptor);
  Stream<List<RoomDescriptor>> discover();
  Future<void> send(WireMessage message);
  Future<void> close();
}
