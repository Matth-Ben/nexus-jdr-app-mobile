import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/character_detail.dart';
import '../../domain/proficiency_bonus.dart';
import '../../domain/skill_bonus_calculator.dart';
import 'character_class_features_card.dart';
import 'character_languages_card.dart';
import 'character_skills_card.dart';
import 'character_tool_proficiencies_card.dart';
import 'class_feature_action_sheet.dart';

/// Contenu de l'onglet "Compétences" de la fiche personnage — voir
/// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`, section
/// "Onglet Compétences".
///
/// Les sorts (aptitudes/emplacements) ont leur propre onglet "Sorts" — voir
/// `character_spells_tab_body.dart` — depuis la scission de cet onglet en 2.
///
/// [onUseFeature]/[actionsDisabled] délégués tels quels à
/// [CharacterClassFeaturesCard] — voir sa documentation de classe. Le reste
/// de l'onglet demeure en lecture seule.
class CharacterSkillsTabBody extends StatelessWidget {
  const CharacterSkillsTabBody({
    required this.detail,
    required this.onUseFeature,
    this.actionsDisabled = false,
    super.key,
  });

  final CharacterDetail detail;
  final UseClassFeatureCallback onUseFeature;
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    final proficiencyBonus = ProficiencyBonusRules.forTotalLevel(
      detail.totalLevel,
    );
    final skillResults = SkillBonusCalculator.computeAll(
      skills: detail.skills,
      abilityScores: detail.abilityScores,
      proficiencyBonus: proficiencyBonus,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (detail.classFeatures.isNotEmpty) ...[
          CharacterClassFeaturesCard(
            features: detail.classFeatures,
            onUseFeature: onUseFeature,
            actionsDisabled: actionsDisabled,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        CharacterSkillsCard(results: skillResults),
        if (detail.toolProficiencyNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterToolProficienciesCard(names: detail.toolProficiencyNames),
        ],
        if (detail.knownLanguageNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterLanguagesCard(names: detail.knownLanguageNames),
        ],
      ],
    );
  }
}
