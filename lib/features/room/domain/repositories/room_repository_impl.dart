import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/domain/models/connection_state.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/common/transport/domain/repositories/game_transport.dart';
import 'package:war_armies_app/features/room/data/data_sources/room_data_source.dart';
import 'package:war_armies_app/features/room/data/exceptions/room_exceptions.dart';
import 'package:war_armies_app/features/room/domain/models/player.dart';
import 'package:war_armies_app/features/room/domain/models/room.dart';
import 'package:war_armies_app/features/room/domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  RoomRepositoryImpl({
    required GameTransport transport,
    RoomDataSource? roomDataSource,
  }) : _transport = transport,
       _roomDataSource = roomDataSource ?? const RoomDataSource();

  final GameTransport _transport;
  final RoomDataSource _roomDataSource;

  Room? _currentRoom;
  StreamSubscription<WireMessage>? _incomingSubscription;
  StreamSubscription<ConnectionState>? _connectionStateSubscription;

  final StreamController<Room> _roomController =
      StreamController<Room>.broadcast();

  // ---------------------------------------------------------------------------
  // Host operations
  // ---------------------------------------------------------------------------

  @override
  Future<Room> hostRoom({
    required String roomName,
    required String hostPlayerName,
  }) async {
    if (_currentRoom != null) {
      throw const RoomException('Already in a room');
    }

    // 1. Start hosting via transport
    final descriptor = await _transport.host(roomName: roomName);

    // 2. Create the host player and room
    final hostPlayer = Player(
      id: _generatePlayerId(),
      name: hostPlayerName,
      color: _defaultHostColor,
    );

    _currentRoom = Room(
      id: descriptor.id,
      name: roomName,
      hostPlayerId: hostPlayer.id,
      players: [hostPlayer],
      status: RoomStatus.lobby,
    );

    // 3. Listen for incoming messages (join/leave requests from guests)
    _incomingSubscription = _transport.incoming.listen(_handleIncomingMessage);

    // 4. Listen for disconnections
    _connectionStateSubscription = _transport.connectionState.listen(
      _handleConnectionState,
    );

    _roomController.add(_currentRoom!);
    return _currentRoom!;
  }

  // ---------------------------------------------------------------------------
  // Guest operations
  // ---------------------------------------------------------------------------

  @override
  Future<Room> joinRoom({
    required RoomDescriptor descriptor,
    required String playerName,
  }) async {
    if (_currentRoom != null) {
      throw const RoomException('Already in a room');
    }

    // 1. Connect to the host via transport
    await _transport.join(descriptor);

    // 2. Create the guest player
    final guestPlayer = Player(
      id: _generatePlayerId(),
      name: playerName,
      color: _defaultGuestColor,
    );

    // 3. Send a join request to the host
    final joinMessage = _roomDataSource.createJoinRequestMessage(
      playerId: guestPlayer.id,
      playerName: guestPlayer.name,
      colorValue: guestPlayer.color.toARGB32(),
    );
    await _transport.send(joinMessage);

    // 4. Listen for room state updates from the host
    _incomingSubscription = _transport.incoming.listen(_handleIncomingMessage);
    _connectionStateSubscription = _transport.connectionState.listen(
      _handleConnectionState,
    );

    // 5. Wait for the first room_state message to arrive
    // The guest's room will be populated when the host sends a room_state
    // update. We return a placeholder room for now; the real state arrives
    // via watchRoom().
    _currentRoom = Room(
      id: descriptor.id,
      name: descriptor.name,
      hostPlayerId: '',
      players: [guestPlayer],
      status: RoomStatus.lobby,
    );

    _roomController.add(_currentRoom!);
    return _currentRoom!;
  }

  @override
  Stream<List<RoomDescriptor>> discoverRooms() {
    return _transport.discover();
  }

  @override
  Stream<Room> watchRoom() => _roomController.stream;

  @override
  Future<void> leaveRoom() async {
    if (_currentRoom == null) return;

    // Send leave request if we're a guest
    if (_currentRoom!.hostPlayerId != _localPlayerId) {
      final leaveMessage = _roomDataSource.createLeaveRequestMessage(
        playerId: _localPlayerId!,
      );
      try {
        await _transport.send(leaveMessage);
      } catch (_) {
        // Best effort — we're leaving anyway
      }
    }

    await _cleanup();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  String? _localPlayerId;

  void _handleIncomingMessage(WireMessage message) {
    if (_roomDataSource.isRoomState(message)) {
      final room = _roomDataSource.tryParseRoomState(message);
      if (room != null) {
        _currentRoom = room;
        _localPlayerId ??= _findLocalPlayerId(room);
        _roomController.add(room);
      }
    } else if (_roomDataSource.isJoinRequest(message)) {
      // Host receives join requests
      if (_currentRoom == null) return;
      final joinData = _roomDataSource.tryParseJoinRequest(message);
      if (joinData == null) return;

      final newPlayer = Player(
        id: joinData.playerId,
        name: joinData.playerName,
        color: Color(joinData.colorValue),
      );

      _currentRoom = Room(
        id: _currentRoom!.id,
        name: _currentRoom!.name,
        hostPlayerId: _currentRoom!.hostPlayerId,
        players: [..._currentRoom!.players, newPlayer],
        status: _currentRoom!.status,
      );

      _roomController.add(_currentRoom!);
      _broadcastRoomState();
    } else if (_roomDataSource.isLeaveRequest(message)) {
      // Host receives leave requests
      if (_currentRoom == null) return;
      final playerId = _roomDataSource.tryParseLeaveRequestPlayerId(message);
      if (playerId == null) return;

      _currentRoom = Room(
        id: _currentRoom!.id,
        name: _currentRoom!.name,
        hostPlayerId: _currentRoom!.hostPlayerId,
        players: _currentRoom!.players.where((p) => p.id != playerId).toList(),
        status: _currentRoom!.status,
      );

      _roomController.add(_currentRoom!);
      _broadcastRoomState();
    }
  }

  void _handleConnectionState(ConnectionState state) {
    if (state == ConnectionState.disconnected) {
      _cleanup();
    }
  }

  void _broadcastRoomState() {
    if (_currentRoom == null) return;
    final message = _roomDataSource.createRoomStateMessage(
      _currentRoom!,
      _nextSeq(),
    );
    _transport.send(message);
  }

  int _seq = 0;
  int _nextSeq() => _seq++;

  Future<void> _cleanup() async {
    await _incomingSubscription?.cancel();
    _incomingSubscription = null;
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _currentRoom = null;
    _localPlayerId = null;
    await _transport.close();
  }

  String _generatePlayerId() {
    final id = _randomId;
    _localPlayerId = id;
    return id;
  }

  String get _randomId =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  String? _findLocalPlayerId(Room room) {
    // On the host side, the local player is the host
    // On the guest side, we track it via _localPlayerId set during join
    return _localPlayerId;
  }

  static const Color _defaultHostColor = Color(0xFF4CAF50);
  static const Color _defaultGuestColor = Color(0xFF2196F3);
}
