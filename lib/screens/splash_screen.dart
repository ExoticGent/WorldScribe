import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';

/// Opening brand screen. Fades in the wordmark and tagline, then hands
/// off to [AppRoutes.home] after a short pause. The delay is purely
/// cosmetic — there is no async bootstrap work in the MVP yet.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration _holdDuration = Duration(milliseconds: 1800);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _navTimer = Timer(SplashScreen._holdDuration, _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ink, AppColors.midnight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _Crest(),
                  SizedBox(height: 28),
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    AppStrings.appTagline,
                    style: TextStyle(
                      color: AppColors.parchmentDim,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.goldDeep, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x33D9B382), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: const Icon(
        Icons.auto_stories_outlined,
        size: 48,
        color: AppColors.gold,
      ),
    );
  }
}
