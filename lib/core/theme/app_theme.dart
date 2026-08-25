import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Thème Material de "Nexus JDR — Personnages", assemblé à partir des tokens
/// de `docs/cahier-des-charges/10-design-system.md`.
///
/// Ce thème couvre le rendu "par défaut" des écrans (fond parchemin, champs
/// de formulaire, bouton Material standard). Les écrans "scène" (connexion,
/// liste des personnages, récapitulatifs ponctuels — voir section 6 du
/// design système) posent leur propre fond dégradé par-dessus via
/// `SceneScaffold` (`core/widgets/scene_scaffold.dart`) plutôt que de passer
/// par `scaffoldBackgroundColor`. De même, le bouton primaire "dégradé or"
/// exact de la maquette est un composant dédié (`core/widgets/primary_button.dart`)
/// plutôt qu'un `ElevatedButton` : `ButtonStyle` ne supporte pas nativement
/// un fond en dégradé, `elevatedButtonTheme` ci-dessous reste le style de
/// secours pour tout `ElevatedButton` Material générique.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.goldEnd,
      primary: AppColors.goldEnd,
      onPrimary: AppColors.woodDark,
      secondary: AppColors.woodMedium,
      onSecondary: AppColors.textOnWood,
      surface: AppColors.parchmentCard,
      onSurface: AppColors.textPrimary,
      error: AppColors.accentBrick,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(
        color: AppColors.woodLight,
        width: AppBorders.card,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.parchmentBg,
      textTheme: AppTypography.textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.parchmentCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        constraints: const BoxConstraints(minHeight: 44),
        hintStyle: AppTypography.body(color: AppColors.textMuted),
        errorMaxLines: 2,
        errorStyle: AppTypography.body(
          fontSize: 12,
          color: AppColors.accentBrick,
          fontWeight: FontWeight.w600,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.woodMedium,
            width: AppBorders.card,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.accentBrick,
            width: AppBorders.card,
          ),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.accentBrick,
            width: AppBorders.card,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldEnd,
          foregroundColor: AppColors.woodDark,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          textStyle: AppTypography.display(
            fontSize: 11,
            color: AppColors.woodDark,
          ),
        ),
      ),
    );
  }
}
