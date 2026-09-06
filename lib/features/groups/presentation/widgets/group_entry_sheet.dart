import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/group_summary.dart';

enum GroupEntryAction { create, join }

/// Sheet "GROUPE" — point d'entrée du bouton "groupes" de
/// `character_list_screen.dart` quand le joueur n'est membre d'aucun groupe
/// (`docs/cahier-des-charges/12-partage-et-groupes.md` section 2) : 2
/// boutons "Créer un groupe"/"Rejoindre un groupe", l'appelant orchestre la
/// navigation (même principe que `pickInventoryAddition` : cette sheet
/// retourne le choix, jamais elle-même la navigation).
Future<GroupEntryAction?> showGroupEntrySheet(BuildContext context) {
  return showModalBottomSheet<GroupEntryAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _GroupEntrySheetContent(),
  );
}

class _GroupEntrySheetContent extends StatelessWidget {
  const _GroupEntrySheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeaderBar(title: 'GROUPE'),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Créer un groupe',
                    onPressed: () =>
                        Navigator.of(context).pop(GroupEntryAction.create),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Rejoindre un groupe',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () =>
                        Navigator.of(context).pop(GroupEntryAction.join),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet listant les groupes du joueur connecté (2+ groupes) — voir la spec
/// de la tâche : "sheet listant les groupes (nom + '{n} membres') avant
/// navigation". Retourne l'identifiant du groupe choisi, `null` si annulée.
Future<String?> showGroupListSheet(
  BuildContext context,
  List<GroupSummary> groups,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _GroupListSheetContent(groups: groups),
  );
}

class _GroupListSheetContent extends StatelessWidget {
  const _GroupListSheetContent({required this.groups});

  final List<GroupSummary> groups;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: 'GROUPES'),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _GroupSummaryRow(
                      group: group,
                      onTap: () => Navigator.of(context).pop(group.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupSummaryRow extends StatelessWidget {
  const _GroupSummaryRow({required this.group, required this.onTap});

  final GroupSummary group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.memberCount} membres',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
