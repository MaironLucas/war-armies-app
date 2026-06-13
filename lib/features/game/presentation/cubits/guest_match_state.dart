import 'package:equatable/equatable.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';

enum GuestMatchStatus { initial, loading, active, error }

class GuestMatchState extends Equatable {
  const GuestMatchState({
    this.status = GuestMatchStatus.initial,
    this.matchState,
    this.localPlayerId,
    this.errorMessage,
  });

  final GuestMatchStatus status;
  final MatchState? matchState;
  final String? localPlayerId;
  final String? errorMessage;

  GuestMatchState copyWith({
    GuestMatchStatus? status,
    MatchState? matchState,
    String? localPlayerId,
    String? errorMessage,
  }) {
    return GuestMatchState(
      status: status ?? this.status,
      matchState: matchState ?? this.matchState,
      localPlayerId: localPlayerId ?? this.localPlayerId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, matchState, localPlayerId, errorMessage];
}
