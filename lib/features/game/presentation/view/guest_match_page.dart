import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/common/transport/data/repositories/game_transport_impl.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository_impl.dart';
import 'package:war_armies_app/features/game/presentation/presentation.dart';
import 'package:war_armies_app/features/shared/shared.dart';
import 'package:war_armies_app/l10n/l10n.dart';
import 'package:war_armies_app/theme/theme.dart';

class GuestMatchPage extends StatefulWidget {
  const GuestMatchPage({super.key});

  @override
  State<GuestMatchPage> createState() => _GuestMatchPageState();
}

class _GuestMatchPageState extends State<GuestMatchPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<GuestMatchCubit>(
      create: (context) {
        final localPlayerId =
            ModalRoute.of(context)!.settings.arguments! as String;
        final cubit = GuestMatchCubit(
          matchRepository: MatchRepositoryImpl(transport: GameTransportImpl()),
          localPlayerId: localPlayerId,
        )..startListening();
        return cubit;
      },
      child: Scaffold(
        appBar: WarAppBar(title: context.l10n.territories),
        body: BlocBuilder<GuestMatchCubit, GuestMatchState>(
          builder: (context, state) {
            switch (state.status) {
              case GuestMatchStatus.initial:
              case GuestMatchStatus.loading:
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoadingIndicatorWidget(),
                      const SizedBox(height: WarSpacing.md),
                      Text(
                        context.l10n.waitingForHost,
                        style: WarTextStyles.body,
                      ),
                    ],
                  ),
                );
              case GuestMatchStatus.active:
                final matchState = state.matchState!;
                final localPlayerId = state.localPlayerId!;
                final players = matchState.room.players;
                final territories = matchState.territoriesByPlayer;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(WarSpacing.md),
                        child: Wrap(
                          spacing: WarSpacing.md,
                          runSpacing: WarSpacing.md,
                          alignment: WrapAlignment.center,
                          children: players.map((player) {
                            final count = territories[player.id]?.count ?? 0;
                            final isLocalPlayer = player.id == localPlayerId;

                            return GuestPlayerCard(
                              playerName: player.name,
                              playerColor: player.color,
                              territoryCount: count,
                              showControls: isLocalPlayer,
                              onIncrement: isLocalPlayer
                                  ? () => context
                                        .read<GuestMatchCubit>()
                                        .incrementTerritories()
                                  : null,
                              onDecrement: isLocalPlayer
                                  ? () => context
                                        .read<GuestMatchCubit>()
                                        .decrementTerritories()
                                  : null,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(WarSpacing.md),
                      child: WarOutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        label: context.l10n.leaveMatch,
                        icon: Icons.exit_to_app,
                      ),
                    ),
                  ],
                );
              case GuestMatchStatus.error:
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
    );
  }
}

class GuestPlayerCard extends StatelessWidget {
  const GuestPlayerCard({
    required this.playerName,
    required this.playerColor,
    required this.territoryCount,
    this.showControls = false,
    this.onIncrement,
    this.onDecrement,
    super.key,
  });

  final String playerName;
  final Color playerColor;
  final int territoryCount;
  final bool showControls;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: WarCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(
              playerName: playerName,
              color: playerColor,
              radius: 28,
            ),
            const SizedBox(height: WarSpacing.sm),
            Text(
              playerName,
              style: WarTextStyles.body,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: WarSpacing.xs),
            Text(
              '${context.l10n.territories}: $territoryCount',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: WarSpacing.sm),
            if (showControls)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onDecrement != null)
                    IconButton(
                      onPressed: onDecrement,
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Decrement',
                      iconSize: 28,
                    ),
                  const SizedBox(width: WarSpacing.md),
                  if (onIncrement != null)
                    IconButton(
                      onPressed: onIncrement,
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Increment',
                      iconSize: 28,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
