import 'background_option.dart';
import 'character_creation_draft.dart';
import 'character_edit_snapshot.dart';
import 'class_option.dart';
import 'language_catalog.dart';
import 'skill_catalog.dart';
import 'spell_catalog.dart';
import 'spellcasting_rules.dart';
import 'tool_catalog.dart';

/// Reconstruit un [CharacterCreationDraft] à partir d'un personnage existant
/// ([CharacterEditSnapshot]), pour pré-remplir l'assistant de création en
/// mode modification.
///
/// Le brouillon ne connaît que les choix « de création » (compétences de
/// classe, outils de classe, langues d'historique, sorts de niveau 0/1) : on
/// ne reprend donc des données stockées que ce qui correspond à ces choix,
/// dans la limite de leurs quotas. Tout le reste (compétence obtenue en
/// montée de niveau, outil de multiclassage, sort appris plus tard...) n'est
/// pas dans le brouillon et [CharacterEditPlanner] n'y touche jamais.
abstract final class CharacterEditHydrator {
  static CharacterCreationDraft toDraft({
    required CharacterEditSnapshot snapshot,
    required ClassOption? classOption,
    required BackgroundOption? backgroundOption,
    required SkillCatalog skillCatalog,
    required ToolCatalog toolCatalog,
    required LanguageCatalog languageCatalog,
    SpellCatalog? spellCatalog,
  }) {
    String? orNull(String? value) =>
        value == null || value.trim().isEmpty ? null : value;

    final skillNameById = {
      for (final skill in skillCatalog.skills) skill.id: skill.name,
    };
    final backgroundSkills = backgroundOption?.skillProficiencies ?? const [];
    final classSkillPool = classOption?.skillChoices.choices ?? const [];
    final classSkills = [
      for (final skill in snapshot.skills)
        if (skillNameById[skill.skillId] case final name?)
          if (classSkillPool.contains(name) && !backgroundSkills.contains(name))
            name,
    ].take(classOption?.skillChoices.count ?? 0).toList();

    final toolChoice = classOption?.toolChoice;
    final toolById = {for (final tool in toolCatalog.tools) tool.id: tool};
    final classTools = toolChoice == null
        ? const <String>[]
        : [
            for (final tool in snapshot.tools)
              if (toolById[tool.toolId] case final option?)
                if (toolChoice.categories.contains(option.category) &&
                    !(classOption?.grantedToolNames.contains(option.name) ??
                        false))
                  option.name,
          ].take(toolChoice.count).toList();

    final languageNameById = {
      for (final language in languageCatalog.languages)
        language.id: language.name,
    };
    final languages = [
      for (final id in snapshot.languageIds) ?languageNameById[id],
    ].take(backgroundOption?.languageChoiceCount ?? 0).toList();

    var cantrips = const <String>[];
    var levelOneSpells = const <String>[];
    if (spellCatalog != null && classOption != null) {
      final spellById = {
        for (final spell in spellCatalog.spells) spell.id: spell,
      };
      final known = [
        for (final spell in snapshot.spells) ?spellById[spell.spellId],
      ];
      cantrips = [
        for (final spell in known)
          if (spell.level == 0) spell.name,
      ].take(SpellcastingRules.cantripQuotaFor(classOption.name)).toList();
      levelOneSpells =
          [
                for (final spell in known)
                  if (spell.level == 1) spell.name,
              ]
              .take(SpellcastingRules.levelOneSpellQuotaFor(classOption.name))
              .toList();
    }

    String? identity(String column) => orNull(snapshot.identity[column]);
    String? text(String column) => orNull(snapshot.texts[column]);

    return CharacterCreationDraft(
      raceId: snapshot.raceId,
      subraceId: snapshot.subraceId,
      raceCustomText: orNull(snapshot.raceCustomText),
      classId: snapshot.primaryClassId,
      subclassId: snapshot.subclassId,
      backgroundId: snapshot.backgroundId,
      abilityScores: Map<String, int>.from(snapshot.abilityScores),
      classSkillChoices: classSkills,
      classToolChoices: classTools,
      backgroundLanguageChoices: languages,
      classCantripChoices: cantrips,
      classLevelOneSpellChoices: levelOneSpells,
      sexe: identity('sexe'),
      age: identity('age'),
      height: identity('height'),
      weight: identity('weight'),
      eyes: identity('eyes'),
      skin: identity('skin'),
      hair: identity('hair'),
      appearanceText: text('appearance_text'),
      traitsText: text('traits_text'),
      idealsText: text('ideals_text'),
      bondsText: text('bonds_text'),
      flawsText: text('flaws_text'),
      backstoryText: text('backstory_text'),
      alliesText: text('allies_text'),
      featuresText: text('features_text'),
      treasureText: text('treasure_text'),
      characterName: orNull(snapshot.name),
      alignmentId: snapshot.alignmentId,
    );
  }
}
