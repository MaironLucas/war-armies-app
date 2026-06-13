// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'War Armies';

  @override
  String get hostGame => 'Criar Jogo';

  @override
  String get joinGame => 'Entrar no Jogo';

  @override
  String get roomName => 'Nome da Sala';

  @override
  String get playerName => 'Nome do Jogador';

  @override
  String get createRoom => 'Criar Sala';

  @override
  String get startMatch => 'Iniciar Partida';

  @override
  String get killRoom => 'Encerrar Sala';

  @override
  String get killRoomConfirm => 'Isso desconectará todos os jogadores';

  @override
  String get joinRoom => 'Entrar';

  @override
  String get leaveRoom => 'Sair da Sala';

  @override
  String get territories => 'Territórios';

  @override
  String get endMatch => 'Encerrar Partida';

  @override
  String get leaveMatch => 'Sair da Partida';

  @override
  String get discoveringRooms => 'Procurando salas…';

  @override
  String get hostingRoom => 'Criando sala…';

  @override
  String get joiningRoom => 'Entrando na sala…';

  @override
  String get waitingForHost => 'Aguardando o anfitrião iniciar a partida…';

  @override
  String get noRoomsFound => 'Nenhuma sala encontrada na rede';

  @override
  String get errorGeneric => 'Algo deu errado';

  @override
  String get players => 'Jogadores';

  @override
  String get set => 'Definir';
}
