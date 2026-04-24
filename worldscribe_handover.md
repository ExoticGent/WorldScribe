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
- Web platform scaffolding for quick browser-based testing
- Golden-style visual preview snapshots for key screens

Not implemented yet:

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
web/
  index.html
  manifest.json
  icons/
test/
  widget_test.dart
  visual_preview_test.dart
  goldens/
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
- Real generated `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Local `firebase.json`, `firestore.rules`, and `firestore.indexes.json`
- Deployed Firestore rules and indexes on the default database

Current Firebase project:

- Project ID: `worldscribe-9c753`
- Android app ID: `1:625579797661:android:25ede5575cbceea4a07874`
- iOS app ID: `1:625579797661:ios:dd176953c72ca3f4a07874`

What still needs to happen before live Firebase works:

1. Enable Anonymous Auth in Firebase Authentication
2. Smoke-test the live flows on a device/emulator
3. Confirm startup no longer falls back to the in-memory mock

Until those project-side steps are complete, the app intentionally falls
back to in-memory mode.

Important long-term note:

- Anonymous Auth is acceptable here as a short-term development and
  testing bridge.
- Once WorldScribe has a real sign-in flow, revisit whether Anonymous
  Auth is still needed.
- If guest accounts are no longer needed, disable Anonymous Auth in
  Firebase Authentication so the long-term auth surface stays tighter.

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
- `flutter build apk --debug`
- `flutter build web`

Coverage currently includes:

- Splash to home transition
- Seeded worlds rendering
- Create world flow
- Add character flow
- Delete character flow
- In-memory service behavior
- Rendered visual previews for splash, home, world dashboard, and
  character detail

---

## Risks and gaps

- Firebase app configuration and Firestore deployment are in place, but
  auth provider setup may still block live sign-in
- Anonymous auth is convenient for bootstrapping but may need upgrading
  later if named user accounts are required
- Firestore delete currently removes a world's characters client-side by
  batching subcollection deletes; large worlds may eventually need a
  server-side cleanup strategy
- Gemini integration is still only planned, not started

---

## Recommended next steps

1. Enable Anonymous Auth in the Firebase project
2. Smoke-test create/read/delete against Firestore on device
3. Add world editing and world deletion flows
4. Start the Cloud Function + Gemini integration for AI generation
5. Revisit Anonymous Auth later and disable it if permanent sign-in
   makes guest accounts unnecessary

---

## Notes

- Do not ship API keys in the Flutter app
- Keep Gemini calls behind Cloud Functions or another backend layer
- The in-memory fallback is deliberate and should stay usable for local
  development and tests
