import 'level_up_block_reason.dart';

/// Les 4 types de choix couverts par l'étape "Choix à faire" de la montée de
/// niveau (increment 2, `presentation/level_up_screen.dart`) —
/// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 6,
/// point 3.
///
/// `invocation` (Occultiste, plusieurs niveaux) n'a volontairement PAS de
/// valeur d'énumération ici : couverte par la nouvelle étape "Invocations",
/// distincte de l'étape "Choix à faire" (voir
/// `presentation/level_up_screen.dart` et
/// `domain/invocations_known_progression.dart`) — [LevelUpPendingChoiceResolver]
/// renvoie `null` pour ce `choice_type` plutôt qu'un [LevelUpChoiceKind].
enum LevelUpChoiceKind {
  /// Répartition de 2 points entre caractéristiques (niveaux codés en dur
  /// `LevelUpBlockRules.abilityScoreImprovementLevels`), OU choix d'un don en
  /// alternative (même kind, voir
  /// `domain/level_up_choice_selection.dart::LevelUpChoiceSelection.featId`
  /// pour la distinction des deux sous-modes) — spec visuelle
  /// direction-artistique section 1 de `presentation/level_up_screen.dart`.
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
    // `'invocation'` est dans `resolvedChoiceTypes` (ne bloque plus le flux,
    // voir `LevelUpBlockRules.evaluate`) mais ne mène PAS à l'étape "Choix à
    // faire" : la nouvelle étape "Invocations" (dédiée, basée sur le delta de
    // `domain/invocations_known_progression.dart` à chaque niveau concerné,
    // pas seulement celui où cette ligne `class_features.choice_type` existe
    // en base) la couvre à la place — voir
    // `presentation/level_up_screen.dart`. Testée avant le `switch`
    // ci-dessous plutôt qu'incluse dedans, pour ne jamais confondre "aucun
    // choix à faire à cette étape" (retour `null`, cas normal) avec le
    // `StateError` défensif qui protège les 3 seules valeurs qui, elles,
    // doivent obligatoirement produire un [LevelUpChoiceKind].
    if (classFeatureChoiceType == 'invocation') {
      return null;
    }

    if (classFeatureChoiceType != null &&
        LevelUpBlockRules.resolvedChoiceTypes.contains(
          classFeatureChoiceType,
        )) {
      return switch (classFeatureChoiceType) {
        'sous_classe' => LevelUpChoiceKind.subclass,
        'style_combat' => LevelUpChoiceKind.fightingStyle,
        'ennemi_jure' => LevelUpChoiceKind.favoredEnemy,
        // Ne devrait jamais arriver : `LevelUpBlockRules.resolvedChoiceTypes`
        // et ce `switch` doivent rester synchronisés (les 3 seules valeurs,
        // hors `'invocation'` déjà exclue ci-dessus, qu'`evaluate` laisse
        // passer sans bloquer).
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
