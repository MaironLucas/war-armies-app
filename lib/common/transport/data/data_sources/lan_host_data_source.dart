import 'dart:async';
import 'dart:io';

import 'package:nsd/nsd.dart' as nsd;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:war_armies_app/common/transport/data/exceptions/transport_exception.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/domain/models/connection_state.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Low-level data source that manages a WebSocket server and advertises
/// the room via mDNS (nsd).
///
/// The host device calls [start] to spin up a shelf WebSocket server and
/// register an mDNS service. Guests connect to this server; the host
/// broadcasts [WireMessage]s to all connected guests and receives
/// [WireMessage]s from them via [incoming].
class LanHostDataSource {
  LanHostDataSource();

  HttpServer? _server;
  nsd.Registration? _registration;
  final List<WebSocketChannel> _clients = [];
  final StreamController<WireMessage> _incomingController =
      StreamController.broadcast();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController.broadcast();

  int? _port;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether the WebSocket server is currently running.
  bool get isRunning => _server != null;

  /// The port the server is listening on, or `null` if not running.
  int? get port => _port;

  /// Stream of [WireMessage]s received from any connected guest.
  Stream<WireMessage> get incoming => _incomingController.stream;

  /// Stream of [ConnectionState] changes.
  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Starts the WebSocket server and begins advertising via mDNS.
  ///
  /// Returns the actual port the server is listening on (useful when
  /// [port] is 0, which lets the OS pick a free port).
  Future<int> start({required String roomName, int port = 0}) async {
    if (isRunning) {
      throw const TransportException('Server is already running');
    }

    _connectionStateController.add(ConnectionState.advertising);

    // 1. Start WebSocket server
    final handler = webSocketHandler(_handleConnection);
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    _port = _server!.port;

    // 2. Register mDNS service
    _registration = await nsd.register(
      nsd.Service(name: roomName, type: '_war._tcp', port: _port),
    );

    _connectionStateController.add(ConnectionState.connected);
    return _port!;
  }

  /// Stops the WebSocket server, disconnects all guests, and unregisters
  /// the mDNS service.
  Future<void> stop() async {
    if (!isRunning) return;

    // Close all client connections
    for (final client in _clients.toList()) {
      await client.sink.close();
    }
    _clients.clear();

    // Unregister mDNS service
    if (_registration != null) {
      await nsd.unregister(_registration!);
      _registration = null;
    }

    // Stop server
    await _server!.close(force: true);
    _server = null;
    _port = null;

    _connectionStateController.add(ConnectionState.idle);
  }

  /// Broadcasts a [WireMessage] to all connected guests.
  void broadcast(WireMessage message) {
    if (!isRunning) {
      throw const TransportException('Server is not running');
    }
    final json = message.toJsonString();
    for (final client in _clients.toList()) {
      client.sink.add(json);
    }
  }

  /// Sends a [WireMessage] to a specific connected guest.
  void sendTo(WebSocketChannel client, WireMessage message) {
    client.sink.add(message.toJsonString());
  }

  /// Releases all resources. Call [stop] first to gracefully shut down.
  void dispose() {
    _incomingController.close();
    _connectionStateController.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _handleConnection(WebSocketChannel webSocket, _) {
    _clients.add(webSocket);
    webSocket.stream.listen(
      (data) {
        try {
          final message = WireMessage.fromJsonString(data as String);
          _incomingController.add(message);
        } catch (_) {
          // Ignore malformed messages
        }
      },
      onDone: () {
        _clients.remove(webSocket);
      },
      onError: (_) {
        _clients.remove(webSocket);
      },
    );
  }
}
