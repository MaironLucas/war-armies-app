class RoomException implements Exception {
  const RoomException(this.message);

  final String message;

  @override
  String toString() => 'RoomException: $message';
}
