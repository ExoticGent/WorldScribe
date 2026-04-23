/// App-wide user-visible strings. Centralized so localization is easy later.
class AppStrings {
  AppStrings._();

  static const String appName = 'WorldScribe';
  static const String appTagline = 'Chronicles of worlds unwritten.';

  // Home
  static const String homeTitle = 'Your Worlds';
  static const String homeEmpty = 'No worlds yet.';
  static const String homeEmptyHint =
      'Tap the quill to scribe your first world.';
  static const String newWorld = 'New World';

  // Create World
  static const String createWorldTitle = 'Forge a New World';
  static const String worldNameLabel = 'World name';
  static const String worldNameHint = 'e.g. Aerenthal, Kingdom of Ash…';
  static const String worldGenreLabel = 'Genre';
  static const String worldGenreHint = 'High fantasy, cyberpunk, post-apoc…';
  static const String worldDescriptionLabel = 'Description';
  static const String worldDescriptionHint =
      'A short pitch for this world — the feeling, the stakes, the era.';
  static const String createAction = 'Create World';

  // World Dashboard
  static const String charactersSection = 'Characters';
  static const String locationsSection = 'Locations';
  static const String factionsSection = 'Factions';
  static const String loreSection = 'Lore';
  static const String aiForge = 'AI Forge';
  static const String comingSoon = 'Coming soon';

  // Characters
  static const String charactersTitle = 'Characters';
  static const String charactersEmpty = 'No characters yet.';
  static const String charactersEmptyHint =
      'Add a hero, villain, or side-cast to this world.';
  static const String newCharacter = 'New Character';
  static const String characterNameLabel = 'Name';
  static const String characterRoleLabel = 'Role';
  static const String characterRoleHint = 'Hero, mentor, antagonist…';
  static const String characterDescriptionLabel = 'Description';
  static const String characterDescriptionHint =
      'Appearance, personality, motivation.';
  static const String saveCharacter = 'Save Character';

  // Validation
  static const String requiredField = 'Required';
}
