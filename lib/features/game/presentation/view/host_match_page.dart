import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/common/transport/data/repositories/game_transport_impl.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository_impl.dart';
import 'package:war_armies_app/features/game/presentation/presentation.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/shared/shared.dart';
import 'package:war_armies_app/l10n/l10n.dart';
import 'package:war_armies_app/theme/theme.dart';

class HostMatchPage extends StatefulWidget {
  const HostMatchPage({super.key});

  @override
  State<HostMatchPage> createState() => _HostMatchPageState();
}

class _HostMatchPageState extends State<HostMatchPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<HostMatchCubit>(
      create: (context) {
        final cubit = HostMatchCubit(
          matchRepository: MatchRepositoryImpl(transport: GameTransportImpl()),
        );
        final room = ModalRoute.of(context)!.settings.arguments! as Room;
        cubit.initializeMatch(room);
        return cubit;
      },
      child: Scaffold(
        appBar: WarAppBar(title: context.l10n.territories),
        body: BlocBuilder<HostMatchCubit, HostMatchState>(
          builder: (context, state) {
            switch (state.status) {
              case HostMatchStatus.initial:
              case HostMatchStatus.starting:
                return const Center(child: LoadingIndicatorWidget());
              case HostMatchStatus.active:
                final matchState = state.matchState!;
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
                            return _PlayerCard(
                              playerName: player.name,
                              playerColor: player.color,
                              territoryCount: count,
                              onIncrement: () => context
                                  .read<HostMatchCubit>()
                                  .incrementTerritories(player.id),
                              onDecrement: () => context
                                  .read<HostMatchCubit>()
                                  .decrementTerritories(player.id),
                              onSet: () => _showSetDialog(
                                context,
                                player.name,
                                count,
                                (value) {
                                  context.read<HostMatchCubit>().setTerritories(
                                    player.id,
                                    value,
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(WarSpacing.md),
                      child: WarOutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        label: context.l10n.endMatch,
                        icon: Icons.exit_to_app,
                      ),
                    ),
                  ],
                );
              case HostMatchStatus.error:
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

  void _showSetDialog(
    BuildContext context,
    String playerName,
    int currentCount,
    void Function(int) onSet,
  ) {
    final controller = TextEditingController(text: currentCount.toString());

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${context.l10n.set} $playerName'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.territories,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null) {
                onSet(value);
                Navigator.pop(dialogContext);
              }
            },
            child: Text(context.l10n.set),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.playerName,
    required this.playerColor,
    required this.territoryCount,
    this.onIncrement,
    this.onDecrement,
    this.onSet,
  });

  final String playerName;
  final Color playerColor;
  final int territoryCount;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onSet;

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
                const SizedBox(width: WarSpacing.xs),
                if (onSet != null)
                  TextButton(onPressed: onSet, child: Text(context.l10n.set)),
                const SizedBox(width: WarSpacing.xs),
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
