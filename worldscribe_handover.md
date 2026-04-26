# WorldScribe Handover

> Living handoff document. Read this first if you are picking the project
> up cold. It describes what ships today, the patterns the codebase
> commits to, and where to look next.

## Project overview

WorldScribe is a mobile-first worldbuilding app for writers, game
developers, and storytellers. The UI is themed as a dark fantasy
journal (Material 3, custom `AppColors` palette).

It runs against Firebase when available and falls back to a seeded
in-memory store for offline development, tests, and resilience when
Firebase init fails.

Repo: github.com/ExoticGent/WorldScribe (branch `main`).
Stack: Flutter (Dart SDK ^3.11.5), Firebase (Auth, Firestore, Functions),
Cloud Functions/TypeScript scaffold for Gemini-backed AI Forge.

Workflow rules carried by this repo:

- Build in small milestones, each shippable on its own.
- Every milestone runs `flutter analyze` and `flutter test` clean before
  it lands.
- Commit + push to GitHub after each milestone. No big-bang changes.
- Never ship API keys in the Flutter app — Gemini stays behind Functions.

---

## Current MVP flow

Today the user can:

- Create, edit, and delete a world
- Browse worlds from the home screen and open a world dashboard
- Add, edit, and delete characters in a world (via dual-mode sheet)
- Add, edit, and delete locations in a world (via dual-mode sheet)
- Create, update, and delete factions in a world at the data-service
  level (CRUD only — UI surface lands in M8c)
- View character detail and location detail
- Generate a character via the AI Forge sheet (wired against a Cloud
  Function — currently behind a fake service in tests; see Firebase
  status for live deployment notes)

All forms validate input, cap text length, prompt before discarding
unsaved edits, and confirm before deleting.

---

## Implemented

App + UX:

- App shell, routing, theme, splash screen
- World list + dashboard
- World create/edit/delete
- Character add/edit/delete + character detail screen
- Location add/edit/delete + location detail screen
- Character ↔ location linking (M7b) — character detail shows a
  "Linked locations" section, location detail shows "Linked characters".
  Tap a row to navigate to the linked entity, tap the unlink icon to
  remove the link, or use the action button to open a picker that lists
  only the unlinked entities in the world.
- Faction CRUD on the data layer (M8a) — `addFaction`, `updateFaction`,
  `deleteFaction`, `factionsFor(worldId)`, `factionById` on the abstract
  service, implemented on both `InMemoryDataService` and
  `FirestoreDataService`. Factions live under
  `users/{uid}/worlds/{worldId}/factions/{factionId}` with name,
  ideology, description, createdAt — no relationship arrays yet (those
  land in M8b). `deleteWorld` cascades the new subcollection.
- AI Forge bottom sheet (character generation only, one entity at a time)
- Loading and error states for data-backed screens

Foundation hardening (shared patterns the rest of the app builds on):

- `AppInput` length budgets — single source of truth for max name /
  tagline / description / AI prompt lengths. Used by every form's
  `maxLength` and validator.
- `FormValidators` (pure validator helpers) — `required`, `maxLength`,
  `requiredWithMaxLength`. Every TextFormField in the app uses these so
  required-field errors and length errors look identical everywhere.
- `ConfirmDialog.show(...)` — the single destructive-confirmation
  prompt. Used by every delete flow and the discard-changes guard.
  Honors `isDestructive` to paint the confirm button in `emberRed`.
- `confirmDiscardChanges(context)` (PopScope discard guard) — wraps
  every form route in `PopScope(canPop: !_isDirty, ...)` so back gestures
  and modal-sheet dismissals prompt before throwing away unsaved edits.
  Lives at `lib/core/forms/discard_changes_guard.dart`.
- Dual-mode form sheets — `AddCharacterSheet` and `AddLocationSheet`
  take an optional `initial:` to switch between add and edit. The single
  sheet handles both flows so create/edit visuals stay in sync.
- Centralized strings — `AppStrings` holds every user-facing label so
  copy changes are one-line edits.
- `EntityPickerSheet` — generic modal-bottom-sheet picker. Takes a
  pre-filtered list of `EntityPickOption`s (id + title + optional
  subtitle/icon) and returns the chosen id. Used by character_detail and
  location_detail today; built generically so the next entity types
  (factions, lore) can drop straight into the same picker without
  inventing a second one.
