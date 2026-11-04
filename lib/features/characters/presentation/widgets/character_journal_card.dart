import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_add_tile.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_journal_entry.dart';
import '../../domain/journal_entry_date_formatter.dart';
import '../../domain/write_outcome.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';
import 'character_journal_entry_edit_sheet.dart';

/// Carte "Journal de campagne" de l'onglet "Histoire" — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Histoire" : "Journal de campagne / notes de séance (distinct du
/// backstory figé)."
///
/// Toujours affichée, même sans aucune entrée — même rationale que
/// `CharacterGalleryCard` (la tuile "Ajouter une note" reste le seul moyen
/// de découvrir la fonctionnalité).
///
/// Une ligne par entrée (`CharacterDetail.journalEntries`, déjà triée du
/// plus récent au plus ancien — voir `CharacterDetailRowMapper
/// .parseJournalEntries`), séparées par un `Divider` — tap ouvre la sheet
/// d'actions "Modifier"/"Supprimer". `ConsumerWidget` auto-suffisant, même
/// principe que `CharacterAdventuresCard`/`CharacterGalleryCard`.
class CharacterJournalCard extends ConsumerWidget {
  const CharacterJournalCard({
    required this.detail,
    this.actionsDisabled = false,
    super.key,
  });

  final CharacterDetail detail;

  /// `true` sur la vue de partage en lecture seule — voir la documentation
  /// de `CharacterStoryTabBody.actionsDisabled`. Désactive la tuile
  /// "Ajouter une note" et le tap sur chaque ligne (aucune sheet d'actions
  /// "Modifier"/"Supprimer" à proposer à un lecteur anonyme) — le texte de
  /// chaque note reste visible tel quel, rien n'est masqué.
  final bool actionsDisabled;

  /// Même principe que `CharacterGalleryCard.hasVisibleContent`.
  static bool hasVisibleContent(
    CharacterDetail detail, {
    required bool actionsDisabled,
  }) => !actionsDisabled || detail.journalEntries.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entries = detail.journalEntries;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.characterJournalCardTitle,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.gaugeTrack,
                ),
              _JournalEntryRow(
                entry: entries[i],
                onTap: actionsDisabled
                    ? null
                    : () => _openActions(context, ref, entries[i]),
              ),
            ],
          ],
          if (!actionsDisabled) ...[
            const SizedBox(height: AppSpacing.sm),
            DashedAddTile(
              label: l10n.characterJournalCardAddButtonLabel,
              onTap: () =>
                  showJournalEntryEditSheet(context, characterId: detail.id),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    CharacterJournalEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<_JournalEntryAction>(
      context: context,
      backgroundColor: AppColors.parchmentCard,
      builder: (sheetContext) => _JournalEntryActionSheetContent(l10n: l10n),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _JournalEntryAction.edit:
        await showJournalEntryEditSheet(
          context,
          characterId: detail.id,
          entry: entry,
        );
      case _JournalEntryAction.remove:
        await _confirmAndRemove(context, ref, entry);
    }
  }

  Future<void> _confirmAndRemove(
    BuildContext context,
    WidgetRef ref,
    CharacterJournalEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showRemoveJournalEntryConfirmationDialog(context);
    if (confirmed != true || !context.mounted) return;

    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .removeJournalEntry(characterId: detail.id, entryId: entry.id);
      if (outcome == WriteOutcome.queued) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.characterOfflineNotPersistedMessage)),
        );
        return;
      }
      ref.invalidate(characterDetailProvider(detail.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.characterJournalCardRemovedMessage)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.characterJournalCardRemoveGenericErrorMessage),
        ),
      );
    }
  }
}

class _JournalEntryRow extends StatelessWidget {
  const _JournalEntryRow({required this.entry, required this.onTap});

  final CharacterJournalEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

enum _JournalEntryAction { edit, remove }

class _JournalEntryActionSheetContent extends StatelessWidget {
  const _JournalEntryActionSheetContent({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(
            icon: Icons.edit_outlined,
            label: l10n.characterJournalCardEditAction,
            onTap: () => Navigator.of(context).pop(_JournalEntryAction.edit),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.delete_outline,
            label: l10n.characterJournalCardRemoveAction,
            color: AppColors.accentBrick,
            onTap: () => Navigator.of(context).pop(_JournalEntryAction.remove),
          ),
        ],
      ),
    );
  }
}

/// Dialogue de confirmation "Supprimer cette note ?" — calque de
/// `item_action_sheet.dart::showRemoveInventoryItemConfirmationDialog`.
Future<bool?> showRemoveJournalEntryConfirmationDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
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
              l10n.characterJournalCardRemoveConfirmationTitle,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.characterJournalCardRemoveConfirmationMessage,
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
                    label:
                        l10n.characterJournalCardRemoveConfirmationCancelButton,
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DestructiveButton(
                    label: l10n
                        .characterJournalCardRemoveConfirmationConfirmButton,
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
