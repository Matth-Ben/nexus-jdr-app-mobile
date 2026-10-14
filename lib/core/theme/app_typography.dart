import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographie de "Nexus JDR — Personnages" : tokens `font.display`
/// (Press Start 2P) et `font.body` (Work Sans) de
/// `docs/cahier-des-charges/10-design-system.md` section 2.
///
/// Règle stricte héritée de `08-direction-artistique.md` : `font.display` ne
/// sert jamais à afficher une valeur que le joueur doit lire vite en jeu (PV,
/// DD, montants) — réservé aux titres d'écran, titres de carte, labels de
/// navigation et boutons, toujours en majuscules. Cette classe ne transforme
/// pas la casse automatiquement : appeler `.toUpperCase()` sur le texte
/// affiché au moment de l'usage.
///
/// Choix technique : polices embarquées en asset (`assets/fonts/`, déclarées
/// dans `pubspec.yaml`), jamais téléchargées à l'exécution (dette D22,
/// `docs/dette-technique.md` — ce fichier utilisait auparavant le package
/// `google_fonts`, qui ne pouvait afficher correctement les polices au tout
/// premier lancement sans réseau). Licence SIL Open Font License 1.1 pour les
/// deux polices — voir `assets/fonts/OFL-*.txt` et l'écran "Crédits &
/// licences" (`features/profile/presentation/profile_credits_screen.dart`).
abstract final class AppTypography {
  static TextStyle display({
    required double fontSize,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0.5,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'PressStart2P',
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle body({
    double fontSize = 14,
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'WorkSans',
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// [TextTheme] Material construit à partir des deux tokens ci-dessus.
  ///
  /// Convention de mapping (à respecter pour tout nouvel écran plutôt que
  /// d'improviser un style ad hoc — les couleurs par défaut ci-dessous
  /// conviennent aux écrans "parchemin" ; sur fond "scène", surcharger la
  /// couleur via `.copyWith(color: AppColors.textOnWood)` au point d'usage) :
  /// - `headlineSmall`/`titleLarge`/`titleMedium`/`labelLarge` → `font.display`
  ///   (titres d'écran, titres de carte, boutons, labels de navigation).
  /// - `bodyLarge`/`bodyMedium`/`bodySmall` → `font.body` texte courant.
  /// - `titleSmall`/`labelMedium`/`labelSmall` → `font.body` en semi-gras
  ///   (labels de champ, valeurs importantes).
  static TextTheme get textTheme {
    return TextTheme(
      headlineSmall: display(fontSize: 15),
      titleLarge: display(fontSize: 13),
      titleMedium: display(fontSize: 11),
      titleSmall: body(fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: body(fontSize: 16),
      bodyMedium: body(fontSize: 14),
      bodySmall: body(fontSize: 12, color: AppColors.textMuted),
      labelLarge: display(fontSize: 11),
      labelMedium: body(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: body(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    );
  }
}
