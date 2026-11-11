import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'display_text.dart';

/// Durée d'affichage d'un SnackBar « Annuler ».
const Duration undoSnackBarDuration = Duration(seconds: 6);

/// Durée quand les services d'accessibilité sont actifs
/// (`MediaQuery.accessibleNavigation`) : 10 s minimum, le temps d'atteindre
/// l'action « Annuler » au lecteur d'écran.
const Duration undoSnackBarAccessibleDuration = Duration(seconds: 10);

/// Affiche un SnackBar unique avec l'action « Annuler » (patron P9, extrait
/// de `showSpellSlotUsedSnackBar` pour être réutilisé par l'annulation de
/// l'archivage d'un personnage, P18). Remplace tout SnackBar déjà affiché
/// (`hideCurrentSnackBar`) : un seul à la fois.
///
/// [extraMessages] : lignes informatives supplémentaires du même SnackBar
/// (l'appelant les inclut aussi dans [announcement]).
///
/// Le bouton « Annuler » est un contrôle maison (`DisplayText` palier
/// control, 44 px de haut minimum) plutôt qu'un `SnackBarAction`, dont le
/// libellé ne peut pas porter ce palier typographique. Garde « déjà
/// déclenché » : pendant l'animation de fermeture le bouton reste dans
/// l'arbre et cliquable, un second appui ne doit pas rappeler [onUndo].
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showUndoSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required String announcement,
  required VoidCallback onUndo,
  List<String> extraMessages = const [],
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final accessible = MediaQuery.accessibleNavigationOf(context);
  var undone = false;
  return messenger.showSnackBar(
    SnackBar(
      duration: accessible
          ? undoSnackBarAccessibleDuration
          : undoSnackBarDuration,
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
                for (final extra in extraMessages) Text(extra),
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
                if (undone) return;
                undone = true;
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
