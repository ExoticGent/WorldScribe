/// Named route paths for the app. Kept as string constants so every
/// navigator call refers to the same source of truth.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String createWorld = '/create-world';
  static const String editWorld = '/edit-world';
  static const String worldDashboard = '/world';
  static const String characters = '/world/characters';
  static const String locations = '/world/locations';
  static const String characterDetail = '/character';
  static const String locationDetail = '/location';
}
