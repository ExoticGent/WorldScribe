# WorldScribe Handover

## Project overview

WorldScribe is a mobile-first worldbuilding app for writers, game
developers, and storytellers.

Current user-facing MVP flow:

- Create a world
- Edit a world
- Delete a world
- Browse worlds from the home screen
- Open a world dashboard
- Use AI Forge to generate a character
- Add characters to a world
- Add locations to a world
- View character details
- Delete characters

The UI is themed as a dark fantasy journal and now runs cleanly against
Firebase when available, with a local seeded fallback kept on purpose
for resilience and testing.

---

## Current status

Implemented:

- Flutter app shell, routing, theme, and splash screen
- World list, world creation/edit/delete, and world dashboard
- Characters list, add-character sheet, character detail, delete flow
- Locations list and add-location sheet
- AI Forge bottom sheet that generates one character into the current
  world
- In-memory seeded data service for local development and tests
- Async-ready data abstraction for future backend integration
- Firebase bootstrap scaffold with anonymous auth and Firestore service
- Firebase web app wiring and live browser smoke-testing
- Cloud Functions scaffold for Gemini-backed character generation
- Loading and error states for data-backed screens
- Unit and widget tests covering the main MVP flows
- Firestore service tests covering snapshot sync and CRUD persistence
- Web platform scaffolding for quick browser-based testing
- Golden-style visual preview snapshots for key screens

Not implemented yet:

- Live Gemini secret + function deployment
- Location detail/edit/delete flows
- Factions, lore editing, and broader AI Forge functionality

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
    location.dart
    generated_character.dart
  screens/
    splash_screen.dart
    home_screen.dart
    create_world_screen.dart
    world_dashboard_screen.dart
    characters_screen.dart
    locations_screen.dart
    character_detail_screen.dart
  widgets/
    empty_state.dart
    loading_state.dart
    world_card.dart
    character_card.dart
    dashboard_tile.dart
    add_character_sheet.dart
    add_location_sheet.dart
    location_card.dart
    ai_forge_sheet.dart
  services/
    worldscribe_data_service.dart
    in_memory_data_service.dart
    firestore_data_service.dart
    ai_forge_service.dart
    app_bootstrap.dart
    service_locator.dart
  firebase_options.dart
  main.dart
functions/
  src/index.ts
  package.json
  tsconfig.json
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
- AI generation goes through a separate `aiForgeService` abstraction so
  the UI can degrade cleanly when Firebase/Functions are unavailable.
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
- Web app ID: `1:625579797661:web:8a0b0a54084eb5f4a07874`

Project-side Firebase setup completed:

1. Anonymous Auth enabled in Firebase Authentication
2. Firestore rules and indexes deployed
3. Firebase web app registered and wired into FlutterFire
4. Live browser smoke test completed successfully

Remaining Firebase validation:

1. Smoke-test create/edit/delete world and character flows on Android or
   iOS hardware/emulator
2. Confirm platform-specific builds do not unexpectedly fall back to the
   in-memory mock

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

AI Forge Cloud Function shape:

- Callable function: `generateCharacter`
- Input: `worldId`, `prompt`
- Auth: requires Firebase Auth user
- Behavior: reads the target world, asks Gemini for a structured
  character, validates the JSON, writes the character into Firestore,
  and returns the created payload to the client

Deployment steps still required:

1. Run `firebase functions:secrets:set GEMINI_API_KEY`
2. Run `firebase deploy --only functions:generateCharacter`
3. Smoke-test AI Forge against the live backend

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
- Create/edit/delete world flow
- AI Forge character generation flow with a fake service
- Add location flow
- Add character flow
- Delete character flow
- In-memory service behavior
- Firestore service behavior, snapshot sync, and CRUD persistence
- Rendered visual previews for splash, home, world dashboard, and
  character detail

---

## Risks and gaps

- Anonymous auth is enabled for now, which is convenient for testing but
  still expands the long-term auth surface
- Browser-based Firebase testing is working, but Android/iOS device
  validation is still recommended before calling the backend cutover
  fully battle-tested
- AI Forge code is wired, but Gemini generation is not live until the
  `GEMINI_API_KEY` secret is set and the function is deployed
- Locations are live for list/add, but there is not yet a dedicated
  location detail or edit/delete flow
- Anonymous auth is convenient for bootstrapping but may need upgrading
  later if named user accounts are required
- Firestore delete currently removes a world's characters client-side by
  batching subcollection deletes; large worlds may eventually need a
  server-side cleanup strategy
- AI Forge currently covers character generation only, not lore,
  factions, or locations yet

---

## Recommended next steps

1. Smoke-test create/edit/delete world and character flows against
   Firestore on Android or iOS
2. Set the Gemini secret and deploy `generateCharacter`
3. Smoke-test AI Forge against the live backend
4. Add a location detail/edit path
5. Expand factions, lore, and broader AI Forge functionality
4. Revisit Anonymous Auth later and disable it if permanent sign-in
   makes guest accounts unnecessary

---

## Notes

- Do not ship API keys in the Flutter app
- Keep Gemini calls behind Cloud Functions or another backend layer
- The in-memory fallback is deliberate and should stay usable for local
  development and tests
