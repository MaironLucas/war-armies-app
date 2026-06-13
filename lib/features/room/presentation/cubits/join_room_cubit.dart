import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';
import 'package:war_armies_app/features/room/presentation/cubits/join_room_state.dart';

class JoinRoomCubit extends Cubit<JoinRoomState> {
  JoinRoomCubit({required RoomRepository roomRepository})
    : _roomRepository = roomRepository,
      super(const JoinRoomState());

  final RoomRepository _roomRepository;

  StreamSubscription<List<RoomDescriptor>>? _discoverySubscription;
  StreamSubscription<Room>? _roomSubscription;

  /// Starts discovering rooms on the local network.
  ///
  /// Emits states: initial → discovering. Discovered rooms are emitted
  /// through [JoinRoomState.discoveredRooms] as they appear/disappear.
  Future<void> startDiscovery() async {
    emit(
      state.copyWith(status: JoinRoomStatus.discovering),
    );

    _discoverySubscription = _roomRepository.discoverRooms().listen((rooms) {
      emit(state.copyWith(discoveredRooms: rooms));
    });
  }

  /// Stops discovering rooms.
  Future<void> stopDiscovery() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
  }

  /// Joins a discovered room with the given [playerName].
  ///
  /// Emits states: discovering → lobby (on success) or error (on failure).
  Future<void> joinRoom({
    required RoomDescriptor descriptor,
    required String playerName,
  }) async {
    emit(state.copyWith(status: JoinRoomStatus.joining));

    try {
      await stopDiscovery();

      final room = await _roomRepository.joinRoom(
        descriptor: descriptor,
        playerName: playerName,
      );

      _roomSubscription = _roomRepository.watchRoom().listen((updatedRoom) {
        emit(state.copyWith(joinedRoom: updatedRoom));
      });

      emit(state.copyWith(status: JoinRoomStatus.lobby, joinedRoom: room));
    } catch (e) {
      emit(
        state.copyWith(
          status: JoinRoomStatus.error,
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

    emit(const JoinRoomState());
  }

  @override
  Future<void> close() {
    _discoverySubscription?.cancel();
    _roomSubscription?.cancel();
    return super.close();
  }
}
