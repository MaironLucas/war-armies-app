import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';
import 'package:war_armies_app/features/room/presentation/cubits/host_room_state.dart';

class HostRoomCubit extends Cubit<HostRoomState> {
  HostRoomCubit({required RoomRepository roomRepository})
    : _roomRepository = roomRepository,
      super(const HostRoomState());

  final RoomRepository _roomRepository;

  StreamSubscription<Room>? _roomSubscription;

  /// Starts hosting a room with the given [roomName] and [hostPlayerName].
  ///
  /// Emits states: initial → lobby (on success) or error (on failure).
  Future<void> hostRoom({
    required String roomName,
    required String hostPlayerName,
  }) async {
    emit(state.copyWith(status: HostRoomStatus.hosting));

    try {
      final room = await _roomRepository.hostRoom(
        roomName: roomName,
        hostPlayerName: hostPlayerName,
      );

      _roomSubscription = _roomRepository.watchRoom().listen((updatedRoom) {
        emit(state.copyWith(room: updatedRoom));
      });

      emit(state.copyWith(status: HostRoomStatus.lobby, room: room));
    } catch (e) {
      emit(
        state.copyWith(
          status: HostRoomStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Leaves the current room and resets to initial state.
  Future<void> leaveRoom() async {
    await _roomSubscription?.cancel();
    _roomSubscription = null;

    await _roomRepository.leaveRoom();

    emit(const HostRoomState());
  }

  @override
  Future<void> close() {
    _roomSubscription?.cancel();
    return super.close();
  }
}
