// Tests unitaires de `core/theme/app_typography.dart` — vérifie que les
// tokens `font.display`/`font.body` référencent bien les familles de police
// embarquées (`PressStart2P`/`WorkSans`, déclarées dans `pubspec.yaml`,
// dette D22 de `docs/dette-technique.md`) plutôt qu'un chargement réseau à
// la volée (`google_fonts`, retiré), et que l'API publique (paramètres,
// valeurs par défaut) de ces deux méthodes n'a pas changé.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_typography.dart';

void main() {
  group('AppTypography.display', () {
    test('utilise la famille de police embarquée PressStart2P', () {
      final style = AppTypography.display(fontSize: 13);

      expect(style.fontFamily, 'PressStart2P');
    });

    test('applique les valeurs par défaut documentées', () {
      final style = AppTypography.display(fontSize: 13);

      expect(style.fontSize, 13);
      expect(style.color, AppColors.textPrimary);
      expect(style.letterSpacing, 0.5);
      expect(style.fontWeight, FontWeight.normal);
      expect(style.height, isNull);
    });

    test('transmet tous les paramètres explicites sans les altérer', () {
      final style = AppTypography.display(
        fontSize: 20,
        color: AppColors.textOnWood,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        height: 1.4,
      );

      expect(style.fontFamily, 'PressStart2P');
      expect(style.fontSize, 20);
      expect(style.color, AppColors.textOnWood);
      expect(style.letterSpacing, 1.2);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.height, 1.4);
    });
  });

  group('AppTypography.body', () {
    test('utilise la famille de police embarquée WorkSans', () {
      final style = AppTypography.body();

      expect(style.fontFamily, 'WorkSans');
    });

    test('applique les valeurs par défaut documentées', () {
      final style = AppTypography.body();

      expect(style.fontSize, 14);
      expect(style.color, AppColors.textPrimary);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.height, isNull);
    });

    test('transmet tous les paramètres explicites sans les altérer', () {
      final style = AppTypography.body(
        fontSize: 16,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w800,
        height: 1.5,
      );

      expect(style.fontFamily, 'WorkSans');
      expect(style.fontSize, 16);
      expect(style.color, AppColors.textMuted);
      expect(style.fontWeight, FontWeight.w800);
      expect(style.height, 1.5);
    });

    // Toutes les graisses réellement utilisées par `AppTypography.body(...)`
    // dans `lib/` (vérifiées par grep exhaustif) : chacune doit être
    // déclarée dans `pubspec.yaml` pour la famille `WorkSans`, faute de quoi
    // Flutter/Skia retomberait sur l'instance la plus proche de la police
    // variable plutôt que la graisse demandée.
    for (final weight in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
    ]) {
      test('accepte la graisse $weight', () {
        final style = AppTypography.body(fontWeight: weight);

        expect(style.fontWeight, weight);
      });
    }
  });

  group('AppTypography.textTheme', () {
    test('mappe chaque style Material sur la bonne famille de police', () {
      final textTheme = AppTypography.textTheme;

      for (final style in [
        textTheme.headlineSmall,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.labelLarge,
      ]) {
        expect(style?.fontFamily, 'PressStart2P');
      }
      for (final style in [
        textTheme.titleSmall,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
        textTheme.labelMedium,
        textTheme.labelSmall,
      ]) {
        expect(style?.fontFamily, 'WorkSans');
      }
    });
  });
}
