import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../character_creation/domain/ability_score_rules.dart';
import '../../../character_creation/domain/spell_catalog.dart';
import '../../../character_creation/presentation/providers/character_creation_providers.dart';
import '../../domain/character_class_feature.dart';
import '../../domain/character_failure.dart';
import '../../domain/invocations_known_progression.dart';
import '../../domain/level_up_block_reason.dart';
import '../../domain/level_up_choice_kind.dart';
import '../../domain/level_up_feat_option.dart';
import '../../domain/level_up_invocation_option.dart';
import '../../domain/level_up_multiclass_option.dart';
import '../../domain/level_up_subclass_option.dart';
import '../../domain/multiclass_prerequisites.dart';
import '../../domain/multiclass_proficiencies.dart';
import '../../domain/spell_slot_change.dart';
import '../../domain/spell_slot_progression.dart';
import '../../domain/spells_known_progression.dart';
import 'character_detail_provider.dart';
import 'character_providers.dart';

part 'level_up_provider.g.dart';

/// Données nécessaires pour afficher une étape du flux "Montée de niveau"
/// (`presentation/level_up_screen.dart`) pour un [characterId]/[targetLevel]
/// donnés, et éventuellement une classe de multiclassage choisie
/// ([multiclassClassId], voir la doc de [levelUpStepData]).
///
/// Combine `characterDetailProvider` (classes déjà possédées, modificateur de
/// Constitution, scores de caractéristiques, PV/XP actuels — déjà chargés
/// pour la fiche), `classCatalogProvider` (les 12 classes RAW, pour
/// déterminer les options de multiclassage) et
/// `CharacterRepository.fetchLevelUpLevelData` (aptitudes/choix du niveau
/// ciblé, pour la classe qui progresse effectivement ce niveau) — même
/// pattern combinateur que les `*StepData` de l'assistant de création.
typedef LevelUpStepData = ({
  /// Classe qui progresse CE niveau : la classe primaire si le joueur
  /// continue (`isMulticlassing == false`), ou la nouvelle classe choisie à
  /// l'étape `classDecision` sinon.
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

  /// Dons NON déjà possédés par le personnage — non vide seulement pour
  /// [LevelUpChoiceKind.abilityScoreImprovement] (sous-mode "don", voir
  /// `domain/level_up_choice_selection.dart::LevelUpChoiceSelection.featId`
  /// et la spec visuelle direction-artistique section 2 de
  /// `presentation/level_up_screen.dart`). Vide pour tout autre
  /// [choiceKind] (aucune requête réseau supplémentaire dans ce cas, voir
  /// `levelUpStepData`).
  List<LevelUpFeatOption> availableFeats,

  /// Scores de caractéristiques actuels (`character_ability_scores`),
  /// nécessaires à l'étape "Choix à faire" variante
  /// [LevelUpChoiceKind.abilityScoreImprovement] (affichage "score actuel →
  /// nouveau score").
  Map<String, int> abilityScores,

  /// Changements de total d'emplacements de sorts déclenchés par ce niveau
  /// (increment 3, étape "Sorts") — voir
  /// `domain/spell_slot_progression.dart::SpellSlotProgression.resolveChangesForLevelUp`
  /// (calcul combiné multiclasse dès que le personnage compte 2 classes
  /// lanceuses "non-pacte" après ce niveau, sinon comportement mono-classe
  /// historique inchangé). Vide pour une classe non lanceuse ou l'Occultiste,
  /// indépendamment de [blockReason].
  List<SpellSlotChange> spellSlotChanges,

  /// Classes actuellement possédées (au moins une des classes du personnage)
  /// éligibles au multiclassage à ce niveau — voir
  /// `domain/multiclass_prerequisites.dart`. Vide dans l'immense majorité des
  /// cas (aucune classe éligible), auquel cas la phase `classDecision` de
  /// l'écran reste invisible (voir spec direction-artistique section 1).
  /// Calculée indépendamment de [blockReason]/[choiceKind] (qui concernent
  /// uniquement la classe "continuée" par défaut).
  List<LevelUpMulticlassOption> multiclassOptions,

  /// `true` si ce niveau multiclasse dans une NOUVELLE classe plutôt que de
  /// continuer la classe primaire — déterminé par
  /// [multiclassClassId] passé à [levelUpStepData], pas par un champ dérivé
  /// des données de fiche.
  bool isMulticlassing,

  /// Nom de la nouvelle classe si [isMulticlassing], `null` sinon — redondant
  /// avec [className] dans la branche multiclasse (ajouté pour la clarté des
  /// sites d'appel de l'écran, ex. le bandeau `InfoBanner` "Nouvelle classe :
  /// $multiclassClassName (niveau 1)").
  String? multiclassClassName,

  /// Maîtrises accordées par le multiclassage dans [className] — non vide
  /// seulement si [isMulticlassing], voir
  /// `domain/multiclass_proficiencies.dart`.
  List<String> multiclassProficiencies,

  /// `true` si l'étape "Sorts" doit proposer une sélection de nouveaux
  /// sorts/cantrips connus — TOUTE montée de niveau (continuée ou
  /// multiclassée) d'une classe "à sorts connus" (Barde/Ensorceleur/
  /// Occultiste/Rôdeur) qui augmente le nombre de sorts et/ou de cantrips
  /// connus à ce niveau précis (voir
  /// `domain/spells_known_progression.dart::SpellsKnownProgression`).
  /// Couvrait uniquement le niveau 1 d'une nouvelle classe multiclassée
  /// avant ce chantier ("sorts/dons/invocations") — généralisé depuis, voir
  /// `domain/level_up_block_reason.dart` (ancienne condition de blocage
  /// "classes à sorts connus > niveau 1", supprimée). `false` pour toute
  /// classe non "à sorts connus" (préparée, ou non lanceuse), et pour tout
  /// niveau à delta nul (ex. Rôdeur niveau 1, RAW 5e sans aucun sort/
  /// emplacement à ce niveau).
  bool requiresSpellSelection,

  /// Catalogue de sorts de [className] pour la sélection — non nul
  /// seulement si [requiresSpellSelection]. Réutilise `character_creation`'s
  /// `spellCatalogProvider`/`SpellCatalog` (même catalogue que l'étape 6/9
  /// de l'assistant de création, TOUS niveaux de sort confondus — le filtre
  /// par niveau est fait côté écran), voir la doc de classe de ce fichier.
  SpellCatalog? spellSelectionCatalog,

  /// Nouveaux cantrips/sorts connus à ce niveau (deltas de
  /// [SpellsKnownProgression]) — 0 si [requiresSpellSelection] est `false`.
  int newCantripQuota,
  int newSpellQuota,

  /// Plus haut niveau de sort castable par [className] à ce niveau de
  /// classe (pour filtrer le catalogue de la section "Sorts" de l'étape —
  /// voir `domain/spell_slot_progression.dart::SpellSlotProgression.maxCastableSpellLevel`
  /// et [SpellSlotProgression.pactMagicFor] pour l'Occultiste), 0 si
  /// [requiresSpellSelection] est `false`.
  int maxCastableSpellLevel,

  /// `true` si l'étape "Invocations" doit être affichée à ce niveau —
  /// Occultiste uniquement, delta strictement positif de
  /// `domain/invocations_known_progression.dart::InvocationsKnownProgression`
  /// (niveaux 2, 5, 7, 9, 12, 15, 18 RAW). Indépendant de [choiceKind] : le
  /// `class_features.choice_type = 'invocation'` en base (niveau 2
  /// uniquement) ne mène plus à l'étape "Choix à faire" (voir
  /// `domain/level_up_choice_kind.dart::LevelUpPendingChoiceResolver`), cette
  /// étape dédiée couvre tous les niveaux concernés.
  bool requiresInvocationSelection,

  /// Invocations NON déjà connues du personnage — non vide seulement si
  /// [requiresInvocationSelection] (peut néanmoins être vide : personnage
  /// haut niveau ayant épuisé les 32 invocations en base, voir
  /// [invocationQuota]).
  List<LevelUpInvocationOption> availableInvocations,

  /// Quota EFFECTIF d'invocations à choisir à ce niveau — `min(delta RAW,
  /// availableInvocations.length)`, jamais le delta RAW brut (spec visuelle
  /// direction-artistique section 3 : l'app ne doit jamais promettre un
  /// quota qu'elle ne peut pas tenir). 0 si [requiresInvocationSelection] est
  /// `false`.
  int invocationQuota,
});

