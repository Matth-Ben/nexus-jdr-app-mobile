import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../domain/ability_score_definitions.dart';
import '../../domain/racial_bonus_choice.dart';

/// Répartition des bonus raciaux au choix à l'étape 4/9 (Demi-elfe,
/// Forgelier, races à bonus flexibles) — voir `domain/racial_bonus_choice.dart`.
///
/// Composant contrôlé : [choices] vient de l'écran, chaque modification est
/// remontée par [onChanged] (map complète, jamais modifiée en place).
class RacialBonusChoiceCard extends StatefulWidget {
  const RacialBonusChoiceCard({
    super.key,
    required this.spec,
    required this.choices,
    required this.onChanged,
  });

  final RacialBonusChoiceSpec spec;
  final Map<String, int> choices;
  final ValueChanged<Map<String, int>> onChanged;

  @override
  State<RacialBonusChoiceCard> createState() => _RacialBonusChoiceCardState();
}

enum _FlexiblePattern { twoOne, oneOneOne }

class _RacialBonusChoiceCardState extends State<RacialBonusChoiceCard> {
  late _FlexiblePattern _pattern;

  @override
  void initState() {
    super.initState();
    // Répartition +1/+1/+1 déjà faite (retour arrière) : on la retrouve.
    final values = widget.choices.values;
    _pattern = values.length == 3 && values.every((value) => value == 1)
        ? _FlexiblePattern.oneOneOne
        : _FlexiblePattern.twoOne;
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final complete = spec.isComplete(widget.choices);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: complete ? AppColors.woodMedium : AppColors.accentBrick,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonus racial au choix',
            style: AppTypography.body(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            complete ? spec.ruleLabel : '${spec.ruleLabel} — à répartir',
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...switch (spec) {
            OthersRacialBonusSpec() => _buildOthers(spec),
            FlexibleRacialBonusSpec() => _buildFlexible(),
          },
        ],
      ),
    );
  }

  List<Widget> _buildOthers(OthersRacialBonusSpec spec) {
    final full = widget.choices.length >= spec.count;
    return [
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final definition in abilityScoreDefinitions)
            _AbilityChip(
              label: '${definition.abbreviation} +${spec.amount}',
              selected: widget.choices.containsKey(definition.key),
              enabled:
                  !spec.excluded.contains(definition.key) &&
                  (widget.choices.containsKey(definition.key) || !full),
              onSelected: (selected) => widget.onChanged({
                for (final entry in widget.choices.entries)
                  if (entry.key != definition.key) entry.key: entry.value,
                if (selected) definition.key: spec.amount,
              }),
            ),
        ],
      ),
    ];
  }

  List<Widget> _buildFlexible() {
    return [
      SegmentedToggle<_FlexiblePattern>(
        options: const [
          SegmentedToggleOption(
            value: _FlexiblePattern.twoOne,
            label: '+2 / +1',
          ),
          SegmentedToggleOption(
            value: _FlexiblePattern.oneOneOne,
            label: '+1 / +1 / +1',
          ),
        ],
        value: _pattern,
        onChanged: (pattern) {
          if (pattern == _pattern) return;
          setState(() => _pattern = pattern);
          widget.onChanged(const {});
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      if (_pattern == _FlexiblePattern.twoOne) ...[
        _singleChoiceRow(bonus: 2, otherBonus: 1),
        const SizedBox(height: AppSpacing.xs),
        _singleChoiceRow(bonus: 1, otherBonus: 2),
      ] else
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final definition in abilityScoreDefinitions)
              _AbilityChip(
                label: '${definition.abbreviation} +1',
                selected: widget.choices.containsKey(definition.key),
                enabled:
                    widget.choices.containsKey(definition.key) ||
                    widget.choices.length < 3,
                onSelected: (selected) => widget.onChanged({
                  for (final entry in widget.choices.entries)
                    if (entry.key != definition.key) entry.key: entry.value,
                  if (selected) definition.key: 1,
                }),
              ),
          ],
        ),
    ];
  }

  /// Une ligne « +2 » ou « +1 » du motif +2/+1 : une seule caractéristique
  /// par ligne, différente de celle de l'autre ligne.
  Widget _singleChoiceRow({required int bonus, required int otherBonus}) {
    String? keyWith(int value) {
      for (final entry in widget.choices.entries) {
        if (entry.value == value) return entry.key;
      }
      return null;
    }

    final current = keyWith(bonus);
    final other = keyWith(otherBonus);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+$bonus',
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final definition in abilityScoreDefinitions)
                _AbilityChip(
                  label: definition.abbreviation,
                  selected: current == definition.key,
                  enabled: other != definition.key,
                  onSelected: (selected) => widget.onChanged({
                    ?other: otherBonus,
                    if (selected) definition.key: bonus,
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AbilityChip extends StatelessWidget {
  const _AbilityChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? onSelected : null,
      showCheckmark: false,
      selectedColor: AppColors.woodMedium,
      labelStyle: AppTypography.body(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.textOnWood : AppColors.textPrimary,
      ),
    );
  }
}
