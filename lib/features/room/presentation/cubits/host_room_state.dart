import 'package:equatable/equatable.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

enum HostRoomStatus { initial, hosting, lobby, error }

class HostRoomState extends Equatable {
  const HostRoomState({
    this.status = HostRoomStatus.initial,
    this.room,
    this.errorMessage,
  });

  final HostRoomStatus status;
  final Room? room;
  final String? errorMessage;

  HostRoomState copyWith({
    HostRoomStatus? status,
    Room? room,
    String? errorMessage,
  }) {
    return HostRoomState(
      status: status ?? this.status,
      room: room ?? this.room,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, room, errorMessage];
}
