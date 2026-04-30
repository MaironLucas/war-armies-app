# war_armies_app

A Flutter companion app to track troop counts for the **War** board game (Brazilian *Risk*). One device hosts a match over the local Wi-Fi network (mDNS + WebSocket); other players join, view the match, and request changes to their own troops.

For the full product spec, scope, domain model, and networking protocol, see [`REQUIREMENTS.md`](./REQUIREMENTS.md). Treat that file as the source of truth before making any product or scope decisions.

## Stack

- Flutter (stable), Dart 3
- Clean Architecture (`data` / `domain` / `presentation` per feature)
- `flutter_bloc` Cubit for state management
- `shelf` + `shelf_web_socket` (host) / `web_socket_channel` (guest)
- `nsd` for mDNS discovery
- Linting: `very_good_analysis`

## Run

```sh
flutter pub get
flutter run
```
