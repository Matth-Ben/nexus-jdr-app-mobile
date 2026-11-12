import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_add_tile.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../characters/domain/journal_entry_date_formatter.dart';
import '../../domain/group_failure.dart';
import '../../domain/group_note_entry.dart';
import '../providers/group_providers.dart';
import 'group_note_entry_edit_sheet.dart';
import '../group_failure_l10n.dart';

/// Contenu de l'onglet "Notes" de l'écran "Groupe" (demande utilisateur du
/// 16/09/2026, hors cahier des charges — carnet personnel pendant la partie,
/// jamais partagé avec les coéquipiers, voir `group_note_entry.dart`).
///
/// Fractionné en plusieurs entrées datées (une par étape/chapitre) à partir
/// du 07/11/2026 — remplace l'ancien `TextField` plein écran unique (texte
/// intégral collecté, transmis à l'écran "Groupe" pour écriture) par le
/// patron "tab = `ListView` pleine page" de `GroupTreasureTabBody` (pas de
/// carte imbriquée type `CharacterJournalCard`), et porte elle-même les
/// actions d'ajout/modification/suppression — même principe "`ConsumerWidget`
/// auto-suffisant" que `CharacterJournalCard`
/// (`features/characters/presentation/widgets/character_journal_card.dart`),
/// plutôt que l'orchestration habituelle de `group_screen.dart` (voir sa doc
/// de classe) : ce fractionnement calque délibérément l'architecture déjà
/// établie pour le journal de personnage plutôt que celle du reste de
/// l'écran "Groupe", décision de la spec direction-artistique de la tâche.
class GroupNotesTabBody extends ConsumerWidget {
  const GroupNotesTabBody({
    required this.groupId,
    required this.entries,
    super.key,
  });

  final String groupId;
  final List<GroupNoteEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (entries.isEmpty)
          const _EmptyNotesState()
        else
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.gaugeTrack,
              ),
            _GroupNoteEntryRow(
              entry: entries[i],
              onTap: () => _openActions(context, ref, entries[i]),
            ),
          ],
        const SizedBox(height: AppSpacing.sm),
        DashedAddTile(
          label: 'Ajouter une note',
          onTap: () => showGroupNoteEntryEditSheet(context, groupId: groupId),
        ),
      ],
    );
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    GroupNoteEntry entry,
  ) async {
    final action = await showModalBottomSheet<_GroupNoteEntryAction>(
      context: context,
      backgroundColor: AppColors.parchmentCard,
      builder: (sheetContext) => const _GroupNoteEntryActionSheetContent(),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _GroupNoteEntryAction.edit:
        await showGroupNoteEntryEditSheet(
          context,
          groupId: groupId,
          entry: entry,
        );
      case _GroupNoteEntryAction.remove:
        await _confirmAndRemove(context, ref, entry);
    }
  }

  Future<void> _confirmAndRemove(
    BuildContext context,
    WidgetRef ref,
    GroupNoteEntry entry,
  ) async {
    final confirmed = await showRemoveGroupNoteEntryConfirmationDialog(context);
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(groupRepositoryProvider).deleteGroupNoteEntry(entry.id);
      ref.invalidate(groupNoteEntriesProvider(groupId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Note supprimée.')));
    } on GroupFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.localized(context))));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer cette note. Réessayez.'),
        ),
      );
    }
  }
}

class _GroupNoteEntryRow extends StatelessWidget {
  const _GroupNoteEntryRow({required this.entry, required this.onTap});

  final GroupNoteEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = entry.title;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                JournalEntryDateFormatter.format(entry.createdAt),
                style: AppTypography.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(entry.body, style: AppTypography.body(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit_note_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucune note pour l\'instant.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

enum _GroupNoteEntryAction { edit, remove }

class _GroupNoteEntryActionSheetContent extends StatelessWidget {
  const _GroupNoteEntryActionSheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(
            icon: Icons.edit_outlined,
            label: 'Modifier',
            onTap: () => Navigator.of(context).pop(_GroupNoteEntryAction.edit),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.delete_outline,
            label: 'Supprimer',
            color: AppColors.accentBrick,
            onTap: () =>
                Navigator.of(context).pop(_GroupNoteEntryAction.remove),
          ),
        ],
      ),
    );
  }
}

/// Dialogue de confirmation "Supprimer cette note ?" — calque exact de
/// `character_journal_card.dart::showRemoveJournalEntryConfirmationDialog`.
Future<bool?> showRemoveGroupNoteEntryConfirmationDialog(BuildContext context) {
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
              'Supprimer cette note ?',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cette action est définitive.',
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
                  child: DestructiveButton(
                    label: 'Supprimer',
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
