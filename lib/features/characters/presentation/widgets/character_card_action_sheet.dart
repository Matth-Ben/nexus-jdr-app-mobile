import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../character_creation/presentation/widgets/character_edit_flow.dart';
import '../../domain/character_failure.dart';
import '../../domain/character_summary.dart';
import '../../domain/write_outcome.dart';
import '../providers/character_providers.dart';
import 'character_delete_confirmation.dart';

/// Ouvre la sheet "Actions de personnage" (clic long sur une carte de
/// `character_list_screen.dart`, hors mode sélection) — même gabarit A que
/// `item_action_sheet.dart`/les sheets "Actions de sort"/"Actions
/// d'aptitude" : titre (nom du personnage), sous-titre (résumé "Race ·
/// Classe · Niv. X", copie exacte de `CharacterCard._summaryLine`), puis les
/// [SheetActionRow] "Modifier"/"Partager"/"Archiver"/"Marquer comme
/// mort"/"Supprimer".
///
/// Écart assumé par rapport à la signature suggérée par la spec de la tâche
/// (6 `VoidCallback` nommés, un par action) : "Modifier" doit appeler
/// `startCharacterEdit(context, ref, ...)`, et "Archiver"/"Marquer comme
/// mort"/"Supprimer" doivent appeler directement
/// `characterRepositoryProvider` avec la même gestion d'erreur (hors-ligne/
/// `CharacterFailure`/échec générique, `SnackBar`) que
/// `character_detail_screen.dart`. Aucune de ces deux choses n'est possible
/// derrière un simple `VoidCallback` (pas de `ref`, pas d'`async`/gestion
/// d'erreur) — cette fonction prend donc directement [WidgetRef] et porte
/// elle-même toute la logique des 5 actions, plutôt que de la déléguer à 6
/// callbacks que l'appelant aurait dû réimplémenter avec la même
/// duplication que ce fichier cherche justement à éviter.
Future<void> showCharacterCardActionSheet(
  BuildContext context,
  WidgetRef ref, {
  required CharacterSummary character,
}) async {
  final action = await showModalBottomSheet<_CardSheetAction>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (sheetContext) => _CardActionSheetContent(character: character),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _CardSheetAction.edit:
      await startCharacterEdit(context, ref, characterId: character.id);
    case _CardSheetAction.share:
      context.push('/characters/${character.id}/share');
    case _CardSheetAction.toggleArchived:
      await _toggleArchived(context, ref, character);
    case _CardSheetAction.toggleDead:
      await _toggleDead(context, ref, character);
    case _CardSheetAction.delete:
      await _delete(context, ref, character);
  }
}

/// Même message que `character_detail_screen.dart::_offlineNotPersistedMessage`
/// (privé à cette classe, donc dupliqué ici à l'identique plutôt
/// qu'importé) : un toggle/une suppression hors-ligne depuis cette sheet
/// n'est, comme depuis la fiche, jamais mis en file de synchro.
const _offlineNotPersistedMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

void _showSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Bascule `characters.is_archived` — même contrat que
/// `character_detail_screen.dart::_toggleArchived`.
Future<void> _toggleArchived(
  BuildContext context,
  WidgetRef ref,
  CharacterSummary character,
) async {
  try {
    final outcome = await ref
        .read(characterRepositoryProvider)
        .setArchived(
          characterId: character.id,
          isArchived: !character.isArchived,
        );
    if (!context.mounted) return;
    if (outcome == WriteOutcome.queued) {
      _showSnackBar(context, _offlineNotPersistedMessage);
      return;
    }
    ref.invalidate(charactersProvider);
  } on CharacterFailure catch (failure) {
    _showSnackBar(context, failure.message);
  } catch (_) {
    _showSnackBar(context, 'Impossible de mettre à jour le statut. Réessayez.');
  }
}

/// Bascule `characters.is_dead` — même contrat que
/// `character_detail_screen.dart::_toggleDead`.
Future<void> _toggleDead(
  BuildContext context,
  WidgetRef ref,
  CharacterSummary character,
) async {
  try {
    final outcome = await ref
        .read(characterRepositoryProvider)
        .setDead(characterId: character.id, isDead: !character.isDead);
    if (!context.mounted) return;
    if (outcome == WriteOutcome.queued) {
      _showSnackBar(context, _offlineNotPersistedMessage);
      return;
    }
    ref.invalidate(charactersProvider);
  } on CharacterFailure catch (failure) {
    _showSnackBar(context, failure.message);
  } catch (_) {
    _showSnackBar(context, 'Impossible de mettre à jour le statut. Réessayez.');
  }
}

/// Supprime définitivement le personnage — même contrat que
/// `character_detail_screen.dart::_deleteCharacter`, à la différence que
/// cet écran n'a jamais besoin de revenir en arrière (la liste affiche déjà
/// l'écran courant, il suffit de l'actualiser).
Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  CharacterSummary character,
) async {
  final confirmed = await showDeleteCharacterConfirmationDialog(
    context,
    characterName: character.name,
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final outcome = await ref
        .read(characterRepositoryProvider)
        .deleteCharacter(characterId: character.id);
    if (!context.mounted) return;
    if (outcome == WriteOutcome.queued) {
      _showSnackBar(context, _offlineNotPersistedMessage);
      return;
    }
    ref.invalidate(charactersProvider);
  } on CharacterFailure catch (failure) {
    _showSnackBar(context, failure.message);
  } catch (_) {
    _showSnackBar(context, 'Impossible de supprimer le personnage. Réessayez.');
  }
}

enum _CardSheetAction { edit, share, toggleArchived, toggleDead, delete }

class _CardActionSheetContent extends StatelessWidget {
  const _CardActionSheetContent({required this.character});

  final CharacterSummary character;

  /// Copie exacte de `CharacterCard._summaryLine` ("Race · Classe · Niv. X",
  /// segments non résolus omis) — dupliquée ici plutôt qu'extraite en
  /// fonction partagée : `_summaryLine` est une méthode privée de
  /// `CharacterCard`, sa logique est triviale (une jointure de 3 segments
  /// optionnels) et n'a pas d'autre appelant à ce jour.
  String _summaryLine(CharacterSummary character) {
    final segments = [
      if (character.raceName != null) character.raceName!,
      if (character.className != null) character.className!,
      'Niv. ${character.level}',
    ];
    return segments.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              character.name,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _summaryLine(character),
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0D2AB)),
            SheetActionRow(
              icon: Icons.edit_outlined,
              label: 'Modifier',
              onTap: () => Navigator.of(context).pop(_CardSheetAction.edit),
            ),
            SheetActionRow(
              icon: Icons.link,
              label: 'Partager',
              onTap: () => Navigator.of(context).pop(_CardSheetAction.share),
            ),
            SheetActionRow(
              icon: character.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
              label: character.isArchived
                  ? 'Désarchiver'
                  : 'Archiver ce personnage',
              onTap: () =>
                  Navigator.of(context).pop(_CardSheetAction.toggleArchived),
            ),
            SheetActionRow(
              icon: character.isDead ? Icons.mood : Icons.mood_bad,
              label: character.isDead ? 'Ressusciter' : 'Marquer comme mort',
              onTap: () =>
                  Navigator.of(context).pop(_CardSheetAction.toggleDead),
            ),
            const SheetActionDivider(),
            SheetActionRow(
              icon: Icons.delete_outline,
              label: 'Supprimer le personnage',
              color: AppColors.accentBrick,
              onTap: () => Navigator.of(context).pop(_CardSheetAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
