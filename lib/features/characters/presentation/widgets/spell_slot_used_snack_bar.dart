import 'package:flutter/material.dart';

import '../../../../core/widgets/undo_snack_bar.dart';

/// Durée d'affichage du SnackBar « emplacement utilisé » (P9).
const Duration spellSlotUsedSnackBarDuration = undoSnackBarDuration;

/// Durée quand les services d'accessibilité sont actifs
/// (`MediaQuery.accessibleNavigation`) : 10 s minimum, le temps d'atteindre
/// l'action « Annuler » au lecteur d'écran.
const Duration spellSlotUsedSnackBarAccessibleDuration =
    undoSnackBarAccessibleDuration;

/// Affiche le SnackBar unique d'un lancer qui vient de consommer un
/// emplacement, avec l'action « Annuler » (P9). Remplace tout SnackBar déjà
/// affiché (`hideCurrentSnackBar`) : un seul à la fois, et seul le dernier
/// lancer est annulable.
///
/// [offlineMessage] non nul : le lancer a été mis en file hors ligne ; le
/// message « sera synchronisé » est fusionné dans ce même SnackBar plutôt
/// qu'affiché dans un second. [concentrationMessage] non nul (sort à
/// concentration, P3a) : ligne informative supplémentaire du même SnackBar ;
/// l'appelant l'inclut aussi dans [announcement].
///
/// Délègue à `showUndoSnackBar` (`core/widgets/undo_snack_bar.dart`), qui
/// porte le bouton « Annuler » maison et la garde anti-double appui.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
showSpellSlotUsedSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required String announcement,
  required VoidCallback onUndo,
  String? offlineMessage,
  String? concentrationMessage,
}) {
  return showUndoSnackBar(
    context,
    message: message,
    undoLabel: undoLabel,
    announcement: announcement,
    onUndo: onUndo,
    extraMessages: [?concentrationMessage, ?offlineMessage],
  );
}
