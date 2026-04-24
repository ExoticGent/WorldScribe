import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/constants/app_strings.dart';
import '../firebase_options.dart';
import 'firestore_data_service.dart';
import 'in_memory_data_service.dart';
import 'service_locator.dart';
import 'worldscribe_data_service.dart';

class AppBootstrapResult {
  const AppBootstrapResult({
    required this.dataService,
    required this.mode,
    this.notice,
  });

  final WorldscribeDataService dataService;
  final DataServiceMode mode;
  final String? notice;
}

/// Boots the data layer.
///
/// If Firebase is configured for the current platform, the app signs in
/// anonymously and switches to the Firestore-backed service. If not, the
/// app falls back to the seeded in-memory mock so local development and
/// tests still work without secrets or platform config.
class AppBootstrap {
  AppBootstrap._();

  static Future<AppBootstrapResult> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      var user = FirebaseAuth.instance.currentUser;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (user == null) {
        throw StateError('Firebase sign-in completed without a user.');
      }

      final service = FirestoreDataService(
        firestore: FirebaseFirestore.instance,
        userId: user.uid,
      );
      await service.initialize();

      return AppBootstrapResult(
        dataService: service,
        mode: DataServiceMode.firestore,
      );
    } catch (error, stackTrace) {
      debugPrint('Firebase bootstrap failed. Falling back to mock data.');
      debugPrintStack(stackTrace: stackTrace);

      final service = InMemoryDataService.instance;
      await service.initialize();

      return AppBootstrapResult(
        dataService: service,
        mode: DataServiceMode.inMemory,
        notice: AppStrings.backendFallbackNotice,
      );
    }
  }
}
