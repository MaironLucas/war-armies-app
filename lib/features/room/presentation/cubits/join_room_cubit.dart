import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';
import 'package:war_armies_app/features/room/presentation/cubits/join_room_state.dart';

class JoinRoomCubit extends Cubit<JoinRoomState> {
  JoinRoomCubit({required RoomRepository roomRepository})
      : _roomRepository = roomRepository,
        super(const JoinRoomState());

  // ignore: unused_field
  final RoomRepository _roomRepository;
}