- `LinkedEntitiesSection` — drop-in widget for "Linked X" sections on
  detail screens. Renders the linked rows (tap to navigate, tap the
  link-off icon to unlink), an empty hint, and a "Link a Y" action
  button that opens an `EntityPickerSheet`. Presentational only — the
  parent owns the data-service calls.

Backend + data layer:

- `WorldscribeDataService` abstraction with two implementations:
  - `InMemoryDataService` (seeded; default fallback; `resetForTests()`
    available behind `@visibleForTesting`)
  - `FirestoreDataService` (real backend, `users/{uid}/worlds/...`)
- `AppBootstrap` initializes Firebase, attempts anonymous sign-in,
  installs the Firestore-backed data service. Falls back to the
  in-memory store and exposes an error message on the home screen if
  bootstrap fails.
- Service-locator pattern via `dataService` and `aiForgeService` so
  screens don't reach into concrete classes.
- AI Forge wired through a separate `AiForgeService` so the UI degrades
  cleanly when Functions are unavailable.
- **Relationship layer (M7a)** — bidirectional, typed references stored
  on both ends. `Character` carries `List<String> locationIds`; `Location`
  carries `List<String> characterIds`. The data-service abstraction owns
  the link primitive (`linkCharacterAndLocation` /
  `unlinkCharacterAndLocation`) so screens never have to write both sides
  themselves. Both implementations:
  - Are idempotent (linking the same pair twice is a no-op; unlinking a
    non-existent link is a no-op)
  - Cascade on delete — deleting a character strips its id from every
    location's `characterIds`, and vice versa for locations
  - Atomic on Firestore — link/unlink and cascade-delete go through a
    single Firestore batch using `FieldValue.arrayUnion` /
    `FieldValue.arrayRemove`, with optimistic local cache updates and
    rollback on failure

