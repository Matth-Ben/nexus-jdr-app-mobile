import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../providers/character_creation_draft_provider.dart';
import '../providers/character_creation_return_route_provider.dart';

/// Orchestre l'abandon de la création en cours (icône croix du bandeau bois
/// de chaque écran d'étape) — voir `docs/cahier-des-charges/`
/// 11-fonctionnalites-a-ajouter.md, section "Création de personnage
/// (assistant pas-à-pas)" : "Annulation / abandon d'une création en cours
/// (suppression du brouillon)".
///
/// Confirme (voir [showAbandonCreationConfirmationDialog]), puis remet le
/// brouillon à zéro (`CharacterCreationDraftController.reset`, même méthode
/// déjà utilisée par `CharacterListScreen._startCreation` en filet de
/// sécurité avant une nouvelle création) et navigue vers la route de retour
/// posée par un éventuel sous-flux appelant ("Rejoindre une histoire"/
/// "Rejoindre un groupe", voir `CharacterCreationReturnRouteController`) —
/// exactement le même `context.go(returnRoute ?? '/')` que
/// `summary_step_screen.dart::_submit` à la création réussie, pour qu'un
/// abandon depuis ce sous-flux ramène l'utilisateur à son étape "Choix du
/// personnage" plutôt qu'à la liste des personnages.
Future<void> abandonCharacterCreation(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showAbandonCreationConfirmationDialog(context);
  if (confirmed != true || !context.mounted) return;

  ref.read(characterCreationDraftControllerProvider.notifier).reset();
  final returnRoute = ref
      .read(characterCreationReturnRouteControllerProvider.notifier)
      .consume();
  context.go(returnRoute ?? '/');
}

/// Dialogue de confirmation "Abandonner la création ?" — calque de
/// `groups/presentation/widgets/group_confirmation_dialog.dart`
/// (`showGroupConfirmationDialog`), dupliqué ici plutôt qu'importé
/// cross-feature (même principe de duplication systématique que le reste de
/// ce dépôt, voir `RaceRowMapper`) : un seul usage ici, pas besoin de la
/// généricité titre/message/libellé de la version "Groupe". Retourne `true`
/// si le joueur confirme, `false`/`null` sinon.
Future<bool?> showAbandonCreationConfirmationDialog(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abandonner la création ?',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Les choix déjà faits dans ce brouillon seront perdus. Cette '
              'action est définitive.',
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
                    label: 'Continuer',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DestructiveButton(
                    label: 'Abandonner',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
