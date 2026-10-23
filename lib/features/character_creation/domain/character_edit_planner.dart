import 'dart:math' as math;

import '../../../core/rules/spell_status.dart';
import 'ability_score_rules.dart';
import 'background_option.dart';
import 'character_creation_draft.dart';
import 'character_edit_snapshot.dart';
import 'class_choice_rules.dart';
import 'class_option.dart';
import 'hit_points_calculator.dart';
import 'language_catalog.dart';
import 'language_selection_resolver.dart';
import 'skill_catalog.dart';
import 'skill_proficiency_resolver.dart';
import 'spell_catalog.dart';
import 'spell_selection_resolver.dart';
import 'tool_catalog.dart';
import 'tool_proficiency_resolver.dart';

typedef ToolRow = ({int? toolId, String? customText});

/// Choix nommé de CLASSE (Style de combat/Ennemi juré) à écrire dans
/// `character_class_options` — correctif D102 (`docs/dette-technique.md`).
/// `CharacterEditRepository.save` résout lui-même `class_feature_id` au
/// moment de l'écriture (même requête `class_features` que
/// `CharacterCreationRepository.createCharacter` : `class_id` +
/// `level = 1` + `choice_type`), jamais mis en cache ici — une classe sans
/// ligne `class_features` correspondante (cas défensif) n'écrit simplement
/// rien.
typedef ClassFeatureChoiceWrite = ({
  int classId,
  String choiceType,
  String chosenValue,
});

/// Second choix de niveau 1 propre à la SOUS-CLASSE (ex. Ancêtre draconique)
/// à écrire — correctif D102, même rationale que [ClassFeatureChoiceWrite] :
/// `CharacterEditRepository.save` résout `class_feature_id` via
/// `subclass_id` + `level = 1` + `choice_type` non nul ET différent de
/// `'sous_classe'` (même requête que `createCharacter`).
typedef SubclassFeatureChoiceWrite = ({int subclassId, String chosenValue});

/// Lignes d'Expertise du Roublard (compétence(s) + éventuellement la
/// substitution outils de voleur, RAW 2014 uniquement) à écrire — correctif
/// D102, même rationale que [ClassFeatureChoiceWrite] :
/// `CharacterEditRepository.save` résout `class_feature_id` via `class_id`
/// + `level = 1` + `choice_type = 'expertise'`. [chosenValues] porte DÉJÀ
/// les noms de compétences ET, le cas échéant, le nom de l'outil de
/// substitution — une ligne par valeur, même convention que
/// `createCharacter`.
typedef ExpertiseOptionsWrite = ({int classId, List<String> chosenValues});

/// Écritures à faire pour enregistrer une modification de personnage —
/// calculées par [CharacterEditPlanner.plan], exécutées telles quelles par
/// `CharacterEditRepository.save`.
class CharacterEditPlan {
  const CharacterEditPlan({
    required this.characterUpdate,
    this.classChange,
    this.abilityScores,
    this.skillDeletes = const {},
    this.skillInserts = const {},
    this.toolDeletes = const [],
    this.toolInserts = const [],
    this.languageDeletes = const {},
    this.languageInserts = const {},
    this.spellDeletes = const {},
    this.spellInserts = const [],
    this.spellSourceClassId,
    this.classFeatureChoiceWrite,
    this.subclassFeatureChoiceWrite,
    this.expertiseOptionsWrite,
    this.expertiseSkillUpgrades = const {},
    this.expertiseSkillDowngrades = const {},
  });

  /// Colonnes `characters` à mettre à jour (toujours écrites en bloc).
  final Map<String, Object?> characterUpdate;

  /// Changement de classe/sous-classe (niveau 1 uniquement). `hpRolled` :
  /// nouvelle valeur de `character_level_hp.hp_rolled` du niveau 1 quand la
  /// classe change (`null` si seule la sous-classe change) ;
  /// `classChanged` : purge des données propres à l'ancienne classe
  /// (usages d'aptitudes, choix d'aptitudes, emplacements de sorts).
  final ({int classId, int? subclassId, int? hpRolled, bool classChanged})?
  classChange;

