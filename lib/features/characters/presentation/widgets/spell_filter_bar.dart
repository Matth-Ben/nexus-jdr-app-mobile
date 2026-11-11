import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/spell_list_filter.dart';
import 'spell_filter_labels.dart';

/// Au-delà de cette taille de police, le bouton « Filtres » passe sous le
/// champ de recherche (pleine largeur) au lieu de rester à sa droite.
const double _stackedTextScale = 1.3;

const double _minTapSize = 44;

/// Ligne « champ de recherche + bouton Filtres » de l'onglet « Sorts ».
class SpellSearchRow extends StatelessWidget {
  const SpellSearchRow({
    required this.search,
    required this.filter,
    required this.onOpenFilters,
    super.key,
  });

  final Widget search;
  final SpellListFilter filter;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackedTextScale;
    final button = SpellFilterButton(
      count: filter.activeCount,
      onPressed: onOpenFilters,
      fullWidth: stacked,
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: AppSpacing.sm),
          button,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: AppSpacing.sm),
        button,
      ],
    );
  }
}

/// Bouton « Filtres » (icône `tune`), avec pastille du nombre de filtres
/// actifs. Le compte est aussi porté par le `Semantics`, la pastille seule
/// n'étant pas un moyen suffisant de le transmettre.
class SpellFilterButton extends StatelessWidget {
  const SpellFilterButton({
    required this.count,
    required this.onPressed,
    this.fullWidth = false,
    super.key,
  });

  final int count;
  final VoidCallback onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = count > 0
        ? l10n.spellFilterButtonActiveSemanticLabel(count)
        : l10n.spellFilterButtonLabel;
    final box = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.parchmentCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.woodLight,
                width: AppBorders.card,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                key: const Key('spellFilterButton'),
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onPressed,
                child: Center(
                  child: fullWidth
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tune,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                l10n.spellFilterButtonLabel,
                                style: AppTypography.body(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Icon(Icons.tune, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(top: -6, right: -6, child: _CountBadge(count: count)),
      ],
    );
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: fullWidth
          ? SizedBox(height: 48, width: double.infinity, child: box)
          : SizedBox(width: 48, height: 48, child: box),
    );
  }
}

/// Couleur du chiffre de la pastille : `parchmentCard` sur `accentTeal`
/// (contraste supérieur à 4,5:1, vérifié par un test).
const Color spellFilterBadgeTextColor = AppColors.parchmentCard;

/// Pastille de compteur : disque `accentTeal`, chiffre en corps 11 px minimum.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('spellFilterCountBadge'),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.accentTeal,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Text(
          '$count',
          style: AppTypography.body(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: spellFilterBadgeTextColor,
          ),
        ),
      ),
    );
  }
}

/// Ligne de puces récapitulatives des filtres actifs + « Tout effacer ».
/// Absente (aucun widget) quand aucun filtre n'est actif.
class SpellActiveFiltersRow extends StatelessWidget {
  const SpellActiveFiltersRow({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final SpellListFilter filter;
  final ValueChanged<SpellListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!filter.isActive) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final levels = filter.levels.toList()..sort();
    final schools = filter.schools.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final level in levels)
            _ActiveChip(
              key: ValueKey('spellActiveFilter-level-$level'),
              label: l10n.spellFilterLevelLabel(level),
              onRemove: () => onChanged(
                filter.copyWith(levels: {...filter.levels}..remove(level)),
              ),
            ),
          for (final school in schools)
            _ActiveChip(
              key: ValueKey('spellActiveFilter-school-${school.name}'),
              label: l10n.spellFilterSchoolLabel(school),
              onRemove: () => onChanged(
                filter.copyWith(schools: {...filter.schools}..remove(school)),
              ),
            ),
          if (filter.concentration != SpellConcentrationFilter.all)
            _ActiveChip(
              key: const ValueKey('spellActiveFilter-concentration'),
              label: l10n.spellFilterConcentrationLabel(filter.concentration),
              onRemove: () => onChanged(
                filter.copyWith(concentration: SpellConcentrationFilter.all),
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _minTapSize,
              minWidth: _minTapSize,
            ),
            child: TextButton(
              key: const Key('spellFilterClearAll'),
              onPressed: () => onChanged(SpellListFilter.none),
              child: Text(
                l10n.spellFilterClearAll,
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove, super.key});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: l10n.spellFilterRemoveSemanticLabel(label),
      onTap: onRemove,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onRemove,
          child: Container(
            constraints: const BoxConstraints(minHeight: _minTapSize),
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.parchmentCard,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.accentTeal,
                width: AppBorders.card,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(
                  width: _minTapSize - 12,
                  height: _minTapSize - 4,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
