import 'dart:async';

import 'package:nsd/nsd.dart' as nsd;
import 'package:war_armies_app/common/transport/data/exceptions/transport_exception.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/domain/models/connection_state.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Low-level data source that discovers rooms via mDNS (nsd) and connects
/// to a host's WebSocket server.
///
/// The guest device calls [startDiscovery] to find rooms on the local
/// network, then [connect] to join a specific room. Messages are sent
/// via [send] and received via [incoming].
class LanClientDataSource {
  LanClientDataSource();

  nsd.Discovery? _discovery;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final StreamController<WireMessage> _incomingController =
      StreamController.broadcast();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController.broadcast();
  final StreamController<List<RoomDescriptor>> _discoveryController =
      StreamController.broadcast();

  // ---------------------------------------------------------------------------
  // Public API — Discovery
  // ---------------------------------------------------------------------------

  /// Starts mDNS discovery for War game rooms on the local network.
  ///
  /// Discovered rooms are emitted through [discoveredRooms].
  Future<void> startDiscovery() async {
    if (_discovery != null) {
      throw const TransportException('Discovery is already running');
    }

    _connectionStateController.add(ConnectionState.discovering);
    _discovery = await nsd.startDiscovery('_war._tcp');

    void emitCurrentServices() {
      final descriptors = _discovery!.services
          .where((s) => s.name != null && s.host != null && s.port != null)
          .map(
            (s) => RoomDescriptor(
              id: s.name!,
              name: s.name!,
              host: s.host!,
              port: s.port!,
            ),
          )
          .toList();
      _discoveryController.add(descriptors);
    }

    // Emit initial snapshot
    emitCurrentServices();

    // Listen for changes
    _discovery!.addListener(emitCurrentServices);
  }

  /// Stops mDNS discovery.
  Future<void> stopDiscovery() async {
    if (_discovery == null) return;

    final discovery = _discovery!;
    _discovery = null;
    await nsd.stopDiscovery(discovery);
  }

  /// Stream of discovered rooms. Emits a new list whenever the set of
  /// available rooms changes.
  Stream<List<RoomDescriptor>> get discoveredRooms =>
      _discoveryController.stream;

  // ---------------------------------------------------------------------------
  // Public API — Connection
  // ---------------------------------------------------------------------------

  /// Whether the client is currently connected to a host.
  bool get isConnected => _channel != null;

  /// Stream of [WireMessage]s received from the host.
  Stream<WireMessage> get incoming => _incomingController.stream;

  /// Stream of [ConnectionState] changes.
  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Connects to a host's WebSocket server using the [descriptor] obtained
  /// from [discoveredRooms].
  Future<void> connect(RoomDescriptor descriptor) async {
    if (isConnected) {
      throw const TransportException('Already connected');
    }

    _connectionStateController.add(ConnectionState.connecting);

    final uri = Uri.parse('ws://${descriptor.host}:${descriptor.port}');
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;

    _subscription = _channel!.stream.listen(
      (data) {
        try {
          final message = WireMessage.fromJsonString(data as String);
          _incomingController.add(message);
        } catch (_) {
          // Ignore malformed messages
        }
      },
      onDone: () {
        _connectionStateController.add(ConnectionState.disconnected);
        _channel = null;
        _subscription = null;
      },
      onError: (_) {
        _connectionStateController.add(ConnectionState.disconnected);
        _channel = null;
        _subscription = null;
      },
    );

    _connectionStateController.add(ConnectionState.connected);
  }

  /// Disconnects from the host's WebSocket server.
  Future<void> disconnect() async {
    if (!isConnected) return;

    await _subscription?.cancel();
    _subscription = null;
    await _channel!.sink.close();
    _channel = null;

    _connectionStateController.add(ConnectionState.disconnected);
  }

  /// Sends a [WireMessage] to the host.
  void send(WireMessage message) {
    if (!isConnected) {
      throw const TransportException('Not connected');
    }
    _channel!.sink.add(message.toJsonString());
  }

  /// Releases all resources. Call [disconnect] and [stopDiscovery] first.
  void dispose() {
    _incomingController.close();
    _connectionStateController.close();
    _discoveryController.close();
  }
}
