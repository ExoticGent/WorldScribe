# WorldScribe

A mobile-first worldbuilding app for writers, game developers, and storytellers.

Create and manage **worlds**, **characters**, **locations**, **factions**, and **lore**.
AI-assisted generation is powered by the Gemini API via a secure backend.

See [`worldscribe_handover.md`](./worldscribe_handover.md) for the full project brief.

---

## Tech stack

- **Frontend**: Flutter (Android-first)
- **Backend**: Firebase (Auth, Firestore, Cloud Functions) — *planned*
- **AI**: Gemini API via Cloud Function — *planned*

---

## Project structure

```
lib/
  core/
    theme/        # app theme, colors, text styles
    constants/    # app-wide constants
  models/         # data models (World, Character, ...)
  screens/        # top-level screens
  widgets/        # shared UI widgets
  services/       # data + AI service layer
  main.dart
```

---

## Getting started

Requires Flutter 3.11+ (Dart 3.11+).

```bash
flutter pub get
flutter run
```

Run analysis and tests:

```bash
flutter analyze
flutter test
```

---

## MVP roadmap

1. Flutter project scaffolding + theme + navigation
2. Splash / Home / Create World / World Dashboard / Characters / Character Detail screens
3. In-memory mock data
4. Firebase (Auth + Firestore)
5. Gemini integration via Cloud Function

API keys are never shipped inside the Flutter app — all AI calls go through a backend.
