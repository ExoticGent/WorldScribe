# WorldScribe

A mobile-first worldbuilding app for writers, game developers, and
storytellers. Create **worlds**, **characters**, **locations**,
**factions**, and **lore**; grow them with AI assistance (Gemini via a
secure backend).

See [`worldscribe_handover.md`](./worldscribe_handover.md) for the product brief.

---

## Status

Prototype — the Flutter UI is up and running against an in-memory mock
data store. Firebase and Gemini are **not yet wired**; the next
milestones pick them up.

| Milestone                                 | Status |
| ----------------------------------------- | ------ |
| 1. Flutter project scaffolding            | Done   |
| 2. App theme + routing                    | Done   |
| 3. Splash screen                          | Done   |
| 4. Home / Worlds list                     | Done   |
| 5. Create World                           | Done   |
| 6. World Dashboard                        | Done   |
| 7. Characters list + add-character sheet  | Done   |
| 8. Character Detail (view + delete)       | Done   |
| 9. Mock data service + tests              | Done   |
| 10. Firebase (Auth + Firestore)           | Pending |
| 11. Gemini Cloud Function integration     | Pending |

---

## Tech stack

- **Frontend**: Flutter 3.11 / Dart 3.11 (Android-first, iOS targets
  are scaffolded but untested)
- **State management**: `ChangeNotifier` + `ListenableBuilder` — no
  external state packages yet
- **Backend** (planned): Firebase Auth, Firestore, Cloud Functions
- **AI** (planned): Gemini API, called from a Cloud Function so the
  key never ships in the app

---

## Project structure

```
lib/
  core/
    constants/      AppStrings, AppRoutes, typed RouteArgs
    theme/          AppColors (dark-fantasy palette), AppTheme
    router.dart     AppRouter.generate (onGenerateRoute)
  models/
    world.dart      immutable World (+ copyWith/toJson/fromJson)
    character.dart  immutable Character
  services/
    data_service.dart   singleton ChangeNotifier, in-memory store,
                        seeded with two sample worlds. Swap-in point
                        for Firestore.
  screens/
    splash_screen.dart
    home_screen.dart
    create_world_screen.dart
    world_dashboard_screen.dart
    characters_screen.dart
    character_detail_screen.dart
  widgets/
    empty_state.dart
    world_card.dart
    character_card.dart
    dashboard_tile.dart
    add_character_sheet.dart
  main.dart

test/
  services/data_service_test.dart   unit tests for DataService
  widget_test.dart                  widget tests for core flows
                                    (splash → home, create world,
                                    add character, delete character)
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
flutter analyze   # must be clean
flutter test      # 11 tests, all green
```

---

## Architecture notes (for the next agent)

- **Navigation** is entirely via named routes driven by
  [`AppRouter.generate`](lib/core/router.dart). Every screen has one
  constant in [`AppRoutes`](lib/core/constants/app_routes.dart); typed
  argument objects live in
  [`route_args.dart`](lib/core/constants/route_args.dart).
- **Data access** goes through `DataService.instance` — a singleton
  `ChangeNotifier`. Screens wrap reads in `ListenableBuilder` so they
  rebuild on change. This surface (`worlds`, `charactersFor`,
  `addWorld`, `addCharacter`, …) is deliberately shaped like the
  Firestore operations we'll want later, so the swap to a
  Firestore-backed implementation should be drop-in.
- **Seeded mock data** lives inside
  [`DataService._seedMockData`](lib/services/data_service.dart). The
  seed is reset between tests via the `@visibleForTesting`
  `resetForTests()` helper.
- **Theme**: single entry point in
  [`AppTheme.dark`](lib/core/theme/app_theme.dart) with a shared
  colour palette in
  [`AppColors`](lib/core/theme/app_colors.dart). No `google_fonts`
  dependency yet — stock Material 3 Typography is used.
- **No API keys ship in the app.** When AI arrives, the Flutter app
  will call a Cloud Function; the Gemini key stays server-side only.

### Where to plug in Firebase

1. Add `firebase_core`, `cloud_firestore`, and `firebase_auth` to
   `pubspec.yaml`, run `flutterfire configure`.
2. Create `lib/services/firestore_data_service.dart` implementing the
   same public surface as `DataService` (worlds / charactersFor /
   addWorld / addCharacter / delete\*).
3. Replace `DataService.instance` wiring in the screens with a small
   service locator (or keep it a singleton but swap the type). The
   UI code shouldn't need changes beyond that.

### Where to plug in Gemini

1. Create a Cloud Function (`functions/src/generateLore.ts`) that
   takes a prompt, calls Gemini, validates the JSON response, and
   writes to Firestore.
2. Add a `lib/services/ai_service.dart` that invokes the function via
   `cloud_functions`. Screens call `AiService.generateCharacter(...)`
   etc.; no key is present on the client.

---

## UI direction

- Dark-fantasy journal: ink-dark backgrounds, aged-parchment text,
  gold accents.
- Card-based layouts throughout.
- Material 3 components with a custom `ThemeData` — no third-party
  UI kits.

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

Each milestone is one commit, pushed to `main`.
