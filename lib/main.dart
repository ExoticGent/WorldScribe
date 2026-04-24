import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'services/app_bootstrap.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  configureDataService(
    bootstrap.dataService,
    mode: bootstrap.mode,
    startupNotice: bootstrap.notice,
  );
  runApp(const WorldScribeApp());
}

class WorldScribeApp extends StatelessWidget {
  const WorldScribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generate,
    );
  }
}
