import 'package:equatable/equatable.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

enum JoinRoomStatus { initial, discovering, joining, lobby, error }

class JoinRoomState extends Equatable {
  const JoinRoomState({
    this.status = JoinRoomStatus.initial,
    this.discoveredRooms = const [],
    this.joinedRoom,
    this.errorMessage,
  });

  final JoinRoomStatus status;
  final List<RoomDescriptor> discoveredRooms;
  final Room? joinedRoom;
  final String? errorMessage;

  JoinRoomState copyWith({
    JoinRoomStatus? status,
    List<RoomDescriptor>? discoveredRooms,
    Room? joinedRoom,
    String? errorMessage,
  }) {
    return JoinRoomState(
      status: status ?? this.status,
      discoveredRooms: discoveredRooms ?? this.discoveredRooms,
      joinedRoom: joinedRoom ?? this.joinedRoom,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    discoveredRooms,
    joinedRoom,
    errorMessage,
  ];
}
