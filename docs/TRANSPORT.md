# Transport & Wire Protocol

Source-of-truth document for the networking layer. Read this before modifying any transport code.

---

## Network Topology

```
┌──────────────┐         ┌──────────────┐
│  Host Device │◄──────►│ Guest Device │
│              │  WiFi   │              │
│  WebSocket   │  / LAN  │  WebSocket   │
│  Server       │         │  Client      │
│  (shelf)      │         │  (ws_channel)│
│              │         │              │
│  mDNS         │         │  mDNS        │
│  Advertiser  │         │  Discoverer  │
│  (nsd)       │         │  (nsd)       │
└──────────────┘         └──────────────┘
        ▲
        │ WebSocket
        ▼
┌──────────────┐
│ Guest Device │
│ (up to N)   │
└──────────────┘
```

- **One host, many guests** — the host runs a WebSocket server and advertises via mDNS
- **Guests discover** the host via mDNS (`_war._tcp`), then connect via WebSocket
- **Host is authority** — all territory changes are applied on the host and broadcast to guests
- **Guests request** changes — they send increment/decrement/set requests; the host applies and broadcasts diffs

---

## Transport Stack

| Layer | Package | Role |
|---|---|---|
| mDNS discovery | `nsd ^5.0.1` | Host advertises `_war._tcp`, guests discover |
| WebSocket server | `shelf` + `shelf_web_socket` | Host listens for guest connections |
| WebSocket client | `web_socket_channel ^3.0.1` | Guests connect to host |
| Wire format | JSON | `{ "type": "...", "seq": N, "payload": {...} }` |

---

## Wire Message Format

Every message on the wire is a JSON envelope:

```json
{
  "type": "room_state",
  "seq": 42,
  "payload": { ... }
}
```

| Field | Type | Purpose |
|---|---|---|
| `type` | `String` | Message type (see below) |
| `seq` | `int` | Monotonic sequence number for ordering |
| `payload` | `Map<String, dynamic>` | Type-specific data |

### Message Types

#### Host → All Guests

| `type` | Purpose | Payload |
|---|---|---|
| `room_state` | Full lobby snapshot | Serialized `Room` (id, name, hostPlayerId, players, status) |
| `match_snapshot` | Full match state | Serialized `MatchState` (room, territoriesByPlayer, version) |
| `match_diff` | Single territory change | `{ "playerId": "...", "count": N, "version": M }` |
| `error` | Rejection with reason | `{ "reason": "..." }` |

#### Guest → Host

| `type` | Purpose | Payload |
|---|---|---|
| `join_request` | Request to join room | `{ "playerId": "...", "playerName": "...", "colorValue": N }` |
| `leave_request` | Voluntary disconnect | `{ "playerId": "..." }` |
| `increment_territories_request` | +1 territory | `{ "playerId": "..." }` |
| `decrement_territories_request` | −1 territory (clamped at 0) | `{ "playerId": "..." }` |
| `set_territories_request` | Set absolute count | `{ "playerId": "...", "count": N }` |

All type strings are defined as constants in `WireMessageType` to prevent typos.

---

## Data Source Responsibilities

### LanHostDataSource

- Starts a `shelf` WebSocket server on a given port (default: OS-assigned)
- Registers an mDNS service `_war._tcp` via `nsd.register()`
- Manages a list of connected `WebSocketChannel` clients
- `broadcast(WireMessage)` sends to all clients
- `sendTo(WebSocketChannel, WireMessage)` sends to one client
- `incoming` stream exposes messages received from any guest
- `connectionState` stream: `idle → advertising → connected → idle`

### LanClientDataSource

- Discovers rooms via `nsd.startDiscovery('_war._tcp')`
- `discoveredRooms` stream emits `List<RoomDescriptor>` on changes
- Connects to a host via `WebSocketChannel.connect()`
- `send(WireMessage)` transmits to host
- `incoming` stream receives from host
- `connectionState` stream: `idle → discovering → connecting → connected → disconnected`

### GameTransportImpl

- Implements `GameTransport` interface
- **Role-based switching**: `host()` → delegates to `LanHostDataSource`, `join()` → delegates to `LanClientDataSource`
- Single device is either host or guest — never both
- `send()` routes to `broadcast()` (host) or `send()` (guest)
- Throws `TransportException` on role violations (e.g., calling `send()` when idle)

---

## Repository Responsibilities

### RoomRepositoryImpl

- **Host path**: `hostRoom()` → calls `transport.host()`, creates host `Player`, builds `Room(lobby)`, listens for `join_request`/`leave_request`, broadcasts `room_state` on changes
- **Guest path**: `joinRoom()` → calls `transport.join()`, creates guest `Player`, sends `join_request`, listens for `room_state` updates
- `discoverRooms()` → delegates to `transport.discover()`
- `watchRoom()` → broadcasts `Room` changes via `StreamController`
- `leaveRoom()` → sends `leave_request` if guest, calls `transport.close()`

### MatchRepositoryImpl

- **Host path**: `initializeMatch(Room)` → creates `MatchState` with 0 territories per player, starts listening, broadcasts `match_snapshot`
- **Host incoming**: `increment_territories_request` → +1, `decrement_territories_request` → −1 (clamped at 0), `set_territories_request` → absolute value (clamped at 0); each broadcasts `match_diff`
- **Guest path**: `requestIncrementTerritories` / `requestDecrementTerritories` / `setTerritories` → sends corresponding wire message
- **Guest incoming**: `match_snapshot` → replaces state entirely, `match_diff` → applies single-field update with version tracking
- `watchMatch()` → broadcasts `MatchState` changes via `StreamController`

---

## Error Handling

| Exception | When |
|---|---|
| `TransportException` | Role violations, server already running, not connected |
| `RoomException` | Already in a room, room not found |
| `MatchException` | Match not initialized, invalid state |

All exceptions carry a `message` field and override `toString()` for logging.

---

## Reliability Notes

- **No reconnection logic** (v1) — if the host disconnects, the match ends
- **No message ordering guarantees** — `seq` is available for future ordering but not enforced
- **Malformed messages are silently ignored** — data sources catch JSON parse errors and skip
- **Territory counts are clamped at 0** — decrement never goes negative
- **Host authority** — guests cannot directly modify match state; they can only request changes