/// Options de multiclassage disponibles pour [detail] à cet instant — calcul
/// indépendant du niveau ciblé (les prérequis de caractéristiques ne
/// dépendent que des scores actuels, jamais du niveau) : une classe déjà
/// possédée est toujours exclue, et **aucune** classe n'est proposée si une
/// classe déjà possédée ne remplit plus elle-même son propre prérequis (cas
/// défensif "quitte une classe dont le prérequis n'est plus rempli" — spec
/// direction-artistique section 6.4).
List<LevelUpMulticlassOption> _computeMulticlassOptions({
  required List<({String className})> possessedClasses,
  required Map<String, int> abilityScores,
  required List<({Object id, String name})> allClasses,
}) {
  final allCurrentClassesEligible = possessedClasses.every(
    (c) => MulticlassPrerequisites.meetsRequirement(c.className, abilityScores),
  );
  if (!allCurrentClassesEligible) return const [];

  final possessedNames = {for (final c in possessedClasses) c.className};

  return [
    for (final option in allClasses)
      if (!possessedNames.contains(option.name))
        if (MulticlassPrerequisites.satisfiedAbilityIds(
              option.name,
              abilityScores,
            )
            case final satisfied when satisfied.isNotEmpty)
          LevelUpMulticlassOption(
            classId: option.id,
            className: option.name,
            satisfiedAbilityLabels: [
              for (final abilityId in satisfied) _abilityLabel(abilityId),
            ],
          ),
  ];
}

