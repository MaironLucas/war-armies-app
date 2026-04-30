class WireMessage {
  const WireMessage({
    required this.type,
    required this.seq,
    required this.payload,
  });

  final String type;
  final int seq;
  final Map<String, dynamic> payload;
}
