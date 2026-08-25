import 'package:flutter/material.dart';

/// Palette de couleurs de "Nexus JDR — Personnages", tokens issus de
/// `docs/cahier-des-charges/10-design-system.md` section 1.
///
/// Ne jamais coder une couleur en dur ailleurs dans l'app : passer par ces
/// constantes (ou par [AppTheme] pour les usages sémantiques Material comme
/// `colorScheme`/`textTheme`).
abstract final class AppColors {
  // Parchemin.
  static const Color parchmentBg = Color(0xFFF3E6C8);
  static const Color parchmentCard = Color(0xFFFBF3E0);
  static const Color parchmentCardAlt = Color(0xFFEADFC3);

  // Bois.
  static const Color woodDark = Color(0xFF3E2415);
  static const Color woodMedium = Color(0xFF6B4226);
  static const Color woodLight = Color(0xFF8A5A34);
  static const Color woodDeepBgStart = Color(0xFF241609);
  static const Color woodDeepBgEnd = Color(0xFF5A3C26);

  // Accents.
  static const Color goldStart = Color(0xFFE6B73A);
  static const Color goldEnd = Color(0xFFC9962C);
  static const Color accentBrick = Color(0xFFA13D2B);
  static const Color accentTeal = Color(0xFF3F7364);
  static const Color accentBlue = Color(0xFF5A7FA1);
  static const Color accentViolet = Color(0xFF7A6CA8);

  // Texte.
  static const Color textPrimary = Color(0xFF2B1A10);
  static const Color textSecondary = Color(0xFF6B4226);
  static const Color textMuted = Color(0xFF8A5A34);
  static const Color textOnWood = Color(0xFFF3E6C8);
  static const Color textOnWoodMuted = Color(0xFFD9C39A);

  // Jauge de PV.
  static const Color hpHealthyStart = Color(0xFF4D8A5F);
  static const Color hpHealthyEnd = Color(0xFF2F6B42);
  static const Color hpCautionStart = Color(0xFFD99A3E);
  static const Color hpCautionEnd = Color(0xFFB57A22);
  static const Color hpCriticalStart = Color(0xFFA13D2B);
  static const Color hpCriticalEnd = Color(0xFF7A2A1C);

  // Jauge (PV/XP) — piste commune aux deux jauges, voir design système
  // section 3 "Jauge (PV / XP)".
  static const Color gaugeTrack = Color(0xFFE0D2AB);
  static const Color gaugeTrackBorder = Color(0xFFA08862);

  // Bouton primaire : ombre portée basse ("effet pressable").
  static const Color primaryButtonShadow = Color(0xFF7A4D1F);

  /// Ombre portée diffuse de la carte personnage (voir design système
  /// section 4, composant "Carte personnage" : "... ombre portée diffuse.").
  /// La valeur exacte n'y est pas chiffrée ; extension raisonnable en
  /// attendant confirmation du design system, comme documenté pour
  /// [textOnWoodMuted] sur l'écran de connexion.
  static const Color cardDiffuseShadow = Color(0x33000000);

  /// Fond dégradé des écrans "scène" (voir section 6 du design système :
  /// connexion, liste des personnages, récapitulatifs ponctuels).
  static const LinearGradient sceneBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [woodDeepBgStart, woodDeepBgEnd],
  );

  /// Dégradé du bouton primaire (voir section 4 du design système).
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldStart, goldEnd],
  );
}
