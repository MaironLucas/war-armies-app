import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:war_armies_app/common/routing/app_router.dart';
import 'package:war_armies_app/common/transport/data/data_sources/lan_client_data_source.dart';
import 'package:war_armies_app/common/transport/data/data_sources/lan_host_data_source.dart';
import 'package:war_armies_app/common/transport/data/repositories/game_transport_impl.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository.dart';
import 'package:war_armies_app/features/game/domain/repositories/match_repository_impl.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository_impl.dart';
import 'package:war_armies_app/l10n/l10n.dart';
import 'package:war_armies_app/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  static const _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GameTransportImpl>(
          create: (_) => GameTransportImpl(
            hostDataSource: LanHostDataSource(),
            clientDataSource: LanClientDataSource(),
          ),
        ),
        RepositoryProvider<RoomRepository>(
          create: (context) =>
              RoomRepositoryImpl(transport: context.read<GameTransportImpl>()),
        ),
        RepositoryProvider<MatchRepository>(
          create: (context) =>
              MatchRepositoryImpl(transport: context.read<GameTransportImpl>()),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: WarTheme.light,
        darkTheme: WarTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: _appRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
      ),
    );
  }
}
