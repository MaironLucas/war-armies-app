# Design Decisions

Source-of-truth document for key architectural and product decisions. Read this before proposing changes to understand why things are the way they are.

---

## Architecture Decisions

### AD-1: Clean Architecture, feature-first

**Decision:** Organize code by feature (`room/`, `game/`) with `data/domain/presentation` layers inside each feature. Shared infrastructure lives in `common/`.

**Rationale:**
- Features can be developed independently
- Domain layer has zero Flutter/package dependencies — testable in pure Dart
- Data layer can be swapped (e.g., replace WebSocket with Bluetooth) without touching domain or presentation
- Feature-first scales better than layer-first as the app grows

**Trade-off:** Some duplication across features (e.g., each feature has its own `data/exceptions/`). Accepted because the exceptions carry feature-specific context.

---

### AD-2: Cubits over BLoCs

**Decision:** Use `flutter_bloc` Cubits instead of full BLoCs.

**Rationale:**
- Our events are simple method calls (`hostRoom()`, `incrementTerritories()`) — no need for complex event objects
- Cubits are easier to test (call method, assert state)
- Less boilerplate — no separate event classes

**Trade-off:** No event queue or event transformation. Accepted because our use case doesn't need debouncing/throttling.

---

### AD-3: Split Host/Guest Cubits for Match

**Decision:** Separate `HostMatchCubit` and `GuestMatchCubit` instead of a single `MatchCubit`.

**Rationale:**
- Host and guest have fundamentally different responsibilities (authority vs observer)
- Host can set any player's territories; guest can only request changes for itself
- Host calls `initializeMatch()`; guest calls `startListening()`
- Different error handling (host sends errors, guest receives them)
- Separation prevents accidental authority violations at compile time

**Trade-off:** Some UI duplication between `HostMatchPage` and `GuestMatchPage`. Accepted because the pages will diverge further (host controls, guest waiting states, etc.).

---

### AD-4: No HomeCubit

**Decision:** The home page has no Cubit — it's pure navigation.

**Rationale:**
- The home page only needs two buttons that navigate to other pages
- No state to manage, no async operations
- Adding a Cubit would be over-engineering

---

### AD-5: GameTransportImpl as role-switching adapter

**Decision:** Single `GameTransportImpl` that switches between host and guest mode based on which method is called first (`host()` or `join()`).

**Rationale:**
- A single device is either host or guest — never both
- The `GameTransport` interface unifies both roles so repositories don't need to know which transport to use
- Role violations throw `TransportException` — caught early, not at runtime

**Trade-off:** The class has two code paths (host/guest). Accepted because the alternative (separate HostTransport/GuestTransport interfaces) would require repositories to know their role, leaking transport details into the domain layer.

---

### AD-6: Kill Room, not Leave Room (Host)

**Decision:** The host's exit action is labeled "Kill Room" instead of "Leave Room".

**Rationale:**
- When the host disconnects, the WebSocket server shuts down and all guests are disconnected
- "Leave" implies the room continues — it doesn't
- "Kill Room" is honest about the consequence: the room ceases to exist
- The confirmation dialog says "This will disconnect all players"

---

### AD-7: Guest waits in JoinRoomPage

**Decision:** The guest stays on `JoinRoomPage` while waiting for the match to start, not on a separate lobby page.

**Rationale:**
- The `JoinRoomCubit` already manages the full flow: discovery → joining → lobby
- Adding a separate lobby page would require passing state between pages
- The page uses state-driven UI transitions — the same page renders differently per `JoinRoomStatus`
- Auto-navigation to `GuestMatchPage` happens when `RoomStatus.active` is detected

---

### AD-8: Wire protocol uses JSON envelopes

**Decision:** All messages follow `{ "type": "...", "seq": N, "payload": {...} }`.

**Rationale:**
- Human-readable for debugging
- Easy to parse on both sides (Dart's `jsonDecode`/`jsonEncode`)
- `seq` enables future ordering guarantees without breaking changes
- `type` string enables easy routing without magic numbers

**Trade-off:** Larger payload size than binary protocols. Accepted because the data volume is tiny (a few messages per second with small payloads).

---

### AD-9: Malformed messages are silently ignored

**Decision:** Data sources catch JSON parse errors and skip malformed messages instead of crashing.

**Rationale:**
- Network data is untrusted — a buggy client shouldn't crash the host
- The `seq` field enables future deduplication/reordering
- Logging is available via the `error` message type for server-side rejections

---

### AD-10: Territory counts clamped at 0

**Decision:** `decrementTerritories` never goes below 0. `setTerritories` with a negative value is clamped to 0.

**Rationale:**
- Territory counts represent physical territories on a board — they can't be negative
- Clamping at the host side (in `MatchRepositoryImpl`) ensures all guests see consistent state
- The host is the authority, so guests can't bypass this

---

### AD-11: Player IDs are generated locally

**Decision:** Each device generates its own player ID using `DateTime.now().millisecondsSinceEpoch` + random number.

**Rationale:**
- No server to assign IDs
- The ID is set when `hostRoom()` or `joinRoom()` is called and stored in the repository
- Simple, no coordination needed
- Not cryptographically unique, but collision probability is negligible for a LAN party game

**Trade-off:** IDs are not globally unique across sessions. Accepted because a game session is short-lived and local.

---

### AD-12: Color serialization uses ARGB32 int

**Decision:** `Player.color` (a `dart:ui Color`) is serialized as `color.toARGB32()` and deserialized with `Color(value)`.

**Rationale:**
- `Color` is a Dart class, not natively JSON-serializable
- ARGB32 is a single integer — compact and lossless
- `Color(value)` constructor accepts the ARGB32 int directly
- Avoids string-based color formats (hex, RGBA) that need parsing

**Trade-off:** Not human-readable in JSON. Accepted because the wire format is machine-to-machine.

---

### AD-13: RoomRepositoryImpl generates default colors

**Decision:** The host gets `Color(0xFF4CAF50)` (green), guests get `Color(0xFF2196F3)` (blue).

**Rationale:**
- Quick MVP — players get automatic colors without a picker
- Green for host (authority) and blue for guests is a common convention
- Future enhancement: let players choose colors in the lobby

**Trade-off:** All guests get the same color. Accepted for v1; color selection is a future feature.

---

### AD-14: No reconnection logic (v1)

**Decision:** If the host disconnects, the match ends. No reconnection or state recovery.

**Rationale:**
- LAN games are typically short sessions
- Reconnection adds significant complexity (state persistence, reconnection handshake, state reconciliation)
- v1 focuses on core gameplay; reconnection can be added later

---

### AD-15: BlocProvider at page level, not app level

**Decision:** Cubits are created in `BlocProvider` at the page level, not provided globally.

**Rationale:**
- Cubits have page-scoped lifecycle — they should be created when the page opens and disposed when it closes
- A `HostRoomCubit` shouldn't exist when the user is on the match page
- Repositories are app-scoped (provided globally) because they manage transport connections that span pages

**Trade-off:** Cubit state is lost on navigation. Accepted because each page re-initializes from the repository's current state.