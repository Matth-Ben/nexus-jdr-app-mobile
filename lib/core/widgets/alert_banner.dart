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
/// Non interactif par défaut (pas d'`InkWell`, pas de zone de tap) ; avec
/// [onDismiss] (tranche T2 du chantier hors-ligne, alertes de synchro), un
/// bouton de fermeture `Icons.close` de 44x44 apparaît à droite (aucune
/// nouvelle couleur). L'icône d'avertissement est alignée en haut du texte,
/// pour les messages sur plusieurs lignes.
class AlertBanner extends StatelessWidget {
  const AlertBanner({
    required this.message,
    this.onDismiss,
    this.dismissTooltip,
    this.semanticsMessage,
    super.key,
  });

  final String message;

  /// Si non nul, affiche le bouton de fermeture.
  final VoidCallback? onDismiss;

  /// Info-bulle/libellé d'accessibilité du bouton de fermeture (localisé par
  /// l'appelant).
  final String? dismissTooltip;

  /// Texte lu par les technologies d'assistance quand il diffère de
  /// [message] (ex. nom abrégé à l'écran, complet pour le lecteur d'écran).
  /// `null` : [message] sert aux deux.
  final String? semanticsMessage;

  @override
  Widget build(BuildContext context) {
    final onDismiss = this.onDismiss;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: onDismiss == null ? AppSpacing.md : AppSpacing.xs,
        top: onDismiss == null ? AppSpacing.sm : AppSpacing.xs,
        bottom: onDismiss == null ? AppSpacing.sm : AppSpacing.xs,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppColors.accentBrick,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              // Centre le texte d'une ligne sur la zone de 44 dp du bouton.
              padding: EdgeInsets.symmetric(
                vertical: onDismiss == null ? 0 : AppSpacing.sm,
              ),
              child: Semantics(
                label: semanticsMessage,
                excludeSemantics: semanticsMessage != null,
                child: Text(
                  message,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (onDismiss != null)
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: dismissTooltip,
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