/// Libellé français d'une caractéristique depuis son `ability_id` — mapping
/// minimal dupliqué depuis `character_creation/domain/ability_score_definitions.dart`
/// (import direct évité pour ne pas tirer les icônes/couleurs Flutter dans ce
/// provider, qui n'en a pas besoin).
String _abilityLabel(String abilityId) => switch (abilityId) {
  'str' => 'Force',
  'dex' => 'Dextérité',
  'con' => 'Constitution',
  'int' => 'Intelligence',
  'wis' => 'Sagesse',
  'cha' => 'Charisme',
  _ => abilityId,
};

/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").
///
/// [multiclassClassId] : `null` (défaut) pour continuer la classe primaire
/// (comportement historique, avant le multiclassage) ; sinon, `classes.id`
/// de la classe choisie à l'étape `classDecision` pour multiclasser — doit
/// alors être un `classId` présent dans [LevelUpStepData.multiclassOptions]
/// calculé pour le même personnage, sans quoi une [CharacterFailure] est
/// levée (cas défensif : une classe qui a cessé d'être éligible entre
/// l'affichage de `classDecision` et cet appel, ex. un score de
/// caractéristique modifié entre-temps par un autre appareil).
@Riverpod(retry: _noRetry)
Future<LevelUpStepData> levelUpStepData(
  Ref ref, {
  required String characterId,
  required int targetLevel,
  Object? multiclassClassId,
}) async {
  final detail = await ref.watch(characterDetailProvider(characterId).future);
  final primaryClass = detail.primaryClass;
  if (primaryClass == null) {
    throw const CharacterFailure(
      'Aucune classe trouvée pour ce personnage : impossible de calculer '
      'la montée de niveau.',
    );
  }

  final classCatalog = await ref.watch(classCatalogProvider.future);
  final multiclassOptions = _computeMulticlassOptions(
    possessedClasses: [
      for (final row in detail.classes) (className: row.className),
    ],
    abilityScores: detail.abilityScores,
    allClasses: [
      for (final option in classCatalog.classes)
        (id: option.id, name: option.name),
    ],
  );

  final isMulticlassing = multiclassClassId != null;

  Object effectiveClassId;
  String effectiveClassName;
  int effectiveHitDie;
  int effectiveClassLevel;
  int effectiveTargetLevel;

  if (isMulticlassing) {
    final chosen = multiclassOptions.firstWhere(
      (option) => _sameClassId(option.classId, multiclassClassId),
      orElse: () => throw const CharacterFailure(
        'Cette classe ne peut plus être multiclassée (prérequis non rempli, '
        'ou déjà possédée) : revenez en arrière et choisissez à nouveau.',
      ),
    );
    final classOption = classCatalog.classes.firstWhere(
      (option) => _sameClassId(option.id, multiclassClassId),
      orElse: () => throw const CharacterFailure(
        'Classe de multiclassage introuvable dans le catalogue.',
      ),
    );
    effectiveClassId = chosen.classId;
    effectiveClassName = chosen.className;
    effectiveHitDie = classOption.hitDie;
    effectiveClassLevel = 0;
    effectiveTargetLevel = 1;
  } else {
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
    effectiveClassId = primaryClass.classId;
    effectiveClassName = primaryClass.className;
    effectiveHitDie = hitDie;
    // `primaryClass.level + 1`, jamais `targetLevel` (paramètre de ce
    // provider) : `targetLevel` est le niveau TOTAL du personnage + 1
    // (`_targetLevel` de l'écran = `currentTotalLevel + 1`), qui ne
    // correspond au véritable niveau suivant de la classe primaire QUE tant
    // qu'aucune classe secondaire n'existe. Dès qu'un multiclassage a eu
    // lieu (une classe secondaire au niveau 1 — le seul cas possible avec ce
    // chantier), `totalLevel = primaryClass.level + niveaux secondaires`,
    // donc `targetLevel` diverge du vrai niveau suivant de la primaire dès
    // la PROCHAINE montée de niveau — c'est le chemin de jeu normal après
    // tout multiclassage, pas un cas limite. `character_repository.dart`
    // (`applyLevelUp`) calcule lui-même `newClassLevel` depuis la vraie
    // ligne DB (`primaryClass.level + 1`) : utiliser la même source ici
    // garantit que les données affichées (blocage ASI, aptitudes,
    // sous-classes proposées) correspondent à ce qui sera réellement écrit.
    effectiveClassLevel = primaryClass.level;
    effectiveTargetLevel = primaryClass.level + 1;
  }

  final levelData = await ref
      .watch(characterRepositoryProvider)
      .fetchLevelUpLevelData(
        classId: effectiveClassId,
        targetLevel: effectiveTargetLevel,
      );

  // Peut lever une [CharacterFailure] (cas défensif "deux choix simultanés"
  // — voir sa documentation) : se propage naturellement comme n'importe
  // quelle autre erreur de ce provider `Future`. `effectiveTargetLevel` (le
  // niveau DANS la classe qui progresse, jamais `targetLevel` — le niveau
  // TOTAL du personnage) : voir la spec direction-artistique section 6.5,
  // sans quoi un niveau 1 de multiclassage produirait un message
  // RAW-incohérent ("Barbare niveau 6" alors que le choix bloqué concerne le
  // niveau 1 du Barbare).
  final blockReason = LevelUpBlockRules.evaluate(
    targetLevel: effectiveTargetLevel,
    className: effectiveClassName,
    classFeatureChoiceType: levelData.choiceType,
  );

  // Seulement pertinent quand le flux n'est pas bloqué : `evaluate`
  // n'aurait pas laissé passer une valeur de `choiceType` que
  // [LevelUpPendingChoiceResolver.resolve] ne saurait pas mapper.
  final choiceKind = blockReason == null
      ? LevelUpPendingChoiceResolver.resolve(
          targetLevel: effectiveTargetLevel,
          classFeatureChoiceType: levelData.choiceType,
        )
      : null;

  // Emplacements de sorts combinés — voir
  // `SpellSlotProgression.resolveChangesForLevelUp` : construit à partir de
  // TOUTES les classes du personnage, avant/après ce niveau.
  final beforeClasses = [
    for (final row in detail.classes)
      (className: row.className, level: row.level),
  ];
  final afterClasses = isMulticlassing
      ? [...beforeClasses, (className: effectiveClassName, level: 1)]
      : [
          // La classe primaire est toujours unique parmi les classes du
          // personnage (RAW : jamais deux lignes pour le même `class_id`) —
          // une comparaison par nom suffit donc à identifier la ligne qui
          // progresse ce niveau.
          for (final entry in beforeClasses)
            entry.className == effectiveClassName
                ? (className: effectiveClassName, level: effectiveTargetLevel)
                : entry,
        ];
  final spellSlotChanges = SpellSlotProgression.resolveChangesForLevelUp(
    beforeClasses: beforeClasses,
    afterClasses: afterClasses,
  );

  // Nouveaux sorts/cantrips connus à ce niveau — voir la doc de
  // [LevelUpStepData.requiresSpellSelection] : delta RAW de
  // `SpellsKnownProgression`, plus seulement pertinent pour le niveau 1
  // d'une nouvelle classe multiclassée (couvre désormais tout niveau > 1
  // d'une classe "à sorts connus" continuée).
  final newCantripQuota = SpellsKnownProgression.newCantripsAt(
    effectiveClassName,
    effectiveTargetLevel,
  );
  final newSpellQuota = SpellsKnownProgression.newSpellsKnownAt(
    effectiveClassName,
    effectiveTargetLevel,
  );
  final requiresSpellSelection = newCantripQuota > 0 || newSpellQuota > 0;
  SpellCatalog? spellSelectionCatalog;
  var maxCastableSpellLevel = 0;
  if (requiresSpellSelection) {
    spellSelectionCatalog = await ref.watch(
      spellCatalogProvider(classId: (effectiveClassId as num).toInt()).future,
    );
    // Magie de pacte de l'Occultiste : mécanisme séparé, jamais dans
    // `SpellSlotProgression.totalsForClasses` (voir sa documentation) — le
    // niveau de sort max castable est directement celui de la charge de
    // pacte à ce niveau de classe (jamais combiné avec d'autres classes,
    // RAW). Pour les 3 autres classes "à sorts connus" (non-pacte), réutilise
    // le total combiné déjà calculé ci-dessus pour [spellSlotChanges].
    maxCastableSpellLevel = effectiveClassName == 'Occultiste'
        ? (SpellSlotProgression.pactMagicFor(effectiveTargetLevel)?.slotLevel ??
              0)
        : SpellSlotProgression.maxCastableSpellLevel(
            SpellSlotProgression.totalsForClasses(afterClasses),
          );
  }

  // Invocations occultistes — étape "Invocations", indépendante de
  // [choiceKind] (voir `domain/level_up_block_reason.dart` et
  // `domain/level_up_choice_kind.dart::LevelUpPendingChoiceResolver`).
  final invocationDelta = effectiveClassName == 'Occultiste'
      ? InvocationsKnownProgression.newInvocationsAt(effectiveTargetLevel)
      : 0;
  final requiresInvocationSelection = invocationDelta > 0;
  var availableInvocations = const <LevelUpInvocationOption>[];
  var invocationQuota = 0;
  if (requiresInvocationSelection) {
    availableInvocations = await ref
        .watch(characterRepositoryProvider)
        .fetchAvailableInvocations(characterId: characterId);
    // Quota EFFECTIF (spec visuelle direction-artistique section 3) : jamais
    // le delta RAW brut, un personnage haut niveau peut avoir épuisé les 32
    // invocations peuplées en base.
    invocationQuota = invocationDelta < availableInvocations.length
        ? invocationDelta
        : availableInvocations.length;
  }

  // Dons — étape "Choix à faire", sous-mode "don" (voir
  // `domain/level_up_choice_selection.dart::LevelUpChoiceSelection.featId`) :
  // une seule requête réseau supplémentaire, uniquement quand ce niveau
  // déclenche effectivement le choix ASI-ou-don.
  final availableFeats = choiceKind == LevelUpChoiceKind.abilityScoreImprovement
      ? await ref
            .watch(characterRepositoryProvider)
            .fetchAvailableFeats(characterId: characterId)
      : const <LevelUpFeatOption>[];

  return (
    classId: effectiveClassId,
    className: effectiveClassName,
    hitDie: effectiveHitDie,
    constitutionModifier: AbilityScoreRules.abilityModifier(
      detail.abilityScores['con'] ?? 10,
    ),
    currentLevel: effectiveClassLevel,
    currentMaxHp: detail.maxHp,
    currentXp: detail.xp,
    blockReason: blockReason,
    automaticFeatures: levelData.automaticFeatures,
    choiceKind: choiceKind,
    choiceClassFeatureId: levelData.choiceClassFeatureId,
    availableSubclasses: levelData.availableSubclasses,
    availableFeats: availableFeats,
    abilityScores: detail.abilityScores,
    spellSlotChanges: spellSlotChanges,
    multiclassOptions: multiclassOptions,
    isMulticlassing: isMulticlassing,
    multiclassClassName: isMulticlassing ? effectiveClassName : null,
    multiclassProficiencies: isMulticlassing
        ? MulticlassProficiencies.multiclassProficienciesFor(effectiveClassName)
        : const <String>[],
    requiresSpellSelection: requiresSpellSelection,
    spellSelectionCatalog: spellSelectionCatalog,
    newCantripQuota: newCantripQuota,
    newSpellQuota: newSpellQuota,
    maxCastableSpellLevel: maxCastableSpellLevel,
    requiresInvocationSelection: requiresInvocationSelection,
    availableInvocations: availableInvocations,
    invocationQuota: invocationQuota,
  );
}

/// Compare deux `classId` (`Object`, toujours un entier côté Supabase en
/// pratique — voir `CharacterDetailClassRow.classId`) indépendamment de leur
/// type Dart exact (`int` vs `num`) : `==` structurel entre deux `Object`
/// numériques de types différents peut échouer même pour la même valeur
/// (ex. `1 == 1.0` vaut `true` en Dart, mais un id lu deux fois via des
/// chemins réseau différents pourrait varier) — normaliser en `int` avant de
/// comparer élimine ce risque.
bool _sameClassId(Object a, Object b) =>
    (a as num).toInt() == (b as num).toInt();

Duration? _noRetry(int retryCount, Object error) => null;
