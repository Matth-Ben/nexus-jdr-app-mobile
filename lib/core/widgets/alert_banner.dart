import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Bandeau d'alerte inline" du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4) : fond
/// `#FDECE0`/`AppColors.alertBannerBackground`, bordure `accent.brick`,
/// icône d'avertissement — réservé aux erreurs/actions correctives, à ne pas
/// confondre avec le "Bandeau d'info inline" (`InfoBanner`, même document),
/// qui couvre l'information neutre (fond `parchment.card`, bordure
/// `gold-end`, icône `accent.teal`) et n'a explicitement pas pu réutiliser ce
/// token alerte.
///
/// Composant partagé (`core/widgets/`), extrait d'une classe privée
/// `_AlertBanner` dupliquée à l'identique dans 12 fichiers :
/// - `features/profile/presentation/widgets/change_password_sheet.dart`
/// - `features/profile/presentation/widgets/change_email_sheet.dart`
/// - `features/profile/presentation/widgets/avatar_crop_screen.dart`
/// - `features/profile/presentation/widgets/edit_display_name_sheet.dart`
/// - `features/profile/presentation/widgets/report_bug_sheet.dart`
/// - `features/characters/presentation/level_up_screen.dart`
/// - `features/characters/presentation/widgets/character_story_edit_sheet.dart`
/// - `features/xml_import/presentation/xml_import_review_screen.dart`
/// - `features/join_story/presentation/join_character_step_screen.dart`
/// - `features/character_creation/presentation/summary_step_screen.dart`
/// - `features/character_creation/presentation/equipment_step_screen.dart`
/// - `features/characters/presentation/widgets/portrait_crop_screen.dart`
///
/// Non interactif (pas d'`InkWell`, pas de zone de tap).
class AlertBanner extends StatelessWidget {
  const AlertBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.accentBrick,
          width: AppBorders.card,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentBrick,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
