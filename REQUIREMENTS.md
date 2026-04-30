# War Armies — Requirements

> Source-of-truth document for the **War Armies App**. Read this before making product or scope decisions. Anything not specified here is out of scope until added explicitly.

---

## 1. Product goal

A Flutter companion app that solves the most painful part of playing **War** (the Brazilian *Risk*) in person: figuring out **how many troops each player will receive at the start of their next turn**.

In War, reinforcements are derived from the number of territories a player controls — `floor(territories / 2)`. Counting territories every turn for every player is tedious. This app does it automatically: each guest adjusts **their own territory count**, and every device immediately shows the resulting troop reinforcement for everyone.

The app is **a counter and a calculator, not a referee**. It does not enforce game rules.

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
6. On the match screen, the host sees every player's territory count and the derived next-turn troops. The host can edit any player's territory count directly (e.g. when a conquest transfers territories between players).

### 3.2 Guest flow
1. Open app → tap **Join**.
2. App browses for nearby rooms via mDNS and shows them in a list.
3. Guest picks a room, enters a player name and color, and connects.
4. Guest waits in the **lobby** until the host starts the match.
5. On the match screen, the guest sees every player's territory count and derived troops, but can only adjust **their own** territory count (`+` / `−`).

### 3.3 Match flow
- Every device renders the full match state from the host.
- Guests adjust their own territory count via `+` / `−`. Each tap is sent as a **request**; the host validates, applies, and **broadcasts** the new state.
- The host can edit any player's territory count without going through the request protocol.
- The **derived troop number** (`territories ~/ 2`) is computed locally on every device — it's not transmitted, only the territory count is.
- Either side can leave the match at any time. If the host leaves, the match ends for everyone.

---

## 4. Non-goals (v1)

- ❌ No cloud sync, online play, or accounts.
- ❌ No persistent history of past matches — state lives only while a match is active.
- ❌ No automatic enforcement of War rules (turns, dice, conquests, objectives, continent bonuses, minimum-3-troops cap).
- ❌ No Bluetooth fallback. If there's no Wi-Fi, the app does not work in v1.
- ❌ No spectator mode, no chat, no reactions.
- ❌ No map UI. The board is the physical board on the table; the app is the counter.

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

class PlayerTerritories {
  final String playerId;
  final int count;

  /// Derived locally — never transmitted. War's reinforcement formula:
  /// `floor(territories / 2)`.
  int get troops => count ~/ 2;
}

class MatchState {
  final Room room;
  final Map<String, PlayerTerritories> territoriesByPlayer;
  final int version; // monotonic, incremented by the host on every change
}
```

**Key invariant:** only the **territory count** is part of network state. The **troops** number is a pure derivation from `count` and is computed on every device when rendering — it never travels over the wire.

---

## 7. Networking protocol (v1)

All messages are JSON, framed by a `type` discriminator and a monotonic `seq` set by the host on outbound broadcasts.

### Host → all guests
| `type` | Purpose |
|---|---|
| `room_state` | Lobby snapshot (players joined / left). |
| `match_snapshot` | Full `MatchState`. Sent on join, on resume, and on demand. |
| `match_diff` | Single field change — typically `territoriesByPlayer[id].count`. |
| `error` | Server-side rejection of a request, with reason. |

### Guest → host
| `type` | Purpose |
|---|---|
| `join_request` | Request to join a room with a player profile. |
| `leave_request` | Voluntary disconnect. |
| `increment_territories_request` | Increment own territory count by 1. |
| `decrement_territories_request` | Decrement own territory count by 1 (clamped at 0). |
| `set_territories_request` | Set own absolute territory count (rare; useful for big corrections). The host can use this for any player. |

### Reliability
- The host is authoritative. Clients never apply local mutations optimistically.
- Each broadcast includes `seq`. If a client detects a gap, it requests a fresh `match_snapshot`.
- The host validates **sender identity** on every request: a guest can only mutate **their own** `playerId`. The host is the only party allowed to mutate other players' territory counts.

---

## 8. UX requirements

- Each player has a card on the match screen showing: **name + color**, **territory count** (with `+` / `−`), and the **derived troop reinforcement** rendered prominently.
- A guest's own card has interactive `+` / `−`; other players' cards are read-only on a guest's device.
- On the host's device, every card has interactive `+` / `−`.
- Works **fully offline** (only the LAN is required — no internet).
- Survives short app backgrounding (~30s) — auto-reconnect on resume.
- Min OS: **Android 8.0+**, **iOS 14+**.
- Light **and** dark themes.
- Languages: **`en`** and **`pt-BR`**.

---

## 9. Out-of-scope / future ideas

- **Continent bonus tracking** — extra reinforcements for fully owning a continent (e.g. South America: +2, North America: +5). Would extend `PlayerTerritories` (or add a sibling model) so the host can mark which continents a player fully controls; the local `troops` derivation would add the bonus on top of `count ~/ 2`.
- **Card trade-ins** — in War, turning in a set of three territory cards grants extra troops on a rising scale (4, 6, 8, 10, 12, 15, then +5 each). Would add a per-match counter for "trade-ins performed so far" and a "trade in three cards" action that bumps the active player's incoming troops for the next turn.
- Cloud rooms via Firebase, with a 4-character join code, for remote play.
- Minimum-3-troops cap (the official rule when `territories < 6`).
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
| **Match** | An active round of play. |
| **Territory** | A region on the physical War board controlled by a player. v1 only tracks the **count** per player, not which specific territories. |
| **Troops / reinforcements** | The number of new units a player will place at the start of their next turn — **derived** from territory count as `floor(territories / 2)`. Not transmitted; computed locally on every device. |
