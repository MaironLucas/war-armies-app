# War Armies — Requirements

> Source-of-truth document for the **War Armies App**. Read this before making product or scope decisions. Anything not specified here is out of scope until added explicitly.

---

## 1. Product goal

A Flutter companion app for the physical board game **War** (the Brazilian *Risk*), used by friends sitting around the same table. It replaces paper troop tracking: one device hosts the match (source of truth) and the other players join over the local Wi-Fi network to view and manipulate troop counts.

The app is **a counter, not a referee**. It does not enforce game rules.

---

## 2. Target users

Friend groups (typically 2–6 people) playing War in person, all on the same Wi-Fi network (home Wi-Fi or one player's hotspot). No accounts. No internet required.

---

## 3. Core user flows

### 3.1 Host flow
1. Open app → tap **Host**.
2. Enter a room name, the host's player name, and color.
3. App opens a WebSocket server on the LAN and advertises the room over mDNS.
4. Host sees a **lobby** with the list of players that join.
5. Host taps **Start match** → app navigates to the match screen.
6. On the match screen, the host sees every player's troop total and can edit any player's value directly (e.g. when a conquest transfers troops between players).

### 3.2 Guest flow
1. Open app → tap **Join**.
2. App browses for nearby rooms via mDNS and shows them in a list.
3. Guest picks a room, enters a player name and color, and connects.
4. Guest waits in the **lobby** until the host starts the match.
5. On the match screen, the guest sees every player's troop total but can only **request** increment/decrement of **their own** troops.

### 3.3 Match flow
- Every device renders the full match state from the host.
- Guest interactions (`+` / `−` on their own troops) are sent as **requests**; the host validates, applies, and **broadcasts** the new state.
- The host can edit anyone's troops directly without going through the request protocol.
- Either side can leave the match at any time. If the host leaves, the match ends for everyone.

---

## 4. Non-goals (v1)

- ❌ No cloud sync, online play, or accounts.
- ❌ No persistent history of past matches — state lives only while a match is active.
- ❌ No automatic enforcement of War rules (turns, dice, conquests, objectives).
- ❌ No Bluetooth fallback. If there's no Wi-Fi, the app does not work in v1.
- ❌ No spectator mode, no chat, no reactions.
- ❌ No per-territory tracking (see §6 for the v1 troop model).

---

## 5. Tech stack & architectural decisions

| Concern | Choice | Notes |
|---|---|---|
| Framework | **Flutter** (stable channel) | |
| Language | Dart 3 | |
| Architecture | **Clean Architecture**, feature-first | `data` / `domain` / `presentation` per feature. See `lib/` tree. |
| State management | **`flutter_bloc` Cubit** | One state class per cubit, in its own file. |
| DI | **`MultiRepositoryProvider` at the App widget** | No separate DI library. |
| Transport (host) | **`shelf` + `shelf_web_socket`** | WebSocket server on local interface. |
| Transport (guest) | **`web_socket_channel`** | WebSocket client. |
| Discovery | **`nsd`** (mDNS) | Service type `_war._tcp`. |
| Wire format | **JSON envelopes** | `{ type, seq, payload }` |
| Linting | **`very_good_analysis`** | `public_member_api_docs` disabled. |

The transport (WebSocket + mDNS) is shared infrastructure used by both `room` and `game` features. It lives at `lib/common/transport/` and is exposed through the `GameTransport` interface so that feature repositories depend on the abstraction, not the implementation.

---

## 6. Domain model (v1)

```dart
class Player {
  final String id;
  final String name;
  final Color color;
}

enum RoomStatus { lobby, active, ended }

class Room {
  final String id;
  final String name;
  final String hostPlayerId;
  final List<Player> players;
  final RoomStatus status;
}

// v1: one total per player. Per-territory tracking is deferred.
class PlayerTroops {
  final String playerId;
  final int total;
}

class MatchState {
  final Room room;
  final Map<String, PlayerTroops> troopsByPlayer;
  final int version; // monotonic, incremented by the host on every change
}
```

---

## 7. Networking protocol (v1)

All messages are JSON, framed by a `type` discriminator and a monotonic `seq` set by the host on outbound broadcasts.

### Host → all guests
| `type` | Purpose |
|---|---|
| `room_state` | Lobby snapshot (players joined / left). |
| `match_snapshot` | Full `MatchState`. Sent on join, on resume, and on demand. |
| `match_diff` | Single field change (e.g. `troopsByPlayer[id].total`). |
| `error` | Server-side rejection of a request, with reason. |

### Guest → host
| `type` | Purpose |
|---|---|
| `join_request` | Request to join a room with a player profile. |
| `leave_request` | Voluntary disconnect. |
| `increment_request` | Increment own troops by 1. |
| `decrement_request` | Decrement own troops by 1. |
| `set_troops_request` | Set absolute value (rejected unless the host has explicitly authorized this guest, or the request targets a player the host owns — this only applies to the host's own client). |

### Reliability
- The host is authoritative. Clients never apply local mutations optimistically.
- Each broadcast includes `seq`. If a client detects a gap, it requests a fresh `match_snapshot`.
- The host validates the **sender identity** on every request (no impersonation: a guest can only mutate their own player).

---

## 8. UX requirements

- Works **fully offline** (only the LAN is required — no internet).
- Survives short app backgrounding (~30s) — auto-reconnect on resume.
- Min OS: **Android 8.0+**, **iOS 14+**.
- Light **and** dark themes.
- Languages: **`en`** and **`pt-BR`**.

---

## 9. Out-of-scope / future ideas

- Cloud rooms via Firebase, with a 4-character join code, for remote play.
- Per-territory troop tracking with the War map UI.
- Dice roll helper for attacks.
- Match history and statistics.
- BLE fallback for tables with no Wi-Fi available.
- Spectator mode.
- Objective-card distribution.

---

## 10. Glossary

| Term | Meaning |
|---|---|
| **Host** | The device that owns the match state and broadcasts changes. |
| **Guest** | A device that connects to the host and renders state. |
| **Room** | A named match session, identified by an mDNS-advertised service. |
| **Lobby** | The pre-match state where players join the room. |
| **Match** | An active round of play with troops in motion. |
| **Troops** | The unit count owned by a single player (v1: one number per player). |
| **Territory** | A region on the physical War board. **Not modeled in v1.** |
