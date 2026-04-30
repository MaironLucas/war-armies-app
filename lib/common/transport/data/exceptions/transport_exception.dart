class TransportException implements Exception {
  const TransportException(this.message);

  final String message;

  @override
  String toString() => 'TransportException: $message';
}
