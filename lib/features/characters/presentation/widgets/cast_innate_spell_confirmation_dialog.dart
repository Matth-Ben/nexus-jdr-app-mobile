import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/character_spell_entry.dart';

/// Dialogue de confirmation avant de lancer un sort inné à charge limitée
/// (`InnateSpellUsage.isLimited`, niveau >= 1) — décision utilisateur du
/// 09/10/2026 : jamais affichée pour un sort mineur inné à volonté (niveau 0)
/// ni pour un sort ordinaire (emplacement classique), ces deux cas restent
/// inchangés. Les deux points d'entrée sont `spell_action_sheet.dart
/// ::castSpellFlow` (route innée seule) et `spell_info_panel.dart
/// ::showSpellInfoPanel` (bouton "Lancer (sort inné)" d'un sort à double
/// route, D43).
///
/// Calque de `groups/presentation/widgets/group_confirmation_dialog.dart`
/// (`showGroupConfirmationDialog`), dupliqué ici plutôt qu'importé
/// cross-feature (même principe de duplication systématique que le reste de
/// ce dépôt — voir `character_creation/presentation/widgets/
/// abandon_creation_flow.dart::showAbandonCreationConfirmationDialog`, qui
/// duplique déjà ce même calque) : un seul usage ici, pas besoin de la
/// généricité titre/message/libellé de la version "Groupe". `PrimaryButton`
/// (pas `DestructiveButton`) : lancer un sort n'est pas une perte de donnée
/// irréversible, contrairement à quitter un groupe/abandonner une création.
/// Retourne `true` si le joueur confirme, `false`/`null` sinon.
Future<bool?> showCastInnateSpellConfirmationDialog(
  BuildContext context, {
  required CharacterSpellEntry spell,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.parchmentCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(
          color: AppColors.woodLight,
          width: AppBorders.card,
        ),
      ),
      // `SingleChildScrollView` autour de la colonne (absent du calque
      // dupliqué, `group_confirmation_dialog.dart`) : nécessaire ici parce
      // que le message, plus long que ceux des usages "Groupe", déborde du
      // `Dialog` (hauteur non bornée par défaut, pas de défilement intégré)
      // à grande échelle de texte sur petit écran — détecté par
      // `spell_info_panel_test.dart` (matrice 320x568/échelle 3.0), voir le
      // registre de dette technique si ce même défaut doit un jour être
      // corrigé sur le calque d'origine.
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lancer ${spell.name} ?',
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cette action consomme un usage de ce sort inné, récupéré '
                'seulement au prochain repos long.',
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Annuler',
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Lancer',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
