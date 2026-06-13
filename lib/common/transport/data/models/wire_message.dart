import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class WireMessage {
  const WireMessage({
    required this.type,
    required this.seq,
    required this.payload,
  });

  factory WireMessage.fromJson(Map<String, dynamic> json) {
    return WireMessage(
      type: json['type'] as String,
      seq: json['seq'] as int,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }

  factory WireMessage.fromJsonString(String jsonString) {
    return WireMessage.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  final String type;
  final int seq;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
    'type': type,
    'seq': seq,
    'payload': payload,
  };

  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WireMessage &&
          type == other.type &&
          seq == other.seq &&
          _mapEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(type, seq, payload.length);

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
