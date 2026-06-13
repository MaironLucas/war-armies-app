// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'War Armies';

  @override
  String get hostGame => 'Host Game';

  @override
  String get joinGame => 'Join Game';

  @override
  String get roomName => 'Room Name';

  @override
  String get playerName => 'Player Name';

  @override
  String get createRoom => 'Create Room';

  @override
  String get startMatch => 'Start Match';

  @override
  String get killRoom => 'Kill Room';

  @override
  String get killRoomConfirm => 'This will disconnect all players';

  @override
  String get joinRoom => 'Join';

  @override
  String get leaveRoom => 'Leave Room';

  @override
  String get territories => 'Territories';

  @override
  String get endMatch => 'End Match';

  @override
  String get leaveMatch => 'Leave Match';

  @override
  String get discoveringRooms => 'Searching for rooms…';

  @override
  String get hostingRoom => 'Creating room…';

  @override
  String get joiningRoom => 'Joining room…';

  @override
  String get waitingForHost => 'Waiting for host to start match…';

  @override
  String get noRoomsFound => 'No rooms found on the network';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get players => 'Players';

  @override
  String get set => 'Set';
}
