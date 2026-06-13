import 'package:equatable/equatable.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';

enum HostMatchStatus { initial, starting, active, error }

class HostMatchState extends Equatable {
  const HostMatchState({
    this.status = HostMatchStatus.initial,
    this.matchState,
    this.errorMessage,
  });

  final HostMatchStatus status;
  final MatchState? matchState;
  final String? errorMessage;

  HostMatchState copyWith({
    HostMatchStatus? status,
    MatchState? matchState,
    String? errorMessage,
  }) {
    return HostMatchState(
      status: status ?? this.status,
      matchState: matchState ?? this.matchState,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, matchState, errorMessage];
}
