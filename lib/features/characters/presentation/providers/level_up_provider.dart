import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../character_creation/domain/ability_score_rules.dart';
import '../../domain/character_class_feature.dart';
import '../../domain/character_failure.dart';
import '../../domain/level_up_block_reason.dart';
import 'character_detail_provider.dart';
import 'character_providers.dart';

part 'level_up_provider.g.dart';

/// Données nécessaires pour afficher une étape du flux "Montée de niveau"
/// (`presentation/level_up_screen.dart`) pour un [characterId]/[targetLevel]
/// donnés.
///
/// Combine `characterDetailProvider` (classe primaire, modificateur de
/// Constitution, PV/XP actuels — déjà chargés pour la fiche) et
/// `CharacterRepository.fetchLevelUpLevelData` (aptitudes/choix du niveau
/// ciblé) — même pattern combinateur que les `*StepData` de l'assistant de
/// création
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

  final blockReason = LevelUpBlockRules.evaluate(
    targetLevel: targetLevel,
    className: primaryClass.className,
    classFeatureChoiceType: levelData.blockingChoiceType,
  );

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
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
