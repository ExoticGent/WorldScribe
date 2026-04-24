# WorldScribe

A mobile-first worldbuilding app for writers, game developers, and
storytellers. Create **worlds**, **characters**, **locations**,
**factions**, and **lore**; grow them with AI assistance (Gemini via a
secure backend).

See [`worldscribe_handover.md`](./worldscribe_handover.md) for the
product brief.

---

## Status

Prototype - the Flutter UI is running against a seeded in-memory mock
store today. Firebase app configuration is now connected to the real
`worldscribe-9c753` project, and Firestore rules/indexes have been
deployed. The remaining backend cutover work is enabling an auth
provider for sign-in and smoke-testing the live flows. Gemini is not
wired yet.

| Milestone                                 | Status |
| ----------------------------------------- | ------ |
| 1. Flutter project scaffolding            | Done |
| 2. App theme + routing                    | Done |
| 3. Splash screen                          | Done |
| 4. Home / Worlds list                     | Done |
| 5. Create World                           | Done |
| 6. World Dashboard                        | Done |
| 7. Characters list + add-character sheet  | Done |
| 8. Character Detail (view + delete)       | Done |
| 9. Mock data service + tests              | Done |
| 10. Firebase (Auth + Firestore)           | In progress |
| 11. Gemini Cloud Function integration     | Pending |

---

## Tech stack

- **Frontend**: Flutter 3.11 / Dart 3.11
- **State management**: `ChangeNotifier` + `ListenableBuilder`
- **Backend**: Firebase Auth, Firestore, Cloud Functions
- **AI**: Gemini API via a backend-only Cloud Function

---

## Project structure

```text
lib/
  core/
    constants/      AppStrings, AppRoutes, typed RouteArgs
    theme/          AppColors (dark-fantasy palette), AppTheme
    router.dart     AppRouter.generate (onGenerateRoute)
  models/
    world.dart      immutable World
    character.dart  immutable Character
  services/
    worldscribe_data_service.dart  shared data contract
    in_memory_data_service.dart    seeded mock store for local work/tests
    firestore_data_service.dart    live Firebase implementation
    app_bootstrap.dart             startup handoff: Firebase or mock fallback
    service_locator.dart           active service + startup metadata
  screens/
    splash_screen.dart
    home_screen.dart
    create_world_screen.dart
    world_dashboard_screen.dart
    characters_screen.dart
    character_detail_screen.dart
  widgets/
    empty_state.dart
    loading_state.dart
    world_card.dart
    character_card.dart
    dashboard_tile.dart
    add_character_sheet.dart
  main.dart

test/
  services/data_service_test.dart
  widget_test.dart

firebase.json
firestore.rules
firestore.indexes.json
```

---

## Getting started

Requires Flutter 3.11+ (Dart 3.11+).

```bash
flutter pub get
flutter run
```

Quality gates:

```bash
flutter analyze
flutter test
```

---

## Architecture notes

- **Navigation** is entirely route-driven through
  [`AppRouter.generate`](lib/core/router.dart).
- **Data access** goes through the `dataService` service-locator getter.
  Reads stay synchronous for the UI, while writes are async so the same
  screens work with both the mock store and Firestore.
- **Bootstrap** happens in
  [`AppBootstrap`](lib/services/app_bootstrap.dart). If Firebase is
  configured, the app signs in anonymously and uses Firestore.
  Otherwise it falls back to seeded mock data and shows a small notice
  on the Home screen.
- **Seeded mock data** lives inside
  [`InMemoryDataService`](lib/services/in_memory_data_service.dart) and
  is reset between tests through `resetForTests()`.
- **No API keys ship in the app.** Gemini is still planned as a
  Cloud Function call so keys remain server-side.

### Finishing Firebase setup

1. Enable Anonymous Auth in Firebase Authentication for
   `worldscribe-9c753`.
2. Smoke-test create/read/delete against the live backend on a device or
   emulator.
3. If startup still falls back to mock data, check Firebase console
   propagation and auth settings first.

### Where to plug in Gemini

1. Create a Cloud Function such as `functions/src/generateLore.ts`.
2. Validate and normalize the model response to JSON server-side.
3. Add a client `ai_service.dart` that calls the function; keep the API
   key off the device.

---

## UI direction

- Dark-fantasy journal mood
- Card-based layouts
- Material 3 with a custom theme

---

## Commit style

Conventional, human-readable, imperative:

- `Initial Flutter project setup`
- `Add WorldScribe app theme and route scaffolding`
- `Add Splash Screen with WorldScribe wordmark`
- `Add World model and Home / Worlds screen with mock data`
- `Add Create World screen with validated form`
- `Add World Dashboard screen`
- `Add Characters screen with add-character bottom sheet`
- `Add Character Detail screen with delete flow`