Firebase integration:

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`
- Generated `lib/firebase_options.dart`
- Android `google-services.json` and iOS `GoogleService-Info.plist`
- `firebase.json`, `firestore.rules`, `firestore.indexes.json` (rules +
  indexes deployed; rules cover subcollections)
- Anonymous Auth enabled
- Web app registered and verified via live browser smoke test
- Cloud Functions scaffold (`functions/src/index.ts`) for the
  `generateCharacter` callable

Tests + quality gates (75 passing as of this handoff):

- `flutter analyze` clean
- `flutter test` — all green
- `flutter build apk --debug` and `flutter build web` both succeed

Test files:

- `test/widget_test.dart` — main MVP flow coverage (splash → home,
  seeded worlds, world CRUD, AI Forge with fake service, add character,
  delete character, add location, edit character/location, discard-
  changes prompts on world / character / location forms, linking and
  unlinking through the entity picker on both character_detail and
  location_detail, and picker filtering of already-linked entities)
- `test/integration/firestore_app_test.dart` — end-to-end smoke test
  driving the real `WorldScribeApp` widget through a `FirestoreDataService`
  backed by `fake_cloud_firestore`. Catches breakage at the UI ↔
  data-service boundary.
- `test/services/data_service_test.dart` — in-memory service behavior
  including a `factions` group (CRUD + cascade on world delete) and a
  `relationships` group (link / unlink idempotency, cascade-delete on
  both sides)
- `test/services/firestore_data_service_test.dart` — Firestore service
  snapshot sync and CRUD for worlds, characters, locations, and factions
  (uses `fake_cloud_firestore`); also covers the `relationships` group
  end-to-end against the fake Firestore (atomic batch writes, cascade-
  delete writes through to the inverse-side doc), and asserts that
  deleting a world wipes its `factions` subcollection alongside
  `characters` and `locations`
- `test/widgets/confirm_dialog_test.dart` — destructive vs non-
  destructive styling, confirm/cancel/scrim-dismiss return values
- `test/core/forms/form_validators_test.dart` — required, maxLength,
  requiredWithMaxLength
- `test/visual_preview_test.dart` + `test/goldens/` — golden-style
  snapshots for splash, home, world dashboard, character detail
- `test/fake_ai_forge_service.dart` — shared fake for AI Forge

Manual device smoke test:

- `device_smoke_test.md` at repo root — 10-minute checklist for
  validating the live Firestore path on a real Android or iOS device.
  Run after FlutterFire upgrades, bootstrap changes, or rules / index
  changes. Specifically catches the things `fake_cloud_firestore` can't:
  native build config drift, real auth / rules failures, FlutterFire
  init issues.

---

## Not implemented yet

- Live Gemini secret + Function deployment (intentionally postponed —
  needs Blaze billing on `worldscribe-9c753`; see "AI Forge live
  deployment" below)
- Faction relationships (M8b) — `factionIds` on Character/Location and
  inverse arrays on Faction, atomic both-sides link primitives, cascade
  on delete. Today factions are standalone records with no edges.
- Faction UI (M8c) — list screen, detail screen, dual-mode add/edit
  sheet, dashboard tile. The data layer is ready; nothing is wired into
  the UI yet.
- Lore editor; broader AI Forge (locations, lore, factions all still
  TODO)
- Permanent (non-anonymous) sign-in flow
- Server-side cleanup for very large world deletes (currently client-
  side batched subcollection delete)
- Android / iOS device smoke test against live Firestore (web smoke
  test passed; native still recommended before declaring backend cutover
  battle-tested — see `device_smoke_test.md` for the checklist)

---

## Architecture

### Directory layout

```text
lib/
  core/
    constants/
      app_input.dart          # max-length budgets for every text field
      app_routes.dart         # named-route constants
      app_strings.dart        # every user-facing string
      route_args.dart         # typed route argument records
    forms/
      discard_changes_guard.dart  # confirmDiscardChanges(context)
      form_validators.dart        # FormValidators.required / maxLength
    theme/
      app_colors.dart
      app_theme.dart
    router.dart               # AppRouter.generate
  models/
    world.dart
    character.dart
    location.dart
    faction.dart
    generated_character.dart
  screens/
    splash_screen.dart
    home_screen.dart
    create_world_screen.dart            # also handles world edit
    world_dashboard_screen.dart
    characters_screen.dart
    character_detail_screen.dart
    locations_screen.dart
    location_detail_screen.dart
  widgets/
    add_character_sheet.dart            # add + edit (dual mode)
    add_location_sheet.dart             # add + edit (dual mode)
    ai_forge_sheet.dart
    character_card.dart
    confirm_dialog.dart                 # ConfirmDialog.show
    dashboard_tile.dart
    empty_state.dart
    entity_picker_sheet.dart            # generic link picker (M7b)
    linked_entities_section.dart        # detail-screen linked-list (M7b)
    loading_state.dart
    location_card.dart
    world_card.dart
  services/
    ai_forge_service.dart
    app_bootstrap.dart
    firestore_data_service.dart
    in_memory_data_service.dart
    service_locator.dart                # `dataService`, `aiForgeService`
    worldscribe_data_service.dart       # abstract base class
  firebase_options.dart
  main.dart

functions/
  src/index.ts                # generateCharacter callable scaffold
  package.json
  tsconfig.json

web/
  index.html
  manifest.json
  icons/

test/
  core/forms/form_validators_test.dart
  integration/firestore_app_test.dart      # end-to-end UI ↔ Firestore smoke
  services/data_service_test.dart
  services/firestore_data_service_test.dart
  widgets/confirm_dialog_test.dart
  fake_ai_forge_service.dart
  goldens/
  visual_preview_test.dart
  widget_test.dart

device_smoke_test.md          # manual device-smoke checklist
firebase.json
firestore.rules
firestore.indexes.json
```

### Data flow

```
Flutter UI
  -> dataService (service locator)
  -> WorldscribeDataService (abstract)
  -> InMemoryDataService  OR  FirestoreDataService

AI generation:
Flutter UI -> aiForgeService -> Cloud Function `generateCharacter`
  -> Gemini -> Firestore write -> returns payload