  /// Nouveaux scores finaux, `null` si inchangés.
  final Map<String, int>? abilityScores;

  final Set<int> skillDeletes;
  final Set<int> skillInserts;
  final List<ToolRow> toolDeletes;
  final List<ToolRow> toolInserts;
  final Set<int> languageDeletes;
  final Set<int> languageInserts;

  /// Identifiants des sorts dont les lignes ORDINAIRES sont à supprimer.
  /// Jamais une ligne au statut `'inné'` : un même identifiant peut désigner
  /// deux lignes (une innée, une ordinaire), et
  /// `CharacterEditRepository.save` exclut les lignes innées de la
  /// suppression.
  final Set<int> spellDeletes;
  final List<({int spellId, SpellStatus status})> spellInserts;

  /// `character_spells.source_class_id` à écrire sur CHAQUE ligne de
  /// [spellInserts] — toujours la classe (unique, l'édition n'est possible
  /// qu'au niveau 1, voir [canChangeClass] dans [plan]) du personnage APRÈS
  /// modification, `null` seulement si [spellInserts] est vide. Avant ce
  /// champ (D40 du registre de dette technique,
  /// `docs/dette-technique.md`), `CharacterEditRepository.save` utilisait
  /// `classChange?.classId` — toujours `null` quand l'édition ne change NI
  /// la classe NI la sous-classe (ex. remplacer un sort de niveau 1 sans
  /// toucher à la classe), alors que la classe d'origine est connue et
  /// inchangée dans ce cas précis.
  final int? spellSourceClassId;

  /// Style de combat (Guerrier)/Ennemi juré (Rôdeur) — correctif D102
  /// (`docs/dette-technique.md`). `null` si rien à écrire : classe sans ce
  /// choix, ou valeur inchangée sans changement de classe (voir [plan] pour
  /// le détail du diff). `CharacterEditRepository.save` supprime TOUJOURS
  /// la ligne existante pour ce même choix (résolue via `class_id` +
  /// `choice_type`) avant de réinsérer — sans effet quand
  /// [classChange]?.classChanged a déjà tout purgé, nécessaire pour un
  /// changement de VALEUR seule (ex. "Défense" -> "Duel" sans changer de
  /// classe).
  final ClassFeatureChoiceWrite? classFeatureChoiceWrite;

  /// Ancêtre draconique (ou tout futur second choix de sous-classe) —
  /// correctif D102, même rationale que [classFeatureChoiceWrite].
  final SubclassFeatureChoiceWrite? subclassFeatureChoiceWrite;

  /// Expertise du Roublard (compétences + substitution outils de voleur) —
  /// correctif D102, même rationale que [classFeatureChoiceWrite]. Lignes
  /// purement DESCRIPTIVES de `character_class_options` (carte "CHOIX DE
  /// CLASSE" de la fiche) : le bonus RÉEL est porté par
  /// [expertiseSkillUpgrades]/[expertiseSkillDowngrades].
  final ExpertiseOptionsWrite? expertiseOptionsWrite;

  /// `character_skill_proficiencies.proficiency` à rehausser à
  /// `'expertise'` — toujours un sous-ensemble de compétences déjà
  /// maîtrisées (voir [skillInserts]/les compétences déjà stockées), jamais
  /// une ligne séparée ni dupliquée, même convention que
  /// `ExpertiseStepSelection.upgradeToExpertise` côté création.
  /// `CharacterEditRepository.save` exécute cette mise à jour APRÈS
  /// [skillInserts] : une compétence nouvellement choisie ET mise en
  /// Expertise dans le même enregistrement doit déjà exister en base.
  final Set<int> expertiseSkillUpgrades;

  /// Compétences dont l'Expertise d'un enregistrement PRÉCÉDENT n'est plus
  /// choisie dans ce nouvel enregistrement : repassées à `'competente'`
  /// (jamais supprimées, le personnage reste maîtrisé) — correctif D102.
  final Set<int> expertiseSkillDowngrades;
}

