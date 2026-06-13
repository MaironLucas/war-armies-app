import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/common/routing/app_router.dart';
import 'package:war_armies_app/common/transport/transport.dart';
import 'package:war_armies_app/features/room/domain/domain.dart';
import 'package:war_armies_app/features/room/presentation/presentation.dart';
import 'package:war_armies_app/features/shared/shared.dart';
import 'package:war_armies_app/l10n/l10n.dart';
import 'package:war_armies_app/theme/theme.dart';

class HostRoomPage extends StatelessWidget {
  const HostRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HostRoomCubit(
        roomRepository: RoomRepositoryImpl(transport: GameTransportImpl()),
      ),
      child: const _HostRoomBody(),
    );
  }
}

class _HostRoomBody extends StatefulWidget {
  const _HostRoomBody();

  @override
  State<_HostRoomBody> createState() => _HostRoomBodyState();
}

class _HostRoomBodyState extends State<_HostRoomBody> {
  final _roomNameController = TextEditingController();
  final _playerNameController = TextEditingController();

  @override
  void dispose() {
    _roomNameController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HostRoomCubit, HostRoomState>(
      listener: (context, state) {
        if (state.room?.status == RoomStatus.active) {
          Navigator.pushNamed(context, AppRouter.hostMatch);
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case HostRoomStatus.initial:
            return _buildInitial(context);
          case HostRoomStatus.hosting:
            return _buildHosting(context);
          case HostRoomStatus.lobby:
            return _buildLobby(context, state);
          case HostRoomStatus.error:
            return _buildError(context, state);
        }
      },
    );
  }

  Widget _buildInitial(BuildContext context) {
    return Scaffold(
      appBar: WarAppBar(title: context.l10n.hostGame),
      body: Padding(
        padding: const EdgeInsets.all(WarSpacing.md),
        child: Column(
          children: [
            WarTextField(
              label: context.l10n.roomName,
              controller: _roomNameController,
            ),
            const SizedBox(height: WarSpacing.md),
            WarTextField(
              label: context.l10n.playerName,
              controller: _playerNameController,
            ),
            const SizedBox(height: WarSpacing.lg),
            WarElevatedButton(
              label: context.l10n.createRoom,
              icon: Icons.add,
              onPressed: () {
                context.read<HostRoomCubit>().hostRoom(
                  roomName: _roomNameController.text,
                  hostPlayerName: _playerNameController.text,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHosting(BuildContext context) {
    return Scaffold(
      appBar: WarAppBar(title: context.l10n.hostGame, showBackButton: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingIndicatorWidget(),
            const SizedBox(height: WarSpacing.md),
            Text(context.l10n.hostingRoom),
          ],
        ),
      ),
    );
  }

  Widget _buildLobby(BuildContext context, HostRoomState state) {
    final room = state.room!;

    return Scaffold(
      appBar: WarAppBar(title: room.name, showBackButton: false),
      body: Padding(
        padding: const EdgeInsets.all(WarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.players, style: WarTextStyles.title),
            const SizedBox(height: WarSpacing.sm),
            Expanded(
              child: ListView(
                children: room.players
                    .map(
                      (player) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: WarSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            PlayerAvatar(
                              playerName: player.name,
                              color: player.color,
                            ),
                            const SizedBox(width: WarSpacing.md),
                            Text(player.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: WarSpacing.md),
            WarElevatedButton(
              label: context.l10n.startMatch,
              icon: Icons.play_arrow,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.hostMatch),
            ),
            const SizedBox(height: WarSpacing.sm),
            WarOutlinedButton(
              label: context.l10n.killRoom,
              icon: Icons.dangerous,
              onPressed: () {
                context.read<HostRoomCubit>().leaveRoom();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, HostRoomState state) {
    return Scaffold(
      appBar: WarAppBar(title: context.l10n.hostGame),
      body: ErrorIndicatorWidget(
        message: state.errorMessage ?? context.l10n.errorGeneric,
      ),
    );
  }
}