```

Important detail: the UI **reads synchronously** through `dataService`
(via `ListenableBuilder` on the data service as a `ChangeNotifier`),
but **writes are async**. That keeps screens simple while still
supporting Firestore round-trips. If Firebase init fails, the app falls
back to the in-memory store and shows a notice on the home screen.

### Form pattern (current contract for every editable form)

Every form route in the app — `CreateWorldScreen`, `AddCharacterSheet`,
`AddLocationSheet` — follows the same shape:

1. `final _formKey = GlobalKey<FormState>();`
2. `TextEditingController` per field, attached `_onChanged` listeners
   in `initState` (in edit mode, attach **after** pre-fill so dirty is
   false on entry).
3. `bool _isDirty = false;` updated by `_onChanged` → `_computeDirty`.
   - Add mode: dirty if any field has any non-blank text.
   - Edit mode: dirty if any field's trimmed value differs from the
     `initial` (or `_existingWorld`).
4. Wrapped in `PopScope(canPop: !_isDirty, onPopInvokedWithResult:
   _onPopRequested)`. `_onPopRequested` calls
   `confirmDiscardChanges(context)` and pops manually if the user
   confirms.
5. Validators come from `FormValidators` and length caps from
   `AppInput`. `counterText: ''` on InputDecoration so the counter chip
   stays hidden.
6. Submit sets `_isSaving = true`, validates, awaits the data-service
   call, then `Navigator.pop(resultId)` with the saved entity's id (or
   pushes a new dashboard for world creation). On error, shows a
   SnackBar from `AppStrings` and clears `_isSaving`.

When you add the next form (factions, lore, etc.), copy this shape
exactly. Anything new should slot in without inventing a new pattern.

### Firestore shape

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
            locationIds: [locationId, ...]   # M7a — typed ref to locations
        locations/
          {locationId}/
            name
            type
            description
            createdAt
            characterIds: [characterId, ...] # M7a — typed ref to characters
        factions/                          # M8a — CRUD only; relations land in M8b
          {factionId}/
            name
            ideology
            description
            createdAt
```

The two M7a arrays are denormalized — the same edge appears on both
sides. The data service is the only thing that writes them, and always
writes both sides in a single Firestore batch using
`FieldValue.arrayUnion` and `FieldValue.arrayRemove`. Treat them as
set-like (no duplicates). M8b will follow the same shape for
characters ↔ factions and locations ↔ factions: typed `<entity>Ids`
arrays on both ends, mutated through service-level link primitives.

Firestore rules cover any new subcollection automatically through the
recursive `match /{document=**}` rule under each user doc — no rules
edit was needed when factions were added, and no edit will be needed
for lore or any future module either.

---

## Firebase status

Project:

- Project ID: `worldscribe-9c753`
- Android app ID: `1:625579797661:android:25ede5575cbceea4a07874`
- iOS app ID: `1:625579797661:ios:dd176953c72ca3f4a07874`
- Web app ID: `1:625579797661:web:8a0b0a54084eb5f4a07874`

Done:

1. Anonymous Auth enabled
2. Firestore rules + indexes deployed (rules cover `characters/`,
   `locations/`, and `factions/` subcollections via the recursive
   `match /{document=**}` block, so future subcollections inherit the
   ownership check automatically)
3. Web app registered and wired into FlutterFire
4. Live browser smoke test passed

Remaining Firebase validation:

1. Smoke-test create/edit/delete world/character/location flows on
   Android or iOS hardware/emulator
2. Confirm platform builds don't unexpectedly fall back to the in-
   memory mock

Long-term auth note: Anonymous Auth is fine as a development bridge.
Once a real sign-in flow exists, decide whether guest accounts are still
worth supporting — if not, disable Anonymous Auth so the auth surface
stays tighter.

### AI Forge live deployment (postponed)

The `generateCharacter` Cloud Function code is in place but is **not
deployed live**. The secure path (Functions + Secret Manager-backed
Gemini key) requires Blaze billing on `worldscribe-9c753`, which is
intentionally deferred.

Do **not** work around this by shipping the Gemini key in the Flutter
app. The fake-service path is what the UI exercises in tests today;
that's enough to keep the UI honest until billing flips.

When ready:

1. `firebase functions:secrets:set GEMINI_API_KEY`
2. `firebase deploy --only functions:generateCharacter`
3. Smoke-test AI Forge against the live backend

---

## Risks and gaps

- Anonymous Auth is enabled (convenient for testing, expands long-term
  auth surface)
- Native (Android/iOS) device validation against live Firestore not yet
  done; web is verified
- AI Forge: Gemini path not live until secret is set + Function
  deployed (postponed pending Blaze)
- AI Forge today only generates characters — no locations/lore/factions
- Large world deletes batch-delete subcollections client-side; will
  need a server-side cleanup if worlds grow very large
- No real sign-in flow yet (anonymous only)

---

## Recommended next steps

Foreground (good next milestones — each fits the small-milestone rule):

