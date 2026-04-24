import 'in_memory_data_service.dart';
import 'worldscribe_data_service.dart';

/// Tiny service locator for the app's data layer.
///
/// Screens depend on the abstraction: `import '.../service_locator.dart';`
/// and then read via the `dataService` top-level getter. The in-memory
/// mock is the default so the app runs without any Firebase config.
///
/// When wiring Firebase, call [configureDataService] once at startup
/// (inside `main()` after `Firebase.initializeApp()`) with a
/// `FirestoreDataService` instance. Screens need no changes.
WorldscribeDataService _current = InMemoryDataService.instance;
DataServiceMode _currentMode = DataServiceMode.inMemory;
String? _startupNotice;

enum DataServiceMode { inMemory, firestore }

WorldscribeDataService get dataService => _current;
DataServiceMode get dataServiceMode => _currentMode;
String? get dataServiceNotice => _startupNotice;

void configureDataService(
  WorldscribeDataService impl, {
  DataServiceMode mode = DataServiceMode.inMemory,
  String? startupNotice,
}) {
  _current = impl;
  _currentMode = mode;
  _startupNotice = startupNotice;
}
