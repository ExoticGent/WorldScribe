# WorldScribe

A mobile-first worldbuilding app for writers, game developers, and
storytellers. Create **worlds**, **characters**, **locations**,
**factions**, and **lore**; grow them with AI assistance (Gemini via a
secure backend).

See [`worldscribe_handover.md`](./worldscribe_handover.md) for the
product brief.

---

## Status

Prototype - the Flutter UI can now run live against the real
`worldscribe-9c753` Firebase project with Anonymous Auth and Firestore
enabled across Android, iOS, and web configuration. A seeded in-memory
service still remains as a deliberate fallback when Firebase is
unavailable, which keeps local work and tests resilient. The first AI
slice is now scaffolded too: `AI Forge` can generate a character
through a callable Cloud Function once the Gemini secret is set and the
function is deployed.

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
| 10. Firebase (Auth + Firestore)           | Done |
| 11. Gemini Cloud Function integration     | In progress |

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
    generated_character.dart  AI Forge response model
  services/
    worldscribe_data_service.dart  shared data contract
    in_memory_data_service.dart    seeded mock store for local work/tests
    firestore_data_service.dart    live Firebase implementation
    ai_forge_service.dart          callable-function AI generation client
    app_bootstrap.dart             startup handoff: Firebase or mock fallback
    service_locator.dart           active data/AI services + startup metadata
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
    ai_forge_sheet.dart
  main.dart

functions/
  src/index.ts     callable Gemini -> Firestore character generation
  package.json
  tsconfig.json

web/
  index.html
  manifest.json
  icons/

test/
  services/data_service_test.dart
  widget_test.dart
  visual_preview_test.dart

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
flutter build web
```

Quick browser testing:

```bash
flutter run -d edge
```

---

## Architecture notes

- **Navigation** is entirely route-driven through
  [`AppRouter.generate`](lib/core/router.dart).
- **Data access** goes through the `dataService` service-locator getter.
  Reads stay synchronous for the UI, while writes are async so the same
  screens work with both the mock store and Firestore.
- **AI generation** goes through the `aiForgeService` service-locator
  getter. In Firebase mode it calls the backend `generateCharacter`
  function; otherwise the UI explains that AI Forge is unavailable.
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

### Firebase Follow-Up Hardening

1. Smoke-test create/edit/delete world and character flows on an Android
   or iOS device/emulator, not just the browser build.
2. If startup ever falls back to mock data unexpectedly, check Firebase
   console configuration and platform app registration first.
3. Consider App Check once broader external testing begins.
4. Revisit Anonymous Auth later and disable it if a permanent sign-in
   flow replaces guest access.

### Deploying AI Forge

1. Set the Gemini secret with
   `firebase functions:secrets:set GEMINI_API_KEY`.
2. Deploy the callable backend with
   `firebase deploy --only functions:generateCharacter`.
3. Open a world dashboard, tap `AI Forge`, and generate a character to
   confirm the function writes into Firestore.
4. Expand from character generation into lore, factions, and locations
   after the first live slice is stable.

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
