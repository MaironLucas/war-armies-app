import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';
import 'package:war_armies_app/features/room/presentation/cubits/host_room_state.dart';

class HostRoomCubit extends Cubit<HostRoomState> {
  HostRoomCubit({required RoomRepository roomRepository})
      : _roomRepository = roomRepository,
        super(const HostRoomState());

  // ignore: unused_field
  final RoomRepository _roomRepository;
}
