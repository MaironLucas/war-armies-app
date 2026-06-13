# Presentation Layer

Source-of-truth document for the UI layer. Read this before modifying pages or Cubits.

---

## State Management

We use **`flutter_bloc` Cubits** (not full BLoCs) because our events are simple method calls — no complex event objects needed.

### Cubit Overview

| Cubit | State | Role | Authority |
|---|---|---|---|
| `HostRoomCubit` | `HostRoomState` | Host's room lifecycle | Creates room, watches players join/leave |
| `JoinRoomCubit` | `JoinRoomState` | Guest's discovery & joining | Discovers rooms, joins, watches lobby |
| `HostMatchCubit` | `HostMatchState` | Host's match authority | Owns match state, applies changes, broadcasts |
| `GuestMatchCubit` | `GuestMatchState` | Guest's match view | Observes match, sends requests for own player |

**No `HomeCubit`** — the home page is pure navigation with no state.

---

## Cubit Details

### HostRoomCubit

```dart
class HostRoomCubit extends Cubit<HostRoomState> {
  HostRoomCubit({required RoomRepository roomRepository});
}
```

**State:**

| Field | Type | Purpose |
|---|---|---|
| `status` | `HostRoomStatus` | `initial → hosting → lobby → error` |
| `room` | `Room?` | Current room (null until hosted) |
| `errorMessage` | `String?` | Error feedback |

**Methods:**
- `hostRoom(roomName, hostPlayerName)` — calls `roomRepository.hostRoom()`, subscribes to `watchRoom()`
- `leaveRoom()` — cancels subscription, calls `roomRepository.leaveRoom()`, resets to initial

**Subscriptions:**
- `roomRepository.watchRoom()` → emits updated `Room` when players join/leave

---

### JoinRoomCubit

```dart
class JoinRoomCubit extends Cubit<JoinRoomState> {
  JoinRoomCubit({required RoomRepository roomRepository});
}
```

**State:**

| Field | Type | Purpose |
|---|---|---|
| `status` | `JoinRoomStatus` | `initial → discovering → joining → lobby → error` |
| `discoveredRooms` | `List<RoomDescriptor>` | Rooms found via mDNS |
| `joinedRoom` | `Room?` | Room after joining |
| `errorMessage` | `String?` | Error feedback |

**Methods:**
- `startDiscovery()` — subscribes to `roomRepository.discoverRooms()`
- `stopDiscovery()` — cancels discovery subscription
- `joinRoom(descriptor, playerName)` — calls `roomRepository.joinRoom()`, subscribes to `watchRoom()`
- `leaveRoom()` — cancels subscriptions, calls `roomRepository.leaveRoom()`, resets

**Subscriptions:**
- `roomRepository.discoverRooms()` → emits `List<RoomDescriptor>` on changes
- `roomRepository.watchRoom()` → emits updated `Room` when host updates state

---

### HostMatchCubit

```dart
class HostMatchCubit extends Cubit<HostMatchState> {
  HostMatchCubit({required MatchRepository matchRepository});
}
```

**State:**

| Field | Type | Purpose |
|---|---|---|
| `status` | `HostMatchStatus` | `initial → starting → active → error` |
| `matchState` | `MatchState?` | Current match (null until initialized) |
| `errorMessage` | `String?` | Error feedback |

**Methods:**
- `initializeMatch(Room room)` — calls `matchRepository.initializeMatch()`, subscribes to `watchMatch()`
- `incrementTerritories(playerId)` — calls `matchRepository.requestIncrementTerritories()`
- `decrementTerritories(playerId)` — calls `matchRepository.requestDecrementTerritories()`
- `setTerritories(playerId, count)` — calls `matchRepository.setTerritories()`

**Key difference from GuestMatchCubit:** The host can control **any** player's territories (host privilege).

---

### GuestMatchCubit

```dart
class GuestMatchCubit extends Cubit<GuestMatchState> {
  GuestMatchCubit({
    required MatchRepository matchRepository,
    required String localPlayerId,
  });
}
```

**State:**

| Field | Type | Purpose |
|---|---|---|
| `status` | `GuestMatchStatus` | `initial → loading → active → error` |
| `matchState` | `MatchState?` | Current match (null until first snapshot arrives) |
| `localPlayerId` | `String?` | This device's player ID (set at construction) |
| `errorMessage` | `String?` | Error feedback |