1. **M8b — Faction relationships.** Add `factionIds` to `Character`
   and `Location`, add `characterIds` + `locationIds` to `Faction`,
   and introduce two new atomic primitives on the data service:
   `linkCharacterAndFaction` and `linkLocationAndFaction` (and their
   unlink twins). Mirror M7a end-to-end: idempotent links, Firestore
   batch with `FieldValue.arrayUnion` / `arrayRemove`, optimistic local
   cache + rollback, cascade-on-delete from any side. Add tests on
   both `InMemoryDataService` and `FirestoreDataService`.
2. **M8c — Faction UI.** List screen, detail screen, dual-mode add/edit
   sheet, and a dashboard tile that follows the existing pattern. The
   detail screen drops in two `LinkedEntitiesSection`s (characters,
   locations) reusing the M7b picker. No new picker or section widget
   should be needed.
3. **M9 — Lore notes** (free-form long-text entries scoped to a
   world). Same shape as factions but more description-heavy. Mentions
   of any other entity flow through the M7b picker.
4. **M10 — Real sign-in flow** — email + Google sign-in, with
   anonymous as guest fallback. Then revisit whether to disable
   Anonymous Auth.
5. **AI Forge expansion** — extend the `generateCharacter` callable
   shape to also support locations, factions, and lore, with the UI
   choosing which entity to forge.
6. **Native device smoke test** — run create/edit/delete world,
   character, location, and faction flows against live Firestore on
   Android + iOS, confirm no fallback to the mock store.

Background (quality / housekeeping):

- Add tests for location edit and location delete (currently location
  add and the discard-changes guard are covered; explicit edit + delete
  cases for locations would round out parity with characters).
- Consider an integration test that boots through `AppBootstrap` with
  `fake_cloud_firestore` to exercise the real wiring end-to-end.
- Revisit Anonymous Auth once a real sign-in flow exists.

When the project flips to Blaze:

- Set `GEMINI_API_KEY` secret, deploy `generateCharacter`, smoke-test
  AI Forge live, then start expanding AI Forge beyond characters.

---

## Conventions for the next agent

- **Follow the form pattern above** for any new editable form. Don't
  reinvent dirty tracking, discard prompts, or validator shapes.
- **Use `ConfirmDialog.show(...)`** for every destructive prompt
  (delete, discard, overwrite). Pass `isDestructive: true` when the
  action can't be undone.
- **Pull strings from `AppStrings`** and length caps from `AppInput`.
  If you need a new string or cap, add it to those files first, don't
  inline literals.
- **Pull validators from `FormValidators`**. New validation rules go
  there, not on the screen.
- **Read through the data service**, never directly through Firestore
  or `InMemoryDataService`. Use `dataService` from the service locator.
- **Small milestone rule**: ship one coherent change per commit. Run
  `flutter analyze` and `flutter test` before each commit. Push after
  every milestone.
- **Don't ship the Gemini key in Flutter.** Ever. Functions only.
- **Keep the in-memory fallback usable** — it is deliberate, supports
  offline dev, drives the test suite, and is the resilience path when
  Firebase init fails.

---

## Notes

- Current date for this handoff: 2026-04-26.
- Last shipped milestones (most recent first):
  - Faction CRUD on the data layer — `Faction` model, abstract methods
    on `WorldscribeDataService`, full implementations on both
    `InMemoryDataService` (with seeded mock factions per world) and
    `FirestoreDataService` (subscription, optimistic write + rollback,
    deleteWorld batch-cleanup of the new subcollection), 8 new tests
    (M8a, `301443d`)
  - Relationship UI — generic `EntityPickerSheet` and
    `LinkedEntitiesSection`, "Linked locations" on character detail and
    "Linked characters" on location detail, tap-to-navigate, tap-to-
    unlink, picker filters out already-linked entities (M7b, `7d9b408`)
  - Relationship data layer — bidirectional typed refs on Character /
    Location, atomic both-sides link/unlink primitive on the data service,
    cascade-delete on both ends, 10 new tests (M7a, `2c98446`)
  - Build verification + UI ↔ Firestore integration test + device
    smoke checklist (M6, `5fb496d`)
  - PopScope discard-changes guard across all forms (`620748c`)
  - Centralized destructive confirmations via `ConfirmDialog` (`d06d743`)
  - Input length caps + centralized form validators (`252d548`)
  - Character edit flow + unified detail scaffolding (`93ab7b9`)
  - Location detail screen with edit + delete (`a792a51`)
- 75 tests passing at handoff.
