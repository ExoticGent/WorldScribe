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

  // Create / edit world
  static const String createWorldTitle = 'Forge a New World';
  static const String editWorldTitle = 'Revise World';
  static const String worldNameLabel = 'World name';
  static const String worldNameHint = 'e.g. Aerenthal, Kingdom of Ash...';
  static const String worldGenreLabel = 'Genre';
  static const String worldGenreHint = 'High fantasy, cyberpunk, post-apoc...';
  static const String worldDescriptionLabel = 'Description';
  static const String worldDescriptionHint =
      'A short pitch for this world - the feeling, the stakes, the era.';
  static const String createAction = 'Create World';
  static const String saveWorldChanges = 'Save Changes';
  static const String editWorldAction = 'Edit world';
  static const String deleteWorldAction = 'Delete world';
  static const String deleteWorldPrompt =
      'This world and all of its characters and locations will be removed. This cannot be undone.';

  // World Dashboard
  static const String charactersSection = 'Characters';
  static const String locationsSection = 'Locations';
  static const String factionsSection = 'Factions';
  static const String loreSection = 'Lore';
  static const String aiForge = 'AI Forge';
  static const String aiForgeTitle = 'AI Forge';
  static const String aiForgeIntro =
      'Describe the kind of character you want, and WorldScribe will add one directly to this world.';
  static const String aiForgePromptLabel = 'Prompt';
  static const String aiForgePromptHint =
      'e.g. A disgraced astronomer-priest who hears prophecies in whale song.';
  static const String aiForgeGenerateCharacter = 'Generate Character';
  static const String aiForgeUnavailableTitle = 'AI Forge unavailable';
  static const String aiForgeUnavailableNotice =
      'AI Forge needs the live Firebase + Cloud Functions backend before it can generate content.';
  static const String aiForgeUnavailableHint =
      'Deploy the generateCharacter function and keep Firebase enabled to use AI generation.';
  static const String aiForgePromptEmptyHint =
      'Tell AI Forge what kind of character to create.';
  static const String aiForgeFailed =
      'Could not forge a character right now. Try again.';
  static const String comingSoon = 'Coming soon';

  // Characters
  static const String charactersTitle = 'Characters';
  static const String charactersEmpty = 'No characters yet.';
  static const String charactersEmptyHint =
      'Add a hero, villain, or side-cast to this world.';
  static const String newCharacter = 'New Character';
  static const String characterNameLabel = 'Name';
  static const String characterRoleLabel = 'Role';
  static const String characterRoleHint = 'Hero, mentor, antagonist...';
  static const String characterDescriptionLabel = 'Description';
  static const String characterDescriptionHint =
      'Appearance, personality, motivation.';
  static const String saveCharacter = 'Save Character';

  // Locations
  static const String locationsTitle = 'Locations';
  static const String locationsEmpty = 'No locations yet.';
  static const String locationsEmptyHint =
      'Add a city, ruin, hideout, or landmark to ground this world.';
  static const String newLocation = 'New Location';
  static const String locationNameLabel = 'Name';
  static const String locationTypeLabel = 'Type';
  static const String locationTypeHint = 'City, ruin, district, fortress...';
  static const String locationDescriptionLabel = 'Description';
  static const String locationDescriptionHint =
      'What is it like here, and why does it matter?';
  static const String saveLocation = 'Save Location';

  // Data / bootstrap
  static const String backendFallbackNotice =
      'Running in mock-data mode until Firebase is configured.';
  static const String loadingWorlds = 'Opening your archives...';
  static const String loadingWorld = 'Opening world...';
  static const String loadingCharacters = 'Gathering your cast...';
  static const String loadingLocations = 'Charting your map...';
  static const String loadingCharacter = 'Opening character...';
  static const String loadDataFailed = 'Unable to load your data right now.';
  static const String createWorldFailed =
      'Could not create the world. Try again.';
  static const String updateWorldFailed =
      'Could not update the world. Try again.';
  static const String deleteWorldFailed =
      'Could not delete the world. Try again.';
  static const String saveCharacterFailed =
      'Could not save the character. Try again.';
  static const String saveLocationFailed =
      'Could not save the location. Try again.';
  static const String deleteCharacterFailed =
      'Could not delete the character. Try again.';

  // Validation
  static const String requiredField = 'Required';
}
