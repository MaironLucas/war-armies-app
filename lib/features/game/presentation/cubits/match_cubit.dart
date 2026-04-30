import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository.dart';
import 'package:war_armies_app/features/game/presentation/cubits/match_view_state.dart';

class MatchCubit extends Cubit<MatchViewState> {
  MatchCubit({required MatchRepository matchRepository})
      : _matchRepository = matchRepository,
        super(const MatchViewState());

  // ignore: unused_field
  final MatchRepository _matchRepository;
}
