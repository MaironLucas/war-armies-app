import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/common/routing/app_router.dart';
import 'package:war_armies_app/common/transport/data/repositories/game_transport_impl.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository_impl.dart';
import 'package:war_armies_app/features/room/presentation/presentation.dart';
import 'package:war_armies_app/features/shared/shared.dart';
import 'package:war_armies_app/l10n/l10n.dart';
import 'package:war_armies_app/theme/theme.dart';

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({super.key});

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final _playerNameController = TextEditingController();

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JoinRoomCubit>(
      create: (_) => JoinRoomCubit(
        roomRepository: RoomRepositoryImpl(transport: GameTransportImpl()),
      ),
      child: BlocListener<JoinRoomCubit, JoinRoomState>(
        listenWhen: (previous, current) =>
            current.joinedRoom?.status == RoomStatus.active,
        listener: (context, state) {
          Navigator.pushReplacementNamed(context, AppRouter.guestMatch);
        },
        child: Scaffold(
          appBar: WarAppBar(title: context.l10n.joinGame),
          body: BlocBuilder<JoinRoomCubit, JoinRoomState>(
            builder: (context, state) {
              switch (state.status) {
                case JoinRoomStatus.initial:
                  return _InitialView();
                case JoinRoomStatus.discovering:
                  return _DiscoveringView(
                    playerNameController: _playerNameController,
                    rooms: state.discoveredRooms,
                  );
                case JoinRoomStatus.joining:
                  return _JoiningView();
                case JoinRoomStatus.lobby:
                  return _LobbyView(room: state.joinedRoom!);
                case JoinRoomStatus.error:
                  return Padding(
                    padding: const EdgeInsets.all(WarSpacing.md),
                    child: ErrorIndicatorWidget(
                      message: state.errorMessage ?? context.l10n.errorGeneric,
                    ),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WarSpacing.lg),
        child: WarElevatedButton(
          onPressed: () => context.read<JoinRoomCubit>().startDiscovery(),
          label: 'Discover Rooms',
        ),
      ),
    );
  }
}

class _DiscoveringView extends StatelessWidget {
  const _DiscoveringView({
    required TextEditingController playerNameController,
    required List<RoomDescriptor> rooms,
  }) : _playerNameController = playerNameController,
       _rooms = rooms;

  final TextEditingController _playerNameController;
  final List<RoomDescriptor> _rooms;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: WarSpacing.md),
        const LoadingIndicatorWidget(),
        const SizedBox(height: WarSpacing.sm),
        Text(context.l10n.discoveringRooms, style: WarTextStyles.body),
        const SizedBox(height: WarSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WarSpacing.md),
          child: WarTextField(
            label: context.l10n.playerName,
            controller: _playerNameController,
          ),
        ),
        const SizedBox(height: WarSpacing.sm),
        Expanded(
          child: _rooms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(WarSpacing.lg),
                    child: Text(context.l10n.noRoomsFound),
                  ),
                )
              : ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return WarCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(room.name, style: WarTextStyles.title),
                                const SizedBox(height: WarSpacing.xs),
                                Text(
                                  'Host: ${room.host}',
                                  style: WarTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                          WarElevatedButton(
                            onPressed: () {
                              final playerName = _playerNameController.text
                                  .trim();
                              if (playerName.isEmpty) return;
                              context.read<JoinRoomCubit>().joinRoom(
                                descriptor: room,
                                playerName: playerName,
                              );
                            },
                            label: context.l10n.joinRoom,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _JoiningView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingIndicatorWidget(),
          const SizedBox(height: WarSpacing.md),
          Text(context.l10n.joiningRoom, style: WarTextStyles.body),
        ],
      ),
    );
  }
}

class _LobbyView extends StatelessWidget {
  const _LobbyView({required Room room}) : _room = room;

  final Room _room;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: WarSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WarSpacing.md),
          child: Text(
            context.l10n.waitingForHost,
            style: WarTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: WarSpacing.md),
        Expanded(
          child: ListView.builder(
            itemCount: _room.players.length,
            itemBuilder: (context, index) {
              final player = _room.players[index];
              return WarCard(
                child: Row(
                  children: [
                    PlayerAvatar(playerName: player.name, color: player.color),
                    const SizedBox(width: WarSpacing.md),
                    Text(player.name, style: WarTextStyles.body),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(WarSpacing.md),
          child: WarOutlinedButton(
            onPressed: () {
              context.read<JoinRoomCubit>().leaveRoom();
              Navigator.pop(context);
            },
            label: context.l10n.leaveRoom,
          ),
        ),
      ],
    );
  }
}
