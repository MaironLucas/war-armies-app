import 'package:flutter/material.dart';
import 'package:war_armies_app/features/game/presentation/presentation.dart';
import 'package:war_armies_app/features/home/presentation/presentation.dart';
import 'package:war_armies_app/features/room/presentation/presentation.dart';

class AppRouter {
  const AppRouter();

  static const String home = '/';
  static const String hostRoom = '/host-room';
  static const String joinRoom = '/join-room';
  static const String hostMatch = '/host-match';
  static const String guestMatch = '/guest-match';

  Route<void> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        switch (settings.name) {
          case hostRoom:
            return const HostRoomPage();
          case joinRoom:
            return const JoinRoomPage();
          case hostMatch:
            return const HostMatchPage();
          case guestMatch:
            return const GuestMatchPage();
          case home:
          default:
            return const HomePage();
        }
      },
    );
  }
}
