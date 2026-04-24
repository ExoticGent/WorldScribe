import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Placeholder Firebase options.
///
/// Run `flutterfire configure` to replace this file with generated values
/// for the real Firebase project. Until then, bootstrap falls back to the
/// in-memory mock service.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase has not been configured for '
      '${_platformLabel(defaultTargetPlatform, isWeb: kIsWeb)} yet. '
      'Run flutterfire configure to generate lib/firebase_options.dart.',
    );
  }

  static String _platformLabel(TargetPlatform platform, {required bool isWeb}) {
    if (isWeb) return 'web';
    return switch (platform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
