import 'dart:math' as math;

import 'ability_score_rules.dart';
import 'background_option.dart';
import 'character_creation_draft.dart';
import 'character_edit_snapshot.dart';
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
  final Set<int> spellDeletes;
  final List<({int spellId, String status})> spellInserts;
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
    var spellInserts = const <({int spellId, String status})>[];
    if (canChangeClass && editedClass != null && editedSpellCatalog != null) {
      final storedSpells = {for (final spell in snapshot.spells) spell.spellId};
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
      final newRows = SpellSelectionResolver.resolve(
        cantripNames: edited.classCantripChoices,
        levelOneSpellNames: edited.classLevelOneSpellChoices,
        catalog: editedSpellCatalog,
        className: editedClass.name,
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
      skillDeletes: storedSkills.intersection(oldSkills.difference(newSkills)),
      skillInserts: newSkills.difference(storedSkills),
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
    );
  }
}
