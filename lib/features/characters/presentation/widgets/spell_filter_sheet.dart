import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/spell_list_filter.dart';
import '../../domain/spell_school.dart';
import 'spell_filter_labels.dart';

const double _minTapSize = 44;

/// Au-delà de cette taille de police, les deux boutons du pied de feuille
/// s'empilent (pleine largeur) : « RÉINITIALISER » en police pixel ×1,5 ne
/// tient pas sur une demi-largeur sans coupure de mot.
const double _stackedTextScale = 1.3;

/// Ouvre la feuille « Filtrer les sorts » (P4). [levels] et [schools] sont
/// les seules valeurs proposées (celles présentes parmi les sorts du
/// personnage) ; les valeurs déjà sélectionnées restent toujours proposées pour
/// pouvoir être retirées. Choix multiple : aucun tap de puce ne ferme la
/// feuille.
///
/// Retourne le nouveau filtre (« Appliquer »), ou `null` si la feuille est
/// fermée sans appliquer (croix, tap en dehors) : l'appelant ne change alors
/// rien.
Future<SpellListFilter?> showSpellFilterSheet(
  BuildContext context, {
  required SpellListFilter current,
  required List<int> levels,
  required List<SpellSchool> schools,
}) {
  return showModalBottomSheet<SpellListFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _SpellFilterSheetContent(
      initial: current,
      levels: ({...levels, ...current.levels}).toList()..sort(),
      schools: [
        for (final school in SpellSchool.values)
          if (schools.contains(school) || current.schools.contains(school))
            school,
      ],
    ),
  );
}

class _SpellFilterSheetContent extends StatefulWidget {
  const _SpellFilterSheetContent({
    required this.initial,
    required this.levels,
    required this.schools,
  });

  final SpellListFilter initial;
  final List<int> levels;
  final List<SpellSchool> schools;

  @override
  State<_SpellFilterSheetContent> createState() =>
      _SpellFilterSheetContentState();
}

class _SpellFilterSheetContentState extends State<_SpellFilterSheetContent> {
  late SpellListFilter _draft = widget.initial;

  void _toggleLevel(int level) {
    final levels = {..._draft.levels};
    if (!levels.remove(level)) levels.add(level);
    setState(() => _draft = _draft.copyWith(levels: levels));
  }

  void _toggleSchool(SpellSchool school) {
    final schools = {..._draft.schools};
    if (!schools.remove(school)) schools.add(school);
    setState(() => _draft = _draft.copyWith(schools: schools));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackedTextScale;
    final reset = SecondaryButton(
      label: l10n.spellFilterResetButton,
      surface: SecondaryButtonSurface.parchment,
      onPressed: _draft.isActive
          ? () => setState(() => _draft = SpellListFilter.none)
          : null,
    );
    final apply = PrimaryButton(
      label: _draft.isActive
          ? l10n.spellFilterApplyCountButton(_draft.activeCount)
          : l10n.spellFilterApplyButton,
      onPressed: () => Navigator.of(context).pop(_draft),
    );
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeaderBar(title: l10n.spellFilterSheetTitle),
            Flexible(
              child: SingleChildScrollView(
                key: const Key('spellFilterOptions'),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.levels.isNotEmpty) ...[
                      _SectionLabel(l10n.spellFilterLevelSection),
                      const SizedBox(height: AppSpacing.sm),
                      _ChipWrap(
                        children: [
                          for (final level in widget.levels)
                            _ChoiceChip(
                              key: ValueKey('spellFilterOption-level-$level'),
                              label: l10n.spellFilterLevelLabel(level),
                              selected: _draft.levels.contains(level),
                              onTap: () => _toggleLevel(level),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (widget.schools.isNotEmpty) ...[
                      _SectionLabel(l10n.spellFilterSchoolSection),
                      const SizedBox(height: AppSpacing.sm),
                      _ChipWrap(
                        children: [
                          for (final school in widget.schools)
                            _ChoiceChip(
                              key: ValueKey(
                                'spellFilterOption-school-${school.name}',
                              ),
                              label: l10n.spellFilterSchoolLabel(school),
                              selected: _draft.schools.contains(school),
                              onTap: () => _toggleSchool(school),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _SectionLabel(l10n.spellFilterConcentrationSection),
                    const SizedBox(height: AppSpacing.sm),
                    _ChipWrap(
                      children: [
                        for (final value in SpellConcentrationFilter.values)
                          _ChoiceChip(
                            key: ValueKey(
                              'spellFilterOption-concentration-${value.name}',
                            ),
                            label: l10n.spellFilterConcentrationLabel(value),
                            selected: _draft.concentration == value,
                            onTap: () => setState(
                              () => _draft = _draft.copyWith(
                                concentration: value,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        apply,
                        const SizedBox(height: AppSpacing.sm),
                        reset,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: reset),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: apply),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label,
        style: AppTypography.body(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children,
    );
  }
}

/// Puce de la feuille : sélectionnée = liseré `accentTeal` + coche `check`
/// (jamais la couleur seule). Libellé en corps 13 px minimum, jamais coupé :
/// la puce passe à la ligne entière dans le `Wrap`.
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: selected ? l10n.spellFilterSelectedSemanticLabel(label) : label,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: _minTapSize,
              minWidth: _minTapSize,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.parchmentCard,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: selected ? AppColors.accentTeal : AppColors.woodLight,
                width: AppBorders.card,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.accentTeal,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
}
