import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/spell_preparation_filter.dart';

/// Carte "PRÉPARATION DES SORTS" en tête de l'onglet "Sorts"
/// (`character_spells_tab_body.dart`), affichée dès qu'au moins un sort du
/// personnage se prépare — demande utilisateur du 06/10/2026 : regroupe la
/// note d'explication (icône ⓘ, voir [showSpellPreparationInfoSheet]), le
/// compteur "SORTS PRÉPARÉS X / Y" ([PreparedSpellsCounter]) et la bascule
/// de filtre "Tous"/"Préparés"/"Non préparés".
class SpellPreparationCard extends StatelessWidget {
  const SpellPreparationCard({
    required this.filter,
    required this.onFilterChanged,
    required this.preparedCount,
    this.preparedLimit,
    super.key,
  });

  final SpellPreparationFilter filter;
  final ValueChanged<SpellPreparationFilter> onFilterChanged;

  /// Nombre de sorts préparés par le joueur (`CharacterDetail
  /// .preparedSpellCount`, sorts mineurs et sorts accordés exclus).
  final int preparedCount;

  /// Limite de sorts préparés (`CharacterDetail.preparedSpellLimit`), `null`
  /// masque le compteur (classe à sorts connus, ou multiclassage de
  /// plusieurs classes qui préparent). Simple indicateur : n'empêche jamais
  /// de préparer un sort au-delà.
  final int? preparedLimit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PRÉPARATION DES SORTS',
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Comment fonctionne la préparation des sorts ?',
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.accentTeal,
                ),
                onPressed: () => showSpellPreparationInfoSheet(
                  context,
                  preparedLimit: preparedLimit,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.md - AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (preparedLimit != null) ...[
                  PreparedSpellsCounter(
                    count: preparedCount,
                    limit: preparedLimit!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SegmentedToggle<SpellPreparationFilter>(
                  options: [
                    for (final option in SpellPreparationFilter.values)
                      SegmentedToggleOption(value: option, label: option.label),
                  ],
                  value: filter,
                  onChanged: onFilterChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compteur "SORTS PRÉPARÉS X / Y" (classes qui préparent leurs sorts) :
/// libellé + décompte, jauge de remplissage, puis une phrase d'état ("Encore
/// N sort(s) à préparer"/"Limite atteinte"/"Limite dépassée de N"). Au-delà
/// de la limite, décompte, jauge et phrase passent en
/// [AppColors.accentBrick] : aucun blocage, simple signal.
class PreparedSpellsCounter extends StatelessWidget {
  const PreparedSpellsCounter({
    required this.count,
    required this.limit,
    super.key,
  });

  final int count;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final over = count > limit;
    final remaining = limit - count;
    final status = over
        ? 'Limite dépassée de ${-remaining}'
        : remaining == 0
        ? 'Limite atteinte'
        : 'Encore $remaining sort${remaining > 1 ? 's' : ''} à préparer';
    final accent = over ? AppColors.accentBrick : AppColors.textSecondary;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'Sorts préparés : $count sur $limit'
          '${over ? ', limite dépassée' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, size: 14, color: accent),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'SORTS PRÉPARÉS',
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$count / $limit',
                style: AppTypography.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: over ? AppColors.accentBrick : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.gaugeTrack,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.gaugeTrackBorder, width: 1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: limit <= 0 ? 1 : (count / limit).clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: over ? AppColors.accentBrick : null,
                  gradient: over ? null : AppColors.primaryButtonGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            status,
            style: AppTypography.body(
              fontSize: 11,
              fontWeight: over ? FontWeight.w700 : FontWeight.w400,
              color: over ? AppColors.accentBrick : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ouvre la note "PRÉPARATION DES SORTS" (icône ⓘ de
/// [SpellPreparationCard]) — gabarit B ([SheetHeaderBar] + contenu
/// scrollable, même patron que `spell_info_panel.dart`) : rappel de la règle
/// 5e et de ce que fait l'app, demande utilisateur du 06/10/2026.
/// [preparedLimit] : limite actuelle du personnage, rappelée dans la note si
/// non nulle.
Future<void> showSpellPreparationInfoSheet(
  BuildContext context, {
  int? preparedLimit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: 'PRÉPARATION DES SORTS'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _InfoEntry(
                        icon: Icons.bookmark,
                        title: 'Préparer pour lancer',
                        body:
                            'Seuls les sorts préparés peuvent être lancés. '
                            'Les sorts non préparés restent dans la liste, '
                            'grisés, après les sorts préparés. Touchez un '
                            'sort puis « Préparer ce sort » ou « Ne plus '
                            'préparer ».',
                      ),
                      _InfoEntry(
                        icon: Icons.format_list_numbered,
                        title: 'Combien de sorts ?',
                        body:
                            'Clerc, Druide et Magicien : modificateur de '
                            'caractéristique d\'incantation + niveau de '
                            'classe. Paladin : modificateur de Charisme + '
                            'moitié du niveau. Minimum 1.'
                            '${preparedLimit == null ? '' : ' Votre limite actuelle : $preparedLimit.'}'
                            ' Le compteur est indicatif : il signale un '
                            'dépassement sans le bloquer.',
                      ),
                      const _InfoEntry(
                        icon: Icons.auto_awesome,
                        title: 'Sans préparation',
                        body:
                            'Les sorts mineurs, les sorts innés et les sorts '
                            'de domaine ou de serment n\'ont jamais à être '
                            'préparés et ne comptent pas dans la limite. Un '
                            'sort inné de niveau 1 ou plus se lance sans '
                            'emplacement, une fois par repos long.',
                      ),
                      const _InfoEntry(
                        icon: Icons.local_fire_department,
                        title: 'Lancer ne dé-prépare pas',
                        body:
                            'Lancer un sort consomme un emplacement, mais le '
                            'sort reste préparé : vous pouvez le relancer '
                            'tant qu\'il vous reste des emplacements.',
                      ),
                      const _InfoEntry(
                        icon: Icons.hotel,
                        title: 'Changer sa liste',
                        body:
                            'La liste de sorts préparés se change après un '
                            'repos long : le repos long vous propose de '
                            'garder votre liste ou de la modifier.',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InfoEntry extends StatelessWidget {
  const _InfoEntry({
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentTeal),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  body,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
