/// Wire message type constants as defined in the networking protocol.
///
/// Host → all guests:
/// - [WireMessageType.matchSnapshot] — Full match state. Sent on join, on
///   resume, and on demand.
/// - [matchDiff] — Single field change — typically
///   `territoriesByPlayer[id].count`.
/// - [error] — Server-side rejection of a request, with reason.
///
/// Guest → host:
/// - [joinRequest] — Request to join a room with a player profile.
/// - [leaveRequest] — Voluntary disconnect.
/// - [incrementTerritoriesRequest] — Increment own territory count by 1.
/// - [decrementTerritoriesRequest] — Decrement own territory count by 1
///   (clamped at 0).
/// - [setTerritoriesRequest] — Set own absolute territory count.
abstract final class WireMessageType {
  // Host → all guests
  static const String roomState = 'room_state';
  static const String matchSnapshot = 'match_snapshot';
  static const String matchDiff = 'match_diff';
  static const String error = 'error';

  // Guest → host
  static const String joinRequest = 'join_request';
  static const String leaveRequest = 'leave_request';
  static const String incrementTerritoriesRequest =
      'increment_territories_request';
  static const String decrementTerritoriesRequest =
      'decrement_territories_request';
  static const String setTerritoriesRequest = 'set_territories_request';
}
