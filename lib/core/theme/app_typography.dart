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
  /// Plafond partagé d'agrandissement du texte, voir
  /// `docs/cahier-des-charges/10-design-system.md` section 7 (Accessibilité).
  /// Ne couvre PAS tout le texte de l'app : seulement un sous-arbre affiché dans
  /// un conteneur à taille contrainte qui ne peut pas grandir avec lui (titre
  /// borné en lignes, badge dans une ligne de largeur fixe, message sous un
  /// bouton de pied fixe). À utiliser via `MediaQuery.withClampedTextScaling(
  /// maxScaleFactor: AppTypography.maxTextScaleFactor, child: ...)` — jamais
  /// posé une fois pour toute l'app (romprait le redimensionnement libre du
  /// contenu défilant), ni comme substitut à un contenu qu'il faudrait plutôt
  /// rendre défilant.
  static const double maxTextScaleFactor = 2.0;

  /// Plafond de l'agrandissement du texte en police pixel [display] (titres et
  /// boutons), décision du 10/11/2026. Appliqué par `DisplayText` à son seul
  /// `Text`, jamais au sous-arbre ; le texte [body] n'est pas concerné.
  static const double maxDisplayScaleFactor = 1.3;

  /// Taille minimale (px, à x1,0) de la police pixel [display], décision du
  /// 10/11/2026. Partagée par le garde `display_usage_guard_test.dart` et par
  /// les mesures de mots en police pixel (dialogue d'import XML).
  static const double minDisplayFontSize = 11;

  /// Plafond du palier "control" de `DisplayText` (libellés de boutons,
  /// onglets, segments), décision du 10/11/2026 : x1,5, avec retour à la ligne
  /// autorisé et hauteur élastique du conteneur.
  static const double maxControlScaleFactor = 1.5;

  /// Plafond du texte [body] jumelé aux étiquettes display PV/XP de la carte
  /// de signes vitaux (x1,6), uniquement dans un conteneur de taille contrainte
  /// hors zone défilante, décision du 10/11/2026. Ne pas généraliser au corps.
  static const double maxVitalsValueScaleFactor = 1.6;

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
  /// - `headlineSmall`/`titleMedium`/`labelLarge` → `font.body` en gras
  ///   (titre de dialogue, menus, `TextButton`, chips) : un `ThemeData` ne peut
  ///   pas plafonner l'agrandissement du texte, donc tout style hérité par un
  ///   widget Material doit être en corps, qui grandit librement (décision du
  ///   10/11/2026, D192 PR 3).
  /// - `titleLarge` → `font.display` (titre d'AppBar). Aucun usage à ce jour ;
  ///   un `AppBar` qui l'hériterait devrait envelopper son titre dans un
  ///   `DisplayText` (plafonné) plutôt que laisser le `Text` brut.
  /// - `bodyLarge`/`bodyMedium`/`bodySmall` → `font.body` texte courant.
  /// - `titleSmall`/`labelMedium`/`labelSmall` → `font.body` en semi-gras
  ///   (labels de champ, valeurs importantes).
  static TextTheme get textTheme {
    return TextTheme(
      headlineSmall: body(fontSize: 17, fontWeight: FontWeight.w700),
      titleLarge: display(fontSize: 13),
      titleMedium: body(fontSize: 15, fontWeight: FontWeight.w700),
      titleSmall: body(fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: body(fontSize: 16),
      bodyMedium: body(fontSize: 14),
      bodySmall: body(fontSize: 12, color: AppColors.textMuted),
      labelLarge: body(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: body(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: body(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    );
  }
}
