# Device Smoke Test

A minimal manual checklist for proving WorldScribe works end-to-end on a
real Android or iOS device against live Firestore. Run this any time
something in the bootstrap, data layer, or platform config changes.

The automated integration test
(`test/integration/firestore_app_test.dart`) already exercises the UI ↔
`FirestoreDataService` boundary against `fake_cloud_firestore`. This
checklist is the layer above that — it catches things only a real
device + real Firestore can catch: native build config drift, FlutterFire
init issues, rules deployments that didn't go through, wrong API key
tier, etc.

Time budget: ~10 minutes per platform.

## Prereqs

- An Android device or emulator running API 24+ (or an iOS device /
  simulator on macOS).
- The Firebase project `worldscribe-9c753` is configured for the
  platform (`google-services.json` for Android, `GoogleService-Info.plist`
  for iOS — both already in the repo).
- Anonymous Auth is enabled in the Firebase console.
- Firestore rules deployed (`firebase deploy --only firestore:rules`).
- A network connection.

## Run

```bash
flutter run -d <device_id>
```

If you skip `-d` and only one device is connected, Flutter picks it.

## Checklist — first launch

- [ ] App opens on the splash screen with the WorldScribe wordmark.
- [ ] Splash transitions to the Home screen ("Your Worlds") within a
      few seconds.
- [ ] **No "Running in mock-data mode" notice appears at the top of
      Home.** If it does, Firebase failed to bootstrap — check the logs
      for the `Firebase bootstrap failed.` message. This is the most
      important assertion in the whole test: it proves the device is
      really talking to Firestore, not falling back to the mock.
- [ ] If the account is brand new, Home shows the "No worlds yet" empty
      state with the "Tap the quill to scribe your first world." hint.

## Checklist — write path (creates Firestore docs)

- [ ] Tap the FAB ("New World"). The "Forge a New World" form opens.
- [ ] Enter `Smoke Test World` / `Test genre` / a one-line description.
- [ ] Tap "Create World." App lands on the dashboard with that name in
      the app bar.
- [ ] Open the Firebase console → Firestore → `users/{uid}/worlds/`.
      The new world doc exists with the right name, genre, description.
- [ ] On the dashboard, open the Characters tile. Tap "+" / FAB. Add a
      character (`Smoke Char` / `Tester`). Save.
- [ ] In the Firebase console, the character doc exists at
      `users/{uid}/worlds/{worldId}/characters/{characterId}`.
- [ ] Back to the dashboard, open Locations. Add a location
      (`Smoke Place` / `Town`). Save.
- [ ] Location doc exists at `users/{uid}/worlds/{worldId}/locations/`.

## Checklist — edit + delete

- [ ] Open the character. Use the overflow menu → Edit. Change the
      name. Save. Console shows the updated name.
- [ ] Same flow for a location. Console reflects the edit.
- [ ] From the world dashboard's overflow menu, delete the world.
- [ ] Console: the world doc is gone, and so are its `characters/`
      and `locations/` subcollections (the in-app delete batches the
      subcollection cleanup).

## Checklist — second launch (live snapshot path)

- [ ] Kill the app. Reopen it.
- [ ] Home shows the worlds you didn't delete (loaded from the live
      Firestore snapshot, not from local cache only).
- [ ] Make a write from the Firebase console (e.g. add a world doc by
      hand). Within a few seconds, that world appears in the app's home
      list without a manual refresh — proves the snapshot listener is
      live.

## What to do if anything fails

- **Mock-data notice on Home, can't reach Firestore.** Check
  `Firebase.initializeApp` logs — usually a missing or stale platform
  config file. On Android, regenerate `google-services.json` from the
  Firebase console; on iOS, regenerate `GoogleService-Info.plist`.
- **Sign-in fails.** Confirm Anonymous Auth is enabled in the Firebase
  console. The bootstrap log will print the auth error.
- **Reads succeed but writes fail.** Almost always Firestore rules.
  `firebase deploy --only firestore:rules` and recheck. Rules need to
  cover both the world doc AND the `characters/` + `locations/`
  subcollections.
- **"Could not load some characters from Firebase."** A snapshot stream
  errored. Check the device logs (`flutter logs`) for the exact
  Firestore error — usually a missing index or a rules denial.

## When to re-run this checklist

- After upgrading FlutterFire packages.
- After changing anything in `lib/services/app_bootstrap.dart`,
  `lib/services/firestore_data_service.dart`, or `firebase_options.dart`.
- After modifying `firestore.rules` or `firestore.indexes.json`.
- Before any user-facing release.
