import 'dart:async';

import 'package:war_armies_app/common/transport/data/data_sources/lan_client_data_source.dart';
import 'package:war_armies_app/common/transport/data/data_sources/lan_host_data_source.dart';
import 'package:war_armies_app/common/transport/data/exceptions/transport_exception.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/domain/models/connection_state.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:war_armies_app/common/transport/domain/repositories/game_transport.dart';

/// Concrete [GameTransport] that delegates to either [LanHostDataSource] or
/// [LanClientDataSource] depending on the device's role.
///
/// A single device is either a **host** or a **guest** — never both.
/// Calling [host] puts this instance in host mode; calling [join] puts it
/// in guest mode. Attempting to use host methods in guest mode (or vice
/// versa) throws a [TransportException].
class GameTransportImpl implements GameTransport {
  GameTransportImpl({
    LanHostDataSource? hostDataSource,
    LanClientDataSource? clientDataSource,
  }) : _hostDataSource = hostDataSource ?? LanHostDataSource(),
       _clientDataSource = clientDataSource ?? LanClientDataSource();

  final LanHostDataSource _hostDataSource;
  final LanClientDataSource _clientDataSource;

  _TransportRole _role = _TransportRole.idle;

  // ---------------------------------------------------------------------------
  // Stream forwarding
  // ---------------------------------------------------------------------------

  @override
  Stream<ConnectionState> get connectionState {
    if (_role == _TransportRole.host) {
      return _hostDataSource.connectionState;
    }
    if (_role == _TransportRole.guest) {
      return _clientDataSource.connectionState;
    }
    return Stream.value(ConnectionState.idle);
  }

  @override
  Stream<WireMessage> get incoming {
    if (_role == _TransportRole.host) {
      return _hostDataSource.incoming;
    }
    if (_role == _TransportRole.guest) {
      return _clientDataSource.incoming;
    }
    return const Stream.empty();
  }

  // ---------------------------------------------------------------------------
  // Host operations
  // ---------------------------------------------------------------------------

  @override
  Future<RoomDescriptor> host({required String roomName}) async {
    if (_role != _TransportRole.idle) {
      throw TransportException(
        'Cannot host: transport is already in ${_role.name} mode',
      );
    }

    _role = _TransportRole.host;
    final port = await _hostDataSource.start(roomName: roomName);

    return RoomDescriptor(
      id: roomName,
      name: roomName,
      host: _localHost,
      port: port,
    );
  }

  @override
  Future<void> send(WireMessage message) async {
    if (_role == _TransportRole.host) {
      _hostDataSource.broadcast(message);
    } else if (_role == _TransportRole.guest) {
      _clientDataSource.send(message);
    } else {
      throw const TransportException('Cannot send: transport is idle');
    }
  }

  // ---------------------------------------------------------------------------
  // Guest operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> join(RoomDescriptor descriptor) async {
    if (_role != _TransportRole.idle) {
      throw TransportException(
        'Cannot join: transport is already in ${_role.name} mode',
      );
    }

    _role = _TransportRole.guest;
    await _clientDataSource.connect(descriptor);
  }

  @override
  Stream<List<RoomDescriptor>> discover() {
    return _clientDataSource.discoveredRooms;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() async {
    if (_role == _TransportRole.host) {
      await _hostDataSource.stop();
      _hostDataSource.dispose();
    } else if (_role == _TransportRole.guest) {
      await _clientDataSource.disconnect();
      await _clientDataSource.stopDiscovery();
      _clientDataSource.dispose();
    }
    _role = _TransportRole.idle;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Best-effort local host address. On most devices this resolves to the
  /// LAN IP; falls back to localhost.
  String get _localHost => '0.0.0.0';
}

enum _TransportRole { idle, host, guest }