**Methods:**
- `startListening()` — subscribes to `matchRepository.watchMatch()`
- `incrementTerritories()` — calls `matchRepository.requestIncrementTerritories(localPlayerId)`
- `decrementTerritories()` — calls `matchRepository.requestDecrementTerritories(localPlayerId)`
- `setTerritories(count)` — calls `matchRepository.setTerritories(localPlayerId, count)`

**Key difference from HostMatchCubit:** The guest can only request changes for **its own** player (`localPlayerId`).

---

## Pages & Navigation

### Routes

| Route | Page | Cubit |
|---|---|---|
| `/` | `HomePage` | None |
| `/host-room` | `HostRoomPage` | `HostRoomCubit` |
| `/join-room` | `JoinRoomPage` | `JoinRoomCubit` |
| `/host-match` | `HostMatchPage` | `HostMatchCubit` |
| `/guest-match` | `GuestMatchPage` | `GuestMatchCubit` |

### Navigation Flow

```
HomePage
  ├── "Host Game" → HostRoomPage
  │     ├── Create Room → Lobby (player list)
  │     ├── "Start Match" → HostMatchPage
  │     └── "Kill Room" → back to HomePage
  └── "Join Game" → JoinRoomPage
        ├── Discover Rooms → Room list
        ├── Join → Lobby (waiting for host)
        ├── Auto-navigate on RoomStatus.active → GuestMatchPage
        └── "Leave Room" → back to HomePage
```

### Auto-Navigation

- **JoinRoomPage** watches `state.joinedRoom?.status`. When it becomes `RoomStatus.active`, it auto-navigates to `/guest-match`.
- **HostRoomPage** does NOT auto-navigate — the host explicitly clicks "Start Match".

---

## Page State Mapping

### HostRoomPage

| Cubit Status | UI |
|---|---|
| `initial` | Room name input + Player name input + "Create Room" button |
| `hosting` | Loading spinner + "Creating room…" text |
| `lobby` | Player list with avatars + "Start Match" button + "Kill Room" button |
| `error` | Error message |

### JoinRoomPage

| Cubit Status | UI |
|---|---|
| `initial` | "Discover Rooms" button |
| `discovering` | Loading spinner + discovered rooms list + player name input |
| `joining` | Loading spinner + "Joining room…" text |
| `lobby` | Player list with avatars + "Waiting for host to start match…" text + "Leave Room" button |
| `error` | Error message |

### HostMatchPage

| Cubit Status | UI |
|---|---|
| `starting` | Loading spinner |
| `active` | Grid of player cards. Each card: avatar, name, territory count, +/−/Set buttons (host controls all players) |
| `error` | Error message |

### GuestMatchPage

| Cubit Status | UI |
|---|---|
| `loading` | Loading spinner |
| `active` | Grid of player cards. Own card has +/− buttons. Other players' cards are read-only |
| `error` | Error message |

---

## Shared Widgets

All shared widgets live in `features/shared/presentation/widgets/`:

| Widget | Props | Purpose |
|---|---|---|
| `WarAppBar` | `title`, `showBackButton`, `actions` | Consistent app bar |
| `WarElevatedButton` | `onPressed`, `label`, `icon`, `isLoading` | Full-width primary button with loading state |
| `WarOutlinedButton` | `onPressed`, `label`, `icon` | Full-width secondary button |
| `WarTextField` | `label`, `controller`, `validator`, `onChanged` | Styled text input |
| `WarCard` | `child`, `padding`, `onTap` | Card container with consistent styling |
| `PlayerAvatar` | `playerName`, `color`, `radius` | Colored circle with player initial |
| `ErrorIndicatorWidget` | `message` | Error text in theme error color |
| `LoadingIndicatorWidget` | — | Centered `CircularProgressIndicator` |

---

## Localization

All user-facing strings use `context.l10n.xxx` from the ARB files:

| File | Language |
|---|---|
| `lib/l10n/arb/app_en.arb` | English |
| `lib/l10n/arb/app_pt.arb` | Portuguese |

20 keys covering all page labels, button text, loading messages, and error strings. See the ARB files for the full list.

---

## Dependency Injection

Pages receive repositories from the `App` widget's `MultiRepositoryProvider`:

```dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider<GameTransportImpl>(...),
    RepositoryProvider<RoomRepository>(...),
    RepositoryProvider<MatchRepository>(...),
  ],
  child: MaterialApp(...),
)
```

Cubits are created at the page level:

```dart
BlocProvider(
  create: (context) => HostRoomCubit(
    roomRepository: context.read<RoomRepository>(),
  ),
  child: HostRoomPage(),
)
```

This keeps Cubits scoped to their page lifecycle and ensures proper cleanup when navigating away.