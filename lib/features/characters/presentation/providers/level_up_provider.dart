import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../character_creation/domain/ability_score_rules.dart';
import '../../domain/character_class_feature.dart';
import '../../domain/character_failure.dart';
import '../../domain/level_up_block_reason.dart';
import '../../domain/level_up_choice_kind.dart';
import '../../domain/level_up_subclass_option.dart';
import '../../domain/spell_slot_change.dart';
import '../../domain/spell_slot_progression.dart';
import 'character_detail_provider.dart';
import 'character_providers.dart';

part 'level_up_provider.g.dart';

/// Données nécessaires pour afficher une étape du flux "Montée de niveau"
/// (`presentation/level_up_screen.dart`) pour un [characterId]/[targetLevel]
/// donnés.
///
/// Combine `characterDetailProvider` (classe primaire, modificateur de
/// Constitution, scores de caractéristiques, PV/XP actuels — déjà chargés
/// pour la fiche) et `CharacterRepository.fetchLevelUpLevelData`
/// (aptitudes/choix du niveau ciblé) — même pattern combinateur que les
/// `*StepData` de l'assistant de création
/// (`character_creation/presentation/providers/character_creation_providers.dart`).
typedef LevelUpStepData = ({
  Object classId,
  String className,
  int hitDie,
  int constitutionModifier,
  int currentLevel,
  int currentMaxHp,
  int currentXp,
  LevelUpBlockReason? blockReason,
  List<CharacterClassFeature> automaticFeatures,

  /// Type de choix à proposer à l'étape "Choix à faire" (increment 2),
  /// `null` si ce niveau n'en déclenche aucun (comportement de l'increment
  /// 1, inchangé) — toujours `null` quand [blockReason] est non nul (voir
  /// `domain/level_up_choice_kind.dart::LevelUpPendingChoiceResolver`,
  /// appelée seulement si [LevelUpBlockRules.evaluate] n'a pas bloqué).
  LevelUpChoiceKind? choiceKind,

  /// `class_features.id` de la ligne `choice_type` de ce niveau — voir
  /// `domain/level_up_level_data.dart::choiceClassFeatureId`. Pertinent
  /// seulement pour [LevelUpChoiceKind.fightingStyle]/
  /// [LevelUpChoiceKind.favoredEnemy].
  int? choiceClassFeatureId,

  /// Sous-classes disponibles à ce niveau — non vide seulement pour
  /// [LevelUpChoiceKind.subclass].
  List<LevelUpSubclassOption> availableSubclasses,

  /// Scores de caractéristiques actuels (`character_ability_scores`),
  /// nécessaires à l'étape "Choix à faire" variante
  /// [LevelUpChoiceKind.abilityScoreImprovement] (affichage "score actuel →
  /// nouveau score").
  Map<String, int> abilityScores,

  /// Changements de total d'emplacements de sorts déclenchés par ce niveau
  /// (increment 3, étape "Sorts") — voir
  /// `domain/spell_slot_progression.dart::SpellSlotProgression.changesFor`.
  /// Vide pour une classe non lanceuse ou l'Occultiste, indépendamment de
  /// [blockReason] (les classes "à sorts connus" bloquées avant même
  /// d'atteindre cette étape, voir `domain/level_up_block_reason.dart`, ont
  /// simplement cette liste jamais consultée par l'écran de blocage — la
  /// calculer quand même ici reste sans effet visible, plus simple que de la
  /// conditionner sur [blockReason]).
  List<SpellSlotChange> spellSlotChanges,
});

/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").
@Riverpod(retry: _noRetry)
Future<LevelUpStepData> levelUpStepData(
  Ref ref, {
  required String characterId,
  required int targetLevel,
}) async {
  final detail = await ref.watch(characterDetailProvider(characterId).future);
  final primaryClass = detail.primaryClass;
  if (primaryClass == null) {
    throw const CharacterFailure(
      'Aucune classe trouvée pour ce personnage : impossible de calculer '
      'la montée de niveau.',
    );
  }
  final hitDie = primaryClass.hitDie;
  if (hitDie == null) {
    // Voir le commentaire de `CharacterDetailClassRow.hitDie` : ce champ
    // alimente une écriture irréversible (PV/character_level_hp), donc on
    // refuse explicitement de démarrer plutôt que de deviner une valeur.
    throw const CharacterFailure(
      'Dé de vie introuvable pour la classe de ce personnage : impossible '
      'de calculer la montée de niveau.',
    );
  }

  final levelData = await ref
      .watch(characterRepositoryProvider)
      .fetchLevelUpLevelData(
        classId: primaryClass.classId,
        targetLevel: targetLevel,
      );

  // Peut lever une [CharacterFailure] (cas défensif "deux choix simultanés"
  // — voir sa documentation) : se propage naturellement comme n'importe
  // quelle autre erreur de ce provider `Future`.
  final blockReason = LevelUpBlockRules.evaluate(
    targetLevel: targetLevel,
    className: primaryClass.className,
    classFeatureChoiceType: levelData.choiceType,
  );

  // Seulement pertinent quand le flux n'est pas bloqué : `evaluate`
  // n'aurait pas laissé passer une valeur de `choiceType` que
  // [LevelUpPendingChoiceResolver.resolve] ne saurait pas mapper.
  final choiceKind = blockReason == null
      ? LevelUpPendingChoiceResolver.resolve(
          targetLevel: targetLevel,
          classFeatureChoiceType: levelData.choiceType,
        )
      : null;

  return (
    classId: primaryClass.classId,
    className: primaryClass.className,
    hitDie: hitDie,
    constitutionModifier: AbilityScoreRules.abilityModifier(
      detail.abilityScores['con'] ?? 10,
    ),
    currentLevel: detail.totalLevel,
    currentMaxHp: detail.maxHp,
    currentXp: detail.xp,
    blockReason: blockReason,
    automaticFeatures: levelData.automaticFeatures,
    choiceKind: choiceKind,
    choiceClassFeatureId: levelData.choiceClassFeatureId,
    availableSubclasses: levelData.availableSubclasses,
    abilityScores: detail.abilityScores,
    spellSlotChanges: SpellSlotProgression.changesFor(
      className: primaryClass.className,
      targetLevel: targetLevel,
    ),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
