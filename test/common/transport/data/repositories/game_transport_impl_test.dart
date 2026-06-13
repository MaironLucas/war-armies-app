import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:war_armies_app/common/transport/data/data_sources/lan_client_data_source.dart';
import 'package:war_armies_app/common/transport/data/data_sources/lan_host_data_source.dart';
import 'package:war_armies_app/common/transport/data/exceptions/transport_exception.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';
import 'package:war_armies_app/common/transport/data/repositories/game_transport_impl.dart';
import 'package:war_armies_app/common/transport/domain/models/connection_state.dart';
import 'package:war_armies_app/common/transport/domain/models/room_descriptor.dart';

class _MockLanHostDataSource extends Mock implements LanHostDataSource {}

class _MockLanClientDataSource extends Mock implements LanClientDataSource {}

void main() {
  registerFallbackValue(
    const WireMessage(type: 'test', seq: 1, payload: <String, dynamic>{}),
  );
  registerFallbackValue(
    const RoomDescriptor(id: 'r', name: 'r', host: 'h', port: 8080),
  );
  registerFallbackValue('fallback-room');

  late _MockLanHostDataSource mockHost;
  late _MockLanClientDataSource mockClient;
  late GameTransportImpl gameTransport;

  setUp(() {
    mockHost = _MockLanHostDataSource();
    mockClient = _MockLanClientDataSource();
    gameTransport = GameTransportImpl(
      hostDataSource: mockHost,
      clientDataSource: mockClient,
    );
  });

  group('host()', () {
    test('starts the host data source and returns a RoomDescriptor', () async {
      const roomName = 'test-room';
      const port = 8080;
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => port);

      final descriptor = await gameTransport.host(roomName: roomName);

      expect(descriptor.id, equals(roomName));
      expect(descriptor.name, equals(roomName));
      expect(descriptor.host, equals('0.0.0.0'));
      expect(descriptor.port, equals(port));
      verify(() => mockHost.start(roomName: roomName)).called(1);
    });

    test('throws TransportException when called a second time', () async {
      const roomName = 'test-room';
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => 8080);

      await gameTransport.host(roomName: roomName);

      await expectLater(
        () => gameTransport.host(roomName: roomName),
        throwsA(isA<TransportException>()),
      );
    });

    test('throws TransportException when already joined', () async {
      const roomName = 'test-room';
      const descriptor = RoomDescriptor(
        id: 'room',
        name: 'room',
        host: '192.168.1.1',
        port: 8080,
      );
      when(() => mockClient.connect(any())).thenAnswer((_) async => {});
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => 8080);

      await gameTransport.join(descriptor);

      await expectLater(
        () => gameTransport.host(roomName: roomName),
        throwsA(isA<TransportException>()),
      );
    });

    test('sets role to host so that send delegates to broadcast', () async {
      const roomName = 'test-room';
      const message = WireMessage(
        type: 'test',
        seq: 1,
        payload: <String, dynamic>{},
      );
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => 8080);

      await gameTransport.host(roomName: roomName);
      await gameTransport.send(message);

      verify(() => mockHost.broadcast(message)).called(1);
    });
  });

  group('join()', () {
    test('connects the client data source', () async {
      const descriptor = RoomDescriptor(
        id: 'room',
        name: 'room',
        host: '192.168.1.1',
        port: 8080,
      );
      when(() => mockClient.connect(any())).thenAnswer((_) async => {});

      await gameTransport.join(descriptor);

      verify(() => mockClient.connect(descriptor)).called(1);
    });

    test('throws TransportException when already joined', () async {
      const descriptor = RoomDescriptor(
        id: 'room',
        name: 'room',
        host: '192.168.1.1',
        port: 8080,
      );
      when(() => mockClient.connect(any())).thenAnswer((_) async => {});

      await gameTransport.join(descriptor);

      await expectLater(
        () => gameTransport.join(descriptor),
        throwsA(isA<TransportException>()),
      );
    });

    test('throws TransportException when already hosting', () async {
      const roomName = 'test-room';
      const descriptor = RoomDescriptor(
        id: 'room',
        name: 'room',
        host: '192.168.1.1',
        port: 8080,
      );
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => 8080);
      await gameTransport.host(roomName: roomName);

      await expectLater(
        () => gameTransport.join(descriptor),
        throwsA(isA<TransportException>()),
      );
    });

    test('sets role to guest so that send delegates to client.send', () async {
      const descriptor = RoomDescriptor(
        id: 'room',
        name: 'room',
        host: '192.168.1.1',
        port: 8080,
      );
      const message = WireMessage(
        type: 'test',
        seq: 1,
        payload: <String, dynamic>{},
      );
      when(() => mockClient.connect(any())).thenAnswer((_) async => {});

      await gameTransport.join(descriptor);
      await gameTransport.send(message);

      verify(() => mockClient.send(message)).called(1);
    });
  });

  group('send()', () {
    test('throws TransportException when idle', () async {
      const message = WireMessage(
        type: 'test',
        seq: 1,
        payload: <String, dynamic>{},
      );

      await expectLater(
        () => gameTransport.send(message),
        throwsA(isA<TransportException>()),
      );
    });
  });

  group('close()', () {
    test('in host mode stops and disposes the host data source', () async {
      const roomName = 'test-room';
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => 8080);
      when(() => mockHost.stop()).thenAnswer((_) async => {});
      await gameTransport.host(roomName: roomName);

      await gameTransport.close();

      verify(() => mockHost.stop()).called(1);
      verify(() => mockHost.dispose()).called(1);
    });

    test('in guest mode disconnects, stops discovery, and disposes', () async {
      const descriptor = RoomDescriptor(
        id: 'room',
        name: 'room',
        host: '192.168.1.1',
        port: 8080,
      );
      when(() => mockClient.connect(any())).thenAnswer((_) async => {});
      when(() => mockClient.disconnect()).thenAnswer((_) async => {});
      when(() => mockClient.stopDiscovery()).thenAnswer((_) async => {});
      await gameTransport.join(descriptor);

      await gameTransport.close();

      verify(() => mockClient.disconnect()).called(1);
      verify(() => mockClient.stopDiscovery()).called(1);
      verify(() => mockClient.dispose()).called(1);
    });

    test('resets role to idle so that send throws', () async {
      const roomName = 'test-room';
      const message = WireMessage(
        type: 'test',
        seq: 1,
        payload: <String, dynamic>{},
      );
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => 8080);
      when(() => mockHost.stop()).thenAnswer((_) async => {});
      await gameTransport.host(roomName: roomName);

      await gameTransport.close();

      await expectLater(
        () => gameTransport.send(message),
        throwsA(isA<TransportException>()),
      );
    });
  });

  group('connectionState', () {
    test('returns idle stream when role is idle', () {
      expect(gameTransport.connectionState, emits(ConnectionState.idle));
    });

    test('delegates to host data source when role is host', () async {
      const roomName = 'test-room';
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => 8080);
      when(
        () => mockHost.connectionState,
      ).thenAnswer((_) => Stream.value(ConnectionState.connected));
      await gameTransport.host(roomName: roomName);

      expect(gameTransport.connectionState, emits(ConnectionState.connected));
    });

    test('delegates to client data source when role is guest', () async {
      const descriptor = RoomDescriptor(
        id: 'room',
        name: 'room',
        host: '192.168.1.1',
        port: 8080,
      );
      when(() => mockClient.connect(any())).thenAnswer((_) async => {});
      when(
        () => mockClient.connectionState,
      ).thenAnswer((_) => Stream.value(ConnectionState.connected));
      await gameTransport.join(descriptor);

      expect(gameTransport.connectionState, emits(ConnectionState.connected));
    });
  });

  group('incoming', () {
    test('returns empty stream when role is idle', () {
      expect(gameTransport.incoming, emitsDone);
    });

    test('delegates to host data source when role is host', () async {
      const roomName = 'test-room';
      const message = WireMessage(
        type: 'chat',
        seq: 1,
        payload: <String, dynamic>{},
      );
      when(
        () => mockHost.start(roomName: any(named: 'roomName')),
      ).thenAnswer((_) async => 8080);
      when(
        () => mockHost.incoming,
      ).thenAnswer((_) => Stream<WireMessage>.value(message));
      await gameTransport.host(roomName: roomName);

      expect(gameTransport.incoming, emits(message));
    });

    test('delegates to client data source when role is guest', () async {
      const descriptor = RoomDescriptor(
        id: 'room',
        name: 'room',
        host: '192.168.1.1',
        port: 8080,
      );
      const message = WireMessage(
        type: 'chat',
        seq: 1,
        payload: <String, dynamic>{},
      );
      when(() => mockClient.connect(any())).thenAnswer((_) async => {});
      when(
        () => mockClient.incoming,
      ).thenAnswer((_) => Stream<WireMessage>.value(message));
      await gameTransport.join(descriptor);

      expect(gameTransport.incoming, emits(message));
    });
  });

  group('discover()', () {
    test('returns the discoveredRooms stream from the client', () {
      const rooms = [
        RoomDescriptor(id: 'r1', name: 'r1', host: '10.0.0.1', port: 8080),
      ];
      when(
        () => mockClient.discoveredRooms,
      ).thenAnswer((_) => Stream<List<RoomDescriptor>>.value(rooms));

      final stream = gameTransport.discover();

      expect(stream, emits(rooms));
    });
  });
}
