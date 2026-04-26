/// Input length budgets used across every form in the app.
///
/// These caps protect Firestore (single-field and per-document size
/// ceilings, neighborhood of 1MB) and keep the UI honest about how
/// much text a single record is meant to hold. A description that
/// wants more than 4k characters is probably its own document, not
/// a field on a character or location.
class AppInput {
  AppInput._();

  /// Names of top-level entities: worlds, characters, locations, factions.
  static const int maxNameLength = 80;

  /// Short tag-style descriptors that sit below the name on a card:
  /// world genre, character role, location type, faction ideology.
  static const int maxTaglineLength = 60;

  /// Free-form long-form descriptions on every entity. Plenty of
  /// room for a few rich paragraphs without ever approaching the
  /// Firestore document size cap.
  static const int maxDescriptionLength = 4000;

  /// Prompt body sent to the AI Forge backend. Long enough for a
  /// detailed brief, short enough that the request stays cheap.
  static const int maxAiPromptLength = 1000;
}
