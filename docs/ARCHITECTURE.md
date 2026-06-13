# Architecture

Source-of-truth document for the **War Armies App** architecture. Read this before making structural decisions.

---

## Overview

War Armies is a **local-network territory counter** for the War (Risk-style) board game. One device **hosts** a room, other devices **discover and join** it over Wi-Fi via mDNS. The host is the single source of truth for match state.

```
┌─────────────────────────────────────────────────────────┐
│                      Presentation                        │
│  Cubits ←→ Pages (Flutter widgets)                      │
├─────────────────────────────────────────────────────────┤
│                       Domain                             │
│  Repository interfaces + Domain models                   │
├─────────────────────────────────────────────────────────┤
│                        Data                               │
│  Repository implementations ← Data sources ← Transport   │
└─────────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### Presentation (`features/*/presentation/`)

| Component | Responsibility |
|---|---|
| **Cubits** | Hold UI state, call repository methods, listen to streams, emit new states |
| **Pages** | Stateless widgets that build UI from Cubit state via `BlocBuilder` / `BlocConsumer` |
| **Shared widgets** | Reusable UI components (`WarAppBar`, `WarElevatedButton`, `WarCard`, `PlayerAvatar`, etc.) |

Cubits **never** access data sources or transport directly. They go through repository interfaces.

### Domain (`features/*/domain/`)

| Component | Responsibility |
|---|---|
| **Models** | Immutable value objects (`Room`, `Player`, `MatchState`, `PlayerTerritories`, `RoomDescriptor`, `ConnectionState`) |
| **Repository interfaces** | Abstract contracts (`GameTransport`, `RoomRepository`, `MatchRepository`) that the data layer implements |

Domain has **zero** dependencies on Flutter, packages, or infrastructure.

### Data (`features/*/data/` + `common/transport/data/`)

| Component | Responsibility |
|---|---|
| **Data sources** | Create/parse wire messages (`RoomDataSource`, `MatchDataSource`), manage I/O (`LanHostDataSource`, `LanClientDataSource`) |
| **Mappers** | Convert between domain models ↔ JSON maps (`RoomMappers`, `MatchMappers`) |
| **Repository implementations** | Orchestrate data sources and transport, implement domain interfaces (`RoomRepositoryImpl`, `MatchRepositoryImpl`, `GameTransportImpl`) |
| **Wire message types** | String constants for the 9 protocol message types (`WireMessageType`) |
| **Exceptions** | `TransportException`, `RoomException`, `MatchException` |

---

## Feature Structure

Every feature follows the same directory layout:

```
features/<feature>/
├── data/
│   ├── data_sources/       # I/O and message creation/parsing
│   ├── exceptions/          # Feature-specific exceptions
│   ├── mappers/             # Domain model ↔ JSON conversion
│   └── data.dart            # Barrel export
├── domain/
│   ├── models/              # Immutable value objects
│   ├── repositories/        # Abstract interfaces + implementations
│   └── domain.dart           # Barrel export
└── presentation/
    ├── cubits/               # State management (BLoC/Cubit)
    ├── view/                 # Page widgets
    ├── widgets/              # Feature-specific widgets
    └── presentation.dart     # Barrel export
```

Shared infrastructure lives in `common/transport/` (not inside a feature).

---

## Dependency Rule

Dependencies flow **inward only**:

```
Presentation → Domain ← Data
```

- **Presentation** imports from Domain (repository interfaces, models)
- **Data** imports from Domain (implements interfaces, uses models)
- **Domain** imports from nothing (pure Dart)
- **Presentation** never imports from Data directly

---

## Dependency Injection

The `App` widget provides repositories via `MultiRepositoryProvider`:

```dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider<GameTransportImpl>(...),
    RepositoryProvider<RoomRepository>(...),    // uses GameTransportImpl
    RepositoryProvider<MatchRepository>(...),    // uses GameTransportImpl
  ],
  child: MaterialApp(...),
)
```

Pages create Cubits via `BlocProvider` at the page level, injecting the repository from context:

```dart
BlocProvider(
  create: (context) => HostRoomCubit(
    roomRepository: context.read<RoomRepository>(),
  ),
  child: HostRoomPage(),
)
```

---

## Key Models

### Room

```dart
class Room {
  final String id;
  final String name;
  final String hostPlayerId;
  final List<Player> players;
  final RoomStatus status;  // lobby | active | ended
}
```

### Player

```dart
class Player {
  final String id;
  final String name;
  final Color color;  // serialized as ARGB32 int over the wire
}
```

### MatchState

```dart
class MatchState {
  final Room room;
  final Map<String, PlayerTerritories> territoriesByPlayer;
  final int version;  // monotonic, incremented on every change
}
```

### PlayerTerritories

```dart
class PlayerTerritories {
  final String playerId;
  final int count;
  int get troops => count ~/ 2;  // derived: territories ÷ 2
}
```

### RoomDescriptor

```dart
class RoomDescriptor {
  final String id;
  final String name;
  final String host;  // IP address
  final int port;
}
```

### ConnectionState

```dart
enum ConnectionState {
  idle, advertising, discovering, connecting, connected, disconnected
}
```

---

## Test Coverage

165 tests across all layers:

| Layer | Test File | Tests |
|---|---|---|
| Wire protocol | `wire_message_test.dart` | 6 |
| Transport | `game_transport_impl_test.dart` | 19 |
| Room mappers | `room_mappers_test.dart` | 17 |
| Room data source | `room_data_source_test.dart` | 19 |
| Room repository | `room_repository_impl_test.dart` | 13 |
| Match mappers | `match_mappers_test.dart` | 13 |
| Match data source | `match_data_source_test.dart` | 39 |
| Match repository | `match_repository_impl_test.dart` | 14 |
| Host room cubit | `host_room_cubit_test.dart` | 6 |
| Join room cubit | `join_room_cubit_test.dart` | 7 |
| Host match cubit | `host_match_cubit_test.dart` | 7 |
| Guest match cubit | `guest_match_cubit_test.dart` | 5 |

Run with: `flutter test`