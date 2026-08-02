import 'package:flutter/material.dart';

/// Palette de couleurs de l'application.
///
/// IMPORTANT : `background`, `surface`, `textPrimary`, `textSecondary` et
/// `border` sont désormais des *getters dynamiques* qui suivent le mode
/// sombre (voir [isDark]), au lieu de constantes figées. C'est ce qui
/// permet au Dark Mode de s'appliquer réellement : fond noir + texte blanc
/// sur TOUTES les pages, et pas seulement sur l'écran Settings.
/// [isDark] est mis à jour par ThemeProvider à chaque bascule.
class AppColors {
  AppColors._();

  /// Reflète l'état actuel du mode sombre (mis à jour par ThemeProvider).
  static bool isDark = false;

  static const Color primary = Color(0xFF6C4BA6);
  static const Color primaryDark = Color(0xFF4C2E85);
  static const Color primaryLight = Color(0xFF8B6FC7);

  static const List<Color> primaryGradient = [
    Color(0xFF7B5CC7),
    Color(0xFF4C2E85),
  ];

  // --- Palette claire (valeurs de base) ---
  static const Color _backgroundLight = Color(0xFFF7F6FB);
  static const Color _surfaceLight = Colors.white;
  static const Color _textPrimaryLight = Color(0xFF1E1B2E);
  static const Color _textSecondaryLight = Color(0xFF8B8797);
  static const Color _borderLight = Color(0xFFE9E6F2);

  // --- Palette sombre ---
  static const Color darkBackground = Color(0xFF15131E);
  static const Color darkSurface = Color(0xFF201D2E);
  static const Color darkTextPrimary = Color(0xFFF2F0F7);
  static const Color darkTextSecondary = Color(0xFFA6A2B8);
  static const Color darkBorder = Color(0xFF352F49);

  // --- Couleurs dynamiques utilisées partout dans l'app ---
  static Color get background => isDark ? darkBackground : _backgroundLight;
  static Color get surface => isDark ? darkSurface : _surfaceLight;
  static Color get textPrimary => isDark ? darkTextPrimary : _textPrimaryLight;
  static Color get textSecondary => isDark ? darkTextSecondary : _textSecondaryLight;
  static Color get border => isDark ? darkBorder : _borderLight;

  static const Color work = Color(0xFF4A90E2);
  static const Color study = Color(0xFF3DBE64);
  static const Color meeting = Color(0xFFF2994A);
  static const Color personal = Color(0xFF9B6FE0);
  static const Color ideas = Color(0xFFF2C94C);
  static const Color others = Color(0xFF9AA0A6);
  static const Color formation = Color(0xFF00B8D9);
  static const Color development = Color(0xFF6C5CE7);
  static const Color laboratory = Color(0xFF00A896);
  static const Color debug = Color(0xFFE85C5C);

  static const Color success = Color(0xFF3DBE64);
  static const Color error = Color(0xFFE85C5C);
  static const Color star = Color(0xFFF2C94C);
}
