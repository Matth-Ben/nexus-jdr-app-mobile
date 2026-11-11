import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/display_text.dart';

/// Durée d'affichage du SnackBar « emplacement utilisé » (P9).
const Duration spellSlotUsedSnackBarDuration = Duration(seconds: 6);

/// Durée quand les services d'accessibilité sont actifs
/// (`MediaQuery.accessibleNavigation`) : 10 s minimum, le temps d'atteindre
/// l'action « Annuler » au lecteur d'écran.
const Duration spellSlotUsedSnackBarAccessibleDuration = Duration(seconds: 10);

/// Affiche le SnackBar unique d'un lancer qui vient de consommer un
/// emplacement, avec l'action « Annuler » (P9). Remplace tout SnackBar déjà
/// affiché (`hideCurrentSnackBar`) : un seul à la fois, et seul le dernier
/// lancer est annulable.
///
/// [offlineMessage] non nul : le lancer a été mis en file hors ligne ; le
/// message « sera synchronisé » est fusionné dans ce même SnackBar plutôt
/// qu'affiché dans un second.
///
/// Le bouton « Annuler » est un contrôle maison (`DisplayText` palier
/// control, 44 px de haut minimum) plutôt qu'un `SnackBarAction`, dont le
/// libellé ne peut pas porter ce palier typographique.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
showSpellSlotUsedSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required String announcement,
  required VoidCallback onUndo,
  String? offlineMessage,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final accessible = MediaQuery.accessibleNavigationOf(context);
  return messenger.showSnackBar(
    SnackBar(
      duration: accessible
          ? spellSlotUsedSnackBarAccessibleDuration
          : spellSlotUsedSnackBarDuration,
      content: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Annonce unique (liveRegion) : message + mention du bouton.
                Semantics(
                  liveRegion: true,
                  label: announcement,
                  excludeSemantics: true,
                  child: Text(message),
                ),
                if (offlineMessage != null) Text(offlineMessage),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: undoLabel,
            excludeSemantics: true,
            child: InkWell(
              onTap: () {
                messenger.hideCurrentSnackBar(
                  reason: SnackBarClosedReason.action,
                );
                onUndo();
              },
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Center(
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: DisplayText(
                      undoLabel.toUpperCase(),
                      tier: DisplayTier.control,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: AppTypography.display(
                        fontSize: 11,
                        color: AppColors.goldStart,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
