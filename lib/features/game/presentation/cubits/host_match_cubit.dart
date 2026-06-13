import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/features/game/domain/models/match_state.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository.dart';
import 'package:war_armies_app/features/game/presentation/cubits/host_match_state.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';

/// Cubit for the **host** device during a match.
///
/// The host owns the authoritative match state. It initializes the match,
/// applies territory changes locally, and broadcasts diffs to all guests.
class HostMatchCubit extends Cubit<HostMatchState> {
  HostMatchCubit({required MatchRepository matchRepository})
    : _matchRepository = matchRepository,
      super(const HostMatchState());

  final MatchRepository _matchRepository;

  StreamSubscription<MatchState>? _matchSubscription;

  /// Initializes a new match from the given [room].
  ///
  /// Each player starts with 0 territories. The host immediately broadcasts
  /// a `match_snapshot` to all connected guests.
  Future<void> initializeMatch(Room room) async {
    emit(state.copyWith(status: HostMatchStatus.starting));

    try {
      final matchState = _matchRepository.initializeMatch(room);

      _matchSubscription = _matchRepository.watchMatch().listen((updated) {
        emit(state.copyWith(matchState: updated));
      });

      emit(
        state.copyWith(status: HostMatchStatus.active, matchState: matchState),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HostMatchStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Increments the territory count for [playerId] by 1.
  ///
  /// The host applies this locally and broadcasts a `match_diff`.
  Future<void> incrementTerritories(String playerId) async {
    await _matchRepository.requestIncrementTerritories(playerId);
  }

  /// Decrements the territory count for [playerId] by 1 (clamped at 0).
  ///
  /// The host applies this locally and broadcasts a `match_diff`.
  Future<void> decrementTerritories(String playerId) async {
    await _matchRepository.requestDecrementTerritories(playerId);
  }

  /// Sets the territory count for [playerId] to [count].
  ///
  /// The host can set any player's count (host privilege).
  Future<void> setTerritories(String playerId, int count) async {
    await _matchRepository.setTerritories(playerId, count);
  }

  @override
  Future<void> close() {
    _matchSubscription?.cancel();
    return super.close();
  }
}
