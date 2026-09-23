import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../characters/domain/spell_components_formatter.dart';
import '../../domain/spell_option.dart';

/// Panneau d'information d'un sort à l'étape 6/9 "Sorts" de l'assistant de
/// création (demande utilisateur, 2026-09-24 : pouvoir lire la description
/// d'un sort avant de le choisir), ouvert depuis le bouton ⓘ de chaque sort.
///
/// Lecture seule — même habillage que `showSpellInfoPanel` de la fiche
/// personnage (`characters/presentation/widgets/spell_info_panel.dart`),
/// sans ses actions (lancer, préparer) qui n'ont pas de sens avant la
/// création du personnage.
Future<void> showSpellOptionInfoSheet(
  BuildContext context, {
  required SpellOption spell,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SpellOptionInfoContent(spell: spell),
  );
}

class _SpellOptionInfoContent extends StatelessWidget {
  const _SpellOptionInfoContent({required this.spell});

  final SpellOption spell;

  @override
  Widget build(BuildContext context) {
    final components = SpellComponentsFormatter.format(spell.components);
    final levelLabel = spell.level == 0
        ? 'Sort mineur'
        : 'Sort de niveau ${spell.level}';
    final rows = <(String, String)>[
      ("Temps d'incantation", spell.castingTime),
      ('Portée', spell.range),
      (
        'Composantes',
        '${components.label}${components.materialDescriptionSuffix ?? ''}',
      ),
      ('Durée', spell.duration),
      ('Concentration', spell.concentration ? 'Oui' : 'Non'),
    ];

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(title: spell.name.toUpperCase()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spell.school.isEmpty
                            ? levelLabel
                            : '$levelLabel · ${spell.school}',
                        style: AppTypography.body(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (var i = 0; i < rows.length; i++) ...[
                        _InfoRow(label: rows[i].$1, value: rows[i].$2),
                        if (i < rows.length - 1) const SheetActionDivider(),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'DESCRIPTION',
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        spell.description.isEmpty
                            ? 'Description indisponible.'
                            : spell.description,
                        style: AppTypography.body(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTypography.body(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
