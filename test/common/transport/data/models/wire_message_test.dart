import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:war_armies_app/common/transport/data/models/wire_message.dart';

void main() {
  group('WireMessage', () {
    const type = 'message';
    const seq = 1;
    const payload = <String, dynamic>{'key': 'value', 'count': 42};
    const otherPayload = <String, dynamic>{'key': 'different'};

    const message = WireMessage(type: type, seq: seq, payload: payload);

    group('fromJson', () {
      test('creates a WireMessage from a JSON map', () {
        final json = <String, dynamic>{
          'type': type,
          'seq': seq,
          'payload': payload,
        };

        final result = WireMessage.fromJson(json);

        expect(result.type, equals(type));
        expect(result.seq, equals(seq));
        expect(result.payload, equals(payload));
      });
    });

    group('fromJsonString', () {
      test('creates a WireMessage from a JSON string', () {
        final jsonString = jsonEncode(<String, dynamic>{
          'type': type,
          'seq': seq,
          'payload': payload,
        });

        final result = WireMessage.fromJsonString(jsonString);

        expect(result.type, equals(type));
        expect(result.seq, equals(seq));
        expect(result.payload, equals(payload));
      });
    });

    group('toJson', () {
      test('produces the correct JSON map', () {
        final result = message.toJson();

        expect(result, isA<Map<String, dynamic>>());
        expect(result['type'], equals(type));
        expect(result['seq'], equals(seq));
        expect(result['payload'], equals(payload));
      });
    });

    group('toJsonString', () {
      test('produces a valid JSON string that can be round-tripped', () {
        final jsonString = message.toJsonString();

        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        expect(decoded['type'], equals(type));
        expect(decoded['seq'], equals(seq));
        expect(decoded['payload'], equals(payload));
      });
    });

    group('equality', () {
      test('two WireMessages with same type/seq/payload are equal', () {
        const same = WireMessage(type: type, seq: seq, payload: payload);

        expect(message, equals(same));
        expect(message.hashCode, equals(same.hashCode));
      });

      test('different payloads are not equal', () {
        const different = WireMessage(
          type: type,
          seq: seq,
          payload: otherPayload,
        );

        expect(message, isNot(equals(different)));
      });
    });
  });
}
