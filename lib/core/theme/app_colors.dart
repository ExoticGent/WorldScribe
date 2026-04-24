import 'package:flutter/material.dart';

/// WorldScribe palette — a dark-fantasy journal:
/// ink-dark backgrounds, aged-parchment text, and gold/amber accents.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color ink = Color(0xFF0F0B1A); // near-black plum, app background
  static const Color midnight = Color(
    0xFF1A1428,
  ); // slightly lighter, scaffolds
  static const Color surface = Color(0xFF231A33); // cards / dialogs
  static const Color surfaceHigh = Color(0xFF2E2340); // elevated surfaces

  // Borders / dividers
  static const Color outline = Color(0xFF3E3252);
  static const Color outlineSoft = Color(0xFF2B2139);

  // Accents
  static const Color gold = Color(0xFFD9B382); // warm parchment-gold, primary
  static const Color goldDeep = Color(0xFFB08A55);
  static const Color emberRed = Color(0xFFB65445); // destructive / fire
  static const Color arcane = Color(0xFF9E7CC8); // secondary hint of magic

  // Text
  static const Color parchment = Color(0xFFE9DFCB); // primary text
  static const Color parchmentDim = Color(0xFFB7AC95); // secondary text
  static const Color parchmentFaint = Color(0xFF7A7166); // disabled / hint
}
