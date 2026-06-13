import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository.dart';
import 'package:war_armies_app/features/game/presentation/cubits/guest_match_state.dart';

/// Cubit for the **guest** device during a match.
///
/// The guest does not own the match state — it receives `match_snapshot`
/// and `match_diff` updates from the host. It can only request territory
/// changes for its own player.
class GuestMatchCubit extends Cubit<GuestMatchState> {
  GuestMatchCubit({
    required MatchRepository matchRepository,
    required String localPlayerId,
  }) : _matchRepository = matchRepository,
       _localPlayerId = localPlayerId,
       super(GuestMatchState(localPlayerId: localPlayerId));

  final MatchRepository _matchRepository;
  final String _localPlayerId;

  StreamSubscription<MatchState>? _matchSubscription;

  /// Starts listening for match updates from the host.
  ///
  /// The guest transitions to `active` once the first `match_snapshot`
  /// arrives via `watchMatch()`.
  void startListening() {
    emit(state.copyWith(status: GuestMatchStatus.loading));

    _matchSubscription = _matchRepository.watchMatch().listen((matchState) {
      emit(
        state.copyWith(status: GuestMatchStatus.active, matchState: matchState),
      );
    });
  }

  /// Requests the host to increment this guest's territory count by 1.
  Future<void> incrementTerritories() async {
    await _matchRepository.requestIncrementTerritories(_localPlayerId);
  }

  /// Requests the host to decrement this guest's territory count by 1.
  Future<void> decrementTerritories() async {
    await _matchRepository.requestDecrementTerritories(_localPlayerId);
  }

  /// Requests the host to set this guest's territory count to [count].
  Future<void> setTerritories(int count) async {
    await _matchRepository.setTerritories(_localPlayerId, count);
  }

  @override
  Future<void> close() {
    _matchSubscription?.cancel();
    return super.close();
  }
}