/// Calcule un [CharacterEditPlan] en comparant le brouillon d'origine
/// (pré-rempli par `CharacterEditHydrator`) et le brouillon modifié.
///
/// Principe « ne toucher qu'à ce qui vient de la création » : pour chaque
/// table de choix, seules les lignes issues de l'ancien brouillon et
/// absentes du nouveau sont supprimées, et seules les lignes du nouveau
/// brouillon absentes en base sont ajoutées. Tout ce qui a été obtenu
/// autrement (montée de niveau, multiclassage, préparation...) reste intact.
///
/// Décisions utilisateur du 2026-09-25 appliquées ici :
/// - classe/sous-classe modifiables au niveau 1 seulement ([canChangeClass]) ;
/// - caractéristiques saisies en valeurs FINALES ;
/// - PV max recalculés automatiquement quand la Constitution change (ou la
///   classe, au niveau 1), les dégâts subis étant conservés.
abstract final class CharacterEditPlanner {
  static CharacterEditPlan plan({
    required CharacterEditSnapshot snapshot,
    required CharacterCreationDraft original,
    required CharacterCreationDraft edited,
    required ClassOption? originalClass,
    required ClassOption? editedClass,
    required BackgroundOption? originalBackground,
    required BackgroundOption? editedBackground,
    required SkillCatalog skillCatalog,
    required ToolCatalog toolCatalog,
    required LanguageCatalog languageCatalog,
    SpellCatalog? originalSpellCatalog,
    SpellCatalog? editedSpellCatalog,
  }) {
    final canChangeClass = snapshot.totalLevel <= 1;
    final classChanged =
        canChangeClass &&
        edited.classId != null &&
        edited.classId != original.classId;
    final subclassChanged =
        canChangeClass && edited.subclassId != original.subclassId;

    // ── Points de vie ────────────────────────────────────────────────────
    int conModOf(CharacterCreationDraft draft) =>
        AbilityScoreRules.abilityModifier(draft.abilityScores?['con'] ?? 10);
    final oldConMod = conModOf(original);
    final newConMod = conModOf(edited);
    var newMaxHp = snapshot.maxHp;
    if (classChanged && editedClass != null) {
      newMaxHp = HitPointsCalculator.maxHpAtLevel1(
        hitDie: editedClass.hitDie,
        constitutionModifier: newConMod,
      );
    } else if (newConMod != oldConMod) {
      newMaxHp = math.max(
        1,
        snapshot.maxHp + (newConMod - oldConMod) * snapshot.totalLevel,
      );
    }
    final damageTaken = math.max(0, snapshot.maxHp - snapshot.currentHp);
    final newCurrentHp = (newMaxHp - damageTaken).clamp(0, newMaxHp);

    String textOr(String? value) => value ?? '';
    final characterUpdate = <String, Object?>{
      'name': edited.characterName ?? snapshot.name,
      'race_id': edited.raceId,
      'subrace_id': edited.subraceId,
      'race_custom_text': edited.raceCustomText,
      'background_id': edited.backgroundId,
      'alignment_id': edited.alignmentId,
      'sexe': edited.sexe,
      'age': edited.age,
      'height': edited.height,
      'weight': edited.weight,
      'eyes': edited.eyes,
      'skin': edited.skin,
      'hair': edited.hair,
      // `*_text` : colonnes `not null`, jamais `null` littéral.
      'appearance_text': textOr(edited.appearanceText),
      'traits_text': textOr(edited.traitsText),
      'ideals_text': textOr(edited.idealsText),
      'bonds_text': textOr(edited.bondsText),
      'flaws_text': textOr(edited.flawsText),
      'backstory_text': textOr(edited.backstoryText),
      'allies_text': textOr(edited.alliesText),
      'features_text': textOr(edited.featuresText),
      'treasure_text': textOr(edited.treasureText),
      'max_hp': newMaxHp,
      'current_hp': newCurrentHp,
    };

    // ── Caractéristiques (valeurs finales) ───────────────────────────────
    final editedScores = edited.abilityScores ?? const {};
    final scoresChanged =
        editedScores.isNotEmpty &&
        editedScores.entries.any(
          (entry) => snapshot.abilityScores[entry.key] != entry.value,
        );

    // ── Compétences ──────────────────────────────────────────────────────
    Set<int> skillIdsOf(CharacterCreationDraft draft, BackgroundOption? bg) => {
      for (final row in SkillProficiencyResolver.resolve(
        classSkillNames: draft.classSkillChoices,
        backgroundSkillNames: bg?.skillProficiencies ?? const [],
        catalog: skillCatalog,
      ))
        row.skillId,
    };
    final storedSkills = {for (final skill in snapshot.skills) skill.skillId};
    final oldSkills = skillIdsOf(original, originalBackground);
    final newSkills = skillIdsOf(edited, editedBackground);
    final skillDeletes = storedSkills.intersection(
      oldSkills.difference(newSkills),
    );
    final skillInserts = newSkills.difference(storedSkills);

    // ── Outils ───────────────────────────────────────────────────────────
    List<ToolRow> toolsOf(
      CharacterCreationDraft draft,
      ClassOption? classOption,
      BackgroundOption? bg,
    ) => ToolProficiencyResolver.resolve(
      classToolNames: draft.classToolChoices,
      classGrantedToolNames: classOption?.grantedToolNames ?? const [],
      backgroundGrantedToolTexts: bg?.toolOrLanguageGrantedTools ?? const [],
      catalog: toolCatalog,
    );
    final storedTools = snapshot.tools.toSet();
    final oldTools = toolsOf(
      original,
      originalClass,
      originalBackground,
    ).toSet();
    final newTools = toolsOf(edited, editedClass, editedBackground).toSet();

    // ── Langues ──────────────────────────────────────────────────────────
    Set<int> languagesOf(CharacterCreationDraft draft) =>
        LanguageSelectionResolver.resolve(
          languageNames: draft.backgroundLanguageChoices,
          catalog: languageCatalog,
        ).toSet();
    final storedLanguages = snapshot.languageIds.toSet();
    final oldLanguages = languagesOf(original);
    final newLanguages = languagesOf(edited);

    // ── Sorts (niveau 1 uniquement) ──────────────────────────────────────
    var spellDeletes = const <int>{};
    var spellInserts = const <({int spellId, SpellStatus status})>[];
    // Toujours la classe du personnage APRÈS modification (`edited.classId`)
    // dès que ce bloc calcule des `spellInserts` — y compris sans
    // changement de classe/sous-classe (`classChanged`/`subclassChanged`
    // faux) : voir la doc de [CharacterEditPlan.spellSourceClassId] (D40).
    int? spellSourceClassId;
    if (canChangeClass && editedClass != null && editedSpellCatalog != null) {
      // Lignes innées exclues (`CharacterEditSnapshot.classSpells`) : un
      // sort inné vient de la race, aucune modification de classe ne le
      // supprime — pas même un changement de classe, qui vide pourtant tous
      // les autres sorts. Conséquence voulue : choisir côté classe un sort
      // déjà inné AJOUTE une ligne ordinaire à côté de la ligne innée (aucune
      // contrainte d'unicité en base, la ligne ordinaire l'emporte à la
      // lecture de la fiche), que le joueur pourra retirer plus tard sans
      // perdre le sort inné.
      final storedSpells = {
        for (final spell in snapshot.classSpells) spell.spellId,
      };
      final oldSpells = originalSpellCatalog == null || originalClass == null
          ? const <int>{}
          : {
              for (final row in SpellSelectionResolver.resolve(
                cantripNames: original.classCantripChoices,
                levelOneSpellNames: original.classLevelOneSpellChoices,
                catalog: originalSpellCatalog,
                className: originalClass.name,
              ))
                row.spellId,
            };
      // Plafonné à [PreparedSpellsLimit.limitFor] (D79, `docs/dette-
      // technique.md`), même règle qu'à la création
      // (`CharacterCreationRepository.createCharacter`) : [editedClass] n'est
      // modifiable qu'au niveau 1 ([canChangeClass] ci-dessus), donc
      // `classLevel: 1` ici aussi — un multiclassage ajouté PLUS TARD (via
      // la montée de niveau, `CharacterRepository.applyLevelUp`) ne passe
      // jamais par ce planificateur. [edited.abilityScores] sont déjà des
      // valeurs FINALES (décision du 2026-09-25, voir la doc de classe),
      // jamais besoin de recharger `RaceCatalog` ici contrairement à
      // [SpellcastingRules] (quotas de sélection, eux, jamais recalculés
      // depuis l'ability score réel).
      final newRows = SpellSelectionResolver.capToPreparedLimit(
        rows: SpellSelectionResolver.resolve(
          cantripNames: edited.classCantripChoices,
          levelOneSpellNames: edited.classLevelOneSpellChoices,
          catalog: editedSpellCatalog,
          className: editedClass.name,
        ),
        catalog: editedSpellCatalog,
        className: editedClass.name,
        classLevel: 1,
        abilityScores: edited.abilityScores ?? const {},
      );
      final newSpells = {for (final row in newRows) row.spellId};
      // Changement de classe : aucun sort de l'ancienne classe ne reste.
      spellDeletes = classChanged
          ? storedSpells.difference(newSpells)
          : storedSpells.intersection(oldSpells.difference(newSpells));
      spellInserts = [
        for (final row in newRows)
          if (!storedSpells.contains(row.spellId)) row,
      ];
      if (spellInserts.isNotEmpty) {
        spellSourceClassId = edited.classId;
      }
    }

    // ── Choix nommé de CLASSE (Style de combat/Ennemi juré) ───────────────
    // Correctif D102 (`docs/dette-technique.md`). Écrit dès que la valeur
    // change (y compris via un changement de classe, qui a déjà remis
    // [edited.classFeatureChoiceValue] à `null` dans le brouillon — voir
    // `CharacterCreationDraftController.setClass` — avant d'être
    // éventuellement réécrit par `ClassChoiceStepScreen` pour la NOUVELLE
    // classe) : jamais quand la classe est inchangée ET la valeur
    // identique, pour ne pas réécrire `character_class_options` à chaque
    // enregistrement sans rapport avec ce choix.
    ClassFeatureChoiceWrite? classFeatureChoiceWrite;
    final classFeatureKind = canChangeClass && editedClass != null
        ? ClassChoiceRules.kindFor(editedClass.id)
        : null;
    if (classFeatureKind != null &&
        edited.classFeatureChoiceValue != null &&
        (classChanged ||
            edited.classFeatureChoiceValue !=
                original.classFeatureChoiceValue)) {
      classFeatureChoiceWrite = (
        classId: editedClass!.id,
        choiceType: ClassChoiceRules.choiceTypeFor(classFeatureKind),
        chosenValue: edited.classFeatureChoiceValue!,
      );
    }

    // ── Second choix de SOUS-CLASSE (Ancêtre draconique) ──────────────────
    // Correctif D102, même rationale que ci-dessus : `setClass`/
    // `SubclassStepScreen._submit` gardent déjà
    // [edited.subclassFeatureChoiceValue] cohérent avec la sous-classe
    // finale (`null` si elle n'a pas de second choix).
    SubclassFeatureChoiceWrite? subclassFeatureChoiceWrite;
    if (canChangeClass &&
        edited.subclassId != null &&
        edited.subclassFeatureChoiceValue != null &&
        (classChanged ||
            subclassChanged ||
            edited.subclassFeatureChoiceValue !=
                original.subclassFeatureChoiceValue)) {
      subclassFeatureChoiceWrite = (
        subclassId: edited.subclassId!,
        chosenValue: edited.subclassFeatureChoiceValue!,
      );
    }

    // ── Expertise du Roublard ──────────────────────────────────────────────
    // Correctif D102. Deux écritures distinctes, même séparation que
    // `createCharacter` : les lignes `character_class_options` (purement
    // descriptives, carte "CHOIX DE CLASSE") d'une part,
    // `character_skill_proficiencies.proficiency` (le bonus RÉEL) d'autre
    // part — jamais la même ligne qu'un simple [skillInserts]/[skillDeletes]
    // (une compétence peut rester maîtrisée tout en perdant son Expertise).
    ExpertiseOptionsWrite? expertiseOptionsWrite;
    var expertiseSkillUpgrades = const <int>{};
    var expertiseSkillDowngrades = const <int>{};
    if (canChangeClass && editedClass != null) {
      final skillIdByName = {
        for (final skill in skillCatalog.skills) skill.name: skill.id,
      };
      final newExpertiseSkillIds = <int>{
        for (final name in edited.expertiseSkillChoices) ?skillIdByName[name],
      };
      final storedExpertiseSkillIds = {
        for (final skill in snapshot.skills)
          if (skill.proficiency == 'expertise') skill.skillId,
      };
      expertiseSkillUpgrades = newExpertiseSkillIds.difference(
        storedExpertiseSkillIds,
      );
      expertiseSkillDowngrades = storedExpertiseSkillIds
          .difference(newExpertiseSkillIds)
          // Une compétence retirée entièrement (plus du tout maîtrisée)
          // n'a pas besoin d'un `UPDATE` séparé, sa ligne part déjà via
          // [skillDeletes].
          .difference(skillDeletes);

      // Substitution outils de voleur : RAW 2014 UNIQUEMENT, même
      // résolution que `createCharacter`/`_ExpertiseBody`.
      final isEdition2014 = edited.edition == '2014';
      final thievesToolsName =
          edited.expertiseThievesToolsSubstitution &&
              isEdition2014 &&
              editedClass.grantedToolNames.isNotEmpty
          ? editedClass.grantedToolNames.first
          : null;
      final newChosenValues = [
        ...edited.expertiseSkillChoices,
        ?thievesToolsName,
      ];
      final expertiseValueChanged =
          !_sameStringSets(
            original.expertiseSkillChoices,
            edited.expertiseSkillChoices,
          ) ||
          original.expertiseThievesToolsSubstitution !=
              edited.expertiseThievesToolsSubstitution;
      if (newChosenValues.isNotEmpty &&
          (classChanged || expertiseValueChanged)) {
        expertiseOptionsWrite = (
          classId: editedClass.id,
          chosenValues: newChosenValues,
        );
      }
    }

    return CharacterEditPlan(
      characterUpdate: characterUpdate,
      classChange: (classChanged || subclassChanged) && edited.classId != null
          ? (
              classId: edited.classId!,
              subclassId: edited.subclassId,
              hpRolled: classChanged ? editedClass?.hitDie : null,
              classChanged: classChanged,
            )
          : null,
      abilityScores: scoresChanged ? Map.of(editedScores) : null,
      skillDeletes: skillDeletes,
      skillInserts: skillInserts,
      toolDeletes: storedTools
          .intersection(oldTools.difference(newTools))
          .toList(),
      toolInserts: newTools.difference(storedTools).toList(),
      languageDeletes: storedLanguages.intersection(
        oldLanguages.difference(newLanguages),
      ),
      languageInserts: newLanguages.difference(storedLanguages),
      spellDeletes: spellDeletes,
      spellInserts: spellInserts,
      spellSourceClassId: spellSourceClassId,
      classFeatureChoiceWrite: classFeatureChoiceWrite,
      subclassFeatureChoiceWrite: subclassFeatureChoiceWrite,
      expertiseOptionsWrite: expertiseOptionsWrite,
      expertiseSkillUpgrades: expertiseSkillUpgrades,
      expertiseSkillDowngrades: expertiseSkillDowngrades,
    );
  }

  /// `true` si [a]/[b] contiennent exactement les mêmes valeurs, sans tenir
  /// compte de l'ordre ni des doublons — utilisé pour diffuser le choix
  /// d'Expertise du Roublard (correctif D102) sans dépendre de l'ordre dans
  /// lequel le joueur a (re)coché les compétences.
  static bool _sameStringSets(List<String> a, List<String> b) {
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.length == setB.length && setA.containsAll(setB);
  }
}
