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
  static const String editCharacterTitle = 'Edit Character';
  static const String saveCharacterChanges = 'Save Changes';
  static const String editCharacterAction = 'Edit character';
  static const String deleteCharacterAction = 'Delete character';
  static const String deleteCharacterPrompt =
      'This character will be removed from the world. This cannot be undone.';

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
  static const String editLocationTitle = 'Edit Location';
  static const String saveLocationChanges = 'Save Changes';
  static const String editLocationAction = 'Edit location';
  static const String deleteLocationAction = 'Delete location';
  static const String deleteLocationPrompt =
      'This location will be removed from the world. This cannot be undone.';

  // Factions
  static const String factionsTitle = 'Factions';
  static const String factionsEmpty = 'No factions yet.';
  static const String factionsEmptyHint =
      'Add a house, guild, cult, crew, or rival power to this world.';
  static const String newFaction = 'New Faction';
  static const String factionNameLabel = 'Name';
  static const String factionIdeologyLabel = 'Ideology';
  static const String factionIdeologyHint =
      'Creed, agenda, charter, or cause...';
  static const String factionDescriptionLabel = 'Description';
  static const String factionDescriptionHint =
      'Members, influence, secrets, rivals.';
  static const String saveFaction = 'Save Faction';
  static const String editFactionTitle = 'Edit Faction';
  static const String saveFactionChanges = 'Save Changes';
  static const String editFactionAction = 'Edit faction';
  static const String deleteFactionAction = 'Delete faction';
  static const String deleteFactionPrompt =
      'This faction will be removed from the world. This cannot be undone.';

  // Data / bootstrap
  static const String backendFallbackNotice =
      'Running in mock-data mode until Firebase is configured.';
  static const String loadingWorlds = 'Opening your archives...';
  static const String loadingWorld = 'Opening world...';
  static const String loadingCharacters = 'Gathering your cast...';
  static const String loadingLocations = 'Charting your map...';
  static const String loadingFactions = 'Summoning your powers...';
  static const String loadingCharacter = 'Opening character...';
  static const String loadingLocation = 'Opening location...';
  static const String loadingFaction = 'Opening faction...';
  static const String loadDataFailed = 'Unable to load your data right now.';
  static const String createWorldFailed =
      'Could not create the world. Try again.';
  static const String updateWorldFailed =
      'Could not update the world. Try again.';
  static const String deleteWorldFailed =
      'Could not delete the world. Try again.';
  static const String saveCharacterFailed =
      'Could not save the character. Try again.';
  static const String updateCharacterFailed =
      'Could not update the character. Try again.';
  static const String saveLocationFailed =
      'Could not save the location. Try again.';
  static const String updateLocationFailed =
      'Could not update the location. Try again.';
  static const String saveFactionFailed =
      'Could not save the faction. Try again.';
  static const String updateFactionFailed =
      'Could not update the faction. Try again.';
  static const String deleteFactionFailed =
      'Could not delete the faction. Try again.';
  static const String deleteLocationFailed =
      'Could not delete the location. Try again.';
  static const String deleteCharacterFailed =
      'Could not delete the character. Try again.';

  // Relationships (links between characters and locations)
  static const String linkedLocationsLabel = 'Linked locations';
  static const String linkedCharactersLabel = 'Linked characters';
  static const String linkLocationAction = 'Link a location';
  static const String linkCharacterAction = 'Link a character';
  static const String linkLocationTitle = 'Link a location';
  static const String linkCharacterTitle = 'Link a character';
  static const String noLocationsToLink =
      'All locations in this world are already linked.';
  static const String noCharactersToLink =
      'All characters in this world are already linked.';
  static const String noLocationsYet =
      'Add a location to this world to link it.';
  static const String noCharactersYet =
      'Add a character to this world to link it.';
  static const String linkFailed = 'Could not save the link. Try again.';
  static const String unlinkFailed = 'Could not remove the link. Try again.';
  static const String unlinkLocationTooltip = 'Unlink location';
  static const String unlinkCharacterTooltip = 'Unlink character';

  // Validation
  static const String requiredField = 'Required';

  // Form discard guard
  static const String discardChangesTitle = 'Discard changes?';
  static const String discardChangesMessage =
      'Your edits will be lost if you leave this page.';
  static const String discardChangesConfirm = 'Discard';
  static const String keepEditing = 'Keep editing';
}
