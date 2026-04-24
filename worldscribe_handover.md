# WorldScribe Handover

## Project overview

WorldScribe is a mobile-first worldbuilding app for writers, game
developers, and storytellers.

Current user-facing MVP flow:

- Create a world
- Browse worlds from the home screen
- Open a world dashboard
- Add characters to a world
- View character details
- Delete characters

The UI is themed as a dark fantasy journal and currently runs cleanly in
Flutter with a local seeded data source by default.

---

## Current status

Implemented:

- Flutter app shell, routing, theme, and splash screen
- World list, world creation, and world dashboard
- Characters list, add-character sheet, character detail, delete flow
- In-memory seeded data service for local development and tests
- Async-ready data abstraction for future backend integration
- Firebase bootstrap scaffold with anonymous auth and Firestore service
- Loading and error states for data-backed screens
- Unit and widget tests covering the main MVP flows

Not implemented yet:

- Real Firebase project configuration files
- Firestore security rules
- Gemini / AI generation flow
- Locations, factions, lore editing, and AI Forge functionality

---

## Architecture

App structure:

```text
lib/
  core/
    constants/
    theme/
    router.dart
  models/
    world.dart
    character.dart
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
  services/
    worldscribe_data_service.dart
    in_memory_data_service.dart
    firestore_data_service.dart
    app_bootstrap.dart
    service_locator.dart
  firebase_options.dart
  main.dart
```

Data flow:

Flutter UI
-> `AppBootstrap`
-> `WorldscribeDataService`
-> either `InMemoryDataService` or `FirestoreDataService`

Important detail:

- The UI reads synchronously through `dataService`, but writes are async.
- That keeps the current screens simple while still supporting Firestore.
- If Firebase initialization fails, the app falls back to the mock store
  and shows a notice on the home screen.

---

## Firebase status

The codebase now contains:

- `firebase_core`, `firebase_auth`, and `cloud_firestore`
- `AppBootstrap` startup wiring
- Anonymous sign-in attempt during bootstrap
- Firestore-backed data service under `users/{uid}/worlds/{worldId}`
- A placeholder `lib/firebase_options.dart`

What still needs to happen before live Firebase works:

1. Run `flutterfire configure`
2. Replace the placeholder `lib/firebase_options.dart` with generated values
3. Commit platform config files such as `google-services.json`
4. Enable Anonymous Auth in Firebase Authentication
5. Add Firestore rules for per-user isolation

Until then, the app intentionally falls back to in-memory mode.

---

## Firestore shape

```text
users/
  {uid}/
    worlds/
      {worldId}/
        name
        genre
        description
        createdAt
        characters/
          {characterId}/
            name
            role
            description
            createdAt
```

---

## Testing

Passing checks at handoff time:

- `flutter analyze`
- `flutter test`

Coverage currently includes:

- Splash to home transition
- Seeded worlds rendering
- Create world flow
- Add character flow
- Delete character flow
- In-memory service behavior

---

## Risks and gaps

- Firebase cannot actually connect until generated config files exist
- Anonymous auth is convenient for bootstrapping but may need upgrading
  later if named user accounts are required
- Firestore delete currently removes a world's characters client-side by
  batching subcollection deletes; large worlds may eventually need a
  server-side cleanup strategy
- Gemini integration is still only planned, not started

---

## Recommended next steps

1. Run `flutterfire configure` against the real Firebase project
2. Add Firestore security rules and validate anonymous sign-in
3. Smoke-test create/read/delete against Firestore on device
4. Add world editing and world deletion flows
5. Start the Cloud Function + Gemini integration for AI generation

---

## Notes

- Do not ship API keys in the Flutter app
- Keep Gemini calls behind Cloud Functions or another backend layer
- The in-memory fallback is deliberate and should stay usable for local
  development and tests
