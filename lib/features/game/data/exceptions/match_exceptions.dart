class MatchException implements Exception {
  const MatchException(this.message);

  final String message;

  @override
  String toString() => 'MatchException: $message';
}
