import 'level_up_block_reason.dart';

/// Les 4 types de choix couverts par l'étape "Choix à faire" de la montée de
/// niveau (increment 2, `presentation/level_up_screen.dart`) —
/// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 6,
/// point 3.
///
/// `invocation` (Occultiste niveau 2) reste hors périmètre (table
/// `invocations` vide en base) : pas de valeur d'énumération pour ce cas,
/// il continue de mener à l'écran de blocage existant, voir
/// `LevelUpBlockRules.evaluate`.
enum LevelUpChoiceKind {
  /// Répartition de 2 points entre caractéristiques (niveaux codés en dur
  /// `LevelUpBlockRules.abilityScoreImprovementLevels`) — l'alternative
  /// "don" est hors périmètre (table `feats` vide en base).
  abilityScoreImprovement,

  /// `class_features.choice_type == 'sous_classe'`.
  subclass,

  /// `class_features.choice_type == 'style_combat'`.
  fightingStyle,

  /// `class_features.choice_type == 'ennemi_jure'`.
  favoredEnemy,
}

/// Détermine le [LevelUpChoiceKind] applicable à un niveau ciblé donné, une
/// fois acquis qu'il n'est *pas* bloqué (`LevelUpBlockRules.evaluate` a déjà
/// renvoyé `null`, et n'a donc pas non plus levé de [CharacterFailure] pour
/// le cas défensif "deux choix simultanés" — voir sa documentation).
///
/// Fonction séparée de [LevelUpBlockRules.evaluate] plutôt que fusionnée
/// dedans : `evaluate` répond à la question "le flux est-il bloqué ?"
/// (renvoie une raison de blocage ou `null`), alors que ceci répond à la
/// question suivante, seulement pertinente une fois `evaluate` passé :
/// "si le flux n'est pas bloqué, quel choix (s'il y en a un) l'étape 3/4 doit-
/// elle proposer ?".
abstract final class LevelUpPendingChoiceResolver {
  static LevelUpChoiceKind? resolve({
    required int targetLevel,
    required String? classFeatureChoiceType,
  }) {
    if (classFeatureChoiceType != null &&
        LevelUpBlockRules.resolvedChoiceTypes.contains(
          classFeatureChoiceType,
        )) {
      return switch (classFeatureChoiceType) {
        'sous_classe' => LevelUpChoiceKind.subclass,
        'style_combat' => LevelUpChoiceKind.fightingStyle,
        'ennemi_jure' => LevelUpChoiceKind.favoredEnemy,
        // Ne devrait jamais arriver : `LevelUpBlockRules.resolvedChoiceTypes`
        // et ce `switch` doivent rester synchronisés (les 3 seules valeurs
        // qu'`evaluate` laisse passer sans bloquer).
        _ => throw StateError(
          'choice_type "$classFeatureChoiceType" déclaré résolu par '
          'LevelUpBlockRules.resolvedChoiceTypes mais non mappé par '
          'LevelUpPendingChoiceResolver.resolve — garder les deux en '
          'synchronisation.',
        ),
      };
    }

    if (LevelUpBlockRules.abilityScoreImprovementLevels.contains(targetLevel)) {
      return LevelUpChoiceKind.abilityScoreImprovement;
    }

    return null;
  }
}
