import '../../../core/rules/spell_status.dart';

/// `class_features.choice_type`/`class_id`/`subclass_id` d'une ligne
/// `class_features` déjà résolue (par `data/character_edit_repository.dart
/// ::fetchSnapshot`, requête séparée — même convention que
/// `data/character_repository.dart`, qui résout toujours `class_features`
/// via une requête dédiée plutôt qu'une jointure Postgrest embarquée),
/// nécessaire pour reconstruire [CharacterEditSnapshot.classOptions] —
/// correctif D102 (`docs/dette-technique.md`).
typedef ClassFeatureChoiceInfo = ({
  String? choiceType,
  int? classId,
  int? subclassId,
});

/// Ligne `character_class_options` de NIVEAU 1 enrichie du `choice_type`/
/// `class_id`/`subclass_id` de sa ligne `class_features` associée —
/// correctif D102. `featureClassId` non nul pour un choix de CLASSE (Style
/// de combat/Ennemi juré/Expertise), `featureSubclassId` non nul pour un
/// choix de SOUS-CLASSE (Ancêtre draconique), jamais les deux à la fois
/// (même principe que `createCharacter`/`character_repository.dart`).
typedef ClassOptionRow = ({
  int? featureClassId,
  int? featureSubclassId,
  String? choiceType,
  String chosenValue,
});

/// État brut d'un personnage existant au moment où le joueur lance
/// « Modifier » depuis la fiche (demande utilisateur du 2026-09-25 : réutiliser
/// l'assistant de création pour tout modifier). Identifiants bruts, pas de
/// noms traduits : c'est la base de [CharacterEditHydrator] (pré-remplissage
/// du brouillon) et de [CharacterEditPlanner] (écritures à faire).
///
/// Construit par [CharacterEditSnapshot.fromRow] depuis une ligne
/// `characters` avec ses tables enfants embarquées (voir
/// `data/character_edit_repository.dart`).
class CharacterEditSnapshot {
  const CharacterEditSnapshot({
    required this.characterId,
    required this.name,
    required this.primaryClassId,
    required this.primaryClassLevel,
    required this.totalLevel,
    required this.maxHp,
    required this.currentHp,
    this.edition = '2014',
    this.raceId,
    this.subraceId,
    this.raceCustomText,
    this.backgroundId,
    this.alignmentId,
    this.subclassId,
    this.portraitUrl,
    this.abilityScores = const {},
    this.identity = const {},
    this.texts = const {},
    this.skills = const [],
    this.tools = const [],
    this.languageIds = const [],
    this.spells = const [],
    this.classOptions = const [],
  });

  final String characterId;
  final String name;

  /// `characters.edition` — figée à la création, jamais modifiable depuis
  /// l'assistant en mode modification (`CharacterEditHydrator` la reporte
  /// telle quelle dans le brouillon, voir `character_creation_draft.dart
  /// ::edition`) : pilote le même gating Métamagie/Expertise que pour un
  /// personnage en cours de création. `'2014'` par défaut, même rationale
  /// défensive que [maxHp]/[currentHp] pour une ligne ancienne sans cette
  /// colonne.
  final String edition;
  final int? raceId;
  final int? subraceId;
  final String? raceCustomText;
  final int? backgroundId;
  final int? alignmentId;

  /// Classe principale (`character_classes.is_primary`, sinon la première).
  final int? primaryClassId;
  final int? subclassId;
  final int primaryClassLevel;

  /// Somme des niveaux de toutes les classes (multiclassage compris).
  final int totalLevel;

  final int maxHp;
  final int currentHp;
  final String? portraitUrl;

  /// Scores FINAUX (`character_ability_scores`), clé 'str'...'cha'.
  final Map<String, int> abilityScores;

  /// Colonnes `sexe`/`age`/`height`/`weight`/`eyes`/`skin`/`hair` (chaîne
  /// vide si non renseignée), clé = nom de colonne.
  final Map<String, String> identity;

  /// Les 9 colonnes `*_text` (chaîne vide si non renseignée), clé = nom de
  /// colonne.
  final Map<String, String> texts;

  final List<({int skillId, String proficiency})> skills;
  final List<({int? toolId, String? customText})> tools;
  final List<int> languageIds;

  /// Toutes les lignes `character_spells`, sorts innés compris. Une même
  /// valeur de `spellId` peut y figurer deux fois (aucune contrainte
  /// d'unicité en base) : une fois [innateStatus], une fois ordinaire.
  final List<({int spellId, SpellStatus status})> spells;

  /// `character_spells.status` d'un sort inné racial.
  static const SpellStatus innateStatus = SpellStatus.innate;

  /// Lignes `character_class_options` de NIVEAU 1 ("choix nommés" couverts
  /// par ce brouillon : Style de combat/Ennemi juré, Expertise, Ancêtre
  /// draconique) — correctif D102 (`docs/dette-technique.md`). Source de
  /// [CharacterEditHydrator] pour pré-remplir `classFeatureChoiceValue`/
  /// `subclassFeatureChoiceValue`/`expertiseThievesToolsSubstitution` (le
  /// 4e champ, `expertiseSkillChoices`, se dérive plutôt de [skills] — le
  /// bonus RÉEL de l'Expertise est `character_skill_proficiencies.
  /// proficiency = 'expertise'`, cette table-ci n'étant que descriptive,
  /// voir `domain/expertise_step_selection.dart`) et de
  /// [CharacterEditPlanner] pour calculer les écritures à faire.
  final List<ClassOptionRow> classOptions;

  /// Les sorts que l'assistant a le droit de lire comme des choix de classe
  /// et de réécrire : toutes les lignes sauf celles au statut
  /// [innateStatus]. Un sort inné vient de la race
  /// (`racial_innate_spells`), jamais d'un choix de classe : il ne doit ni
  /// pré-remplir l'étape Sorts ([CharacterEditHydrator]), ni entrer dans le
  /// calcul des suppressions ([CharacterEditPlanner]).
  List<({int spellId, SpellStatus status})> get classSpells => [
    for (final spell in spells)
      if (spell.status != innateStatus) spell,
  ];

  static const List<String> identityColumns = [
    'sexe',
    'age',
    'height',
    'weight',
    'eyes',
    'skin',
    'hair',
  ];

  static const List<String> textColumns = [
    'appearance_text',
    'traits_text',
    'ideals_text',
    'bonds_text',
    'flaws_text',
    'backstory_text',
    'allies_text',
    'features_text',
    'treasure_text',
  ];

  /// [classFeaturesById] : `class_features.id` -> [ClassFeatureChoiceInfo],
  /// résolu par une requête SÉPARÉE par l'appelant (`data
  /// /character_edit_repository.dart::fetchSnapshot`, même convention que
  /// `data/character_repository.dart` — jamais une jointure Postgrest
  /// embarquée pour `class_features`, voir la doc de classe de
  /// [ClassFeatureChoiceInfo]) à partir des `class_feature_id` trouvés dans
  /// `row['character_class_options']`. Vide par défaut : un appelant qui ne
  /// le fournit pas (ex. tests existants sans correctif D102) obtient
  /// simplement [classOptions] vide plutôt qu'une erreur.
  static CharacterEditSnapshot fromRow(
    Map<String, dynamic> row, {
    Map<int, ClassFeatureChoiceInfo> classFeaturesById = const {},
  }) {
    List<Map<String, dynamic>> rowsOf(String key) =>
        (row[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    int? intOf(Object? value) => value is num ? value.toInt() : null;

    ClassOptionRow? classOptionRowOf(Map<String, dynamic> optionRow) {
      if (intOf(optionRow['level']) != 1) return null;
      final chosenValue = optionRow['chosen_value'];
      if (chosenValue is! String) return null;
      final featureId = intOf(optionRow['class_feature_id']);
      final feature = featureId == null ? null : classFeaturesById[featureId];
      return (
        featureClassId: feature?.classId,
        featureSubclassId: feature?.subclassId,
        choiceType: feature?.choiceType,
        chosenValue: chosenValue,
      );
    }

    final classRows = rowsOf('character_classes');
    final primary = classRows.firstWhere(
      (classRow) => classRow['is_primary'] == true,
      orElse: () => classRows.isEmpty ? const {} : classRows.first,
    );
    var totalLevel = 0;
    for (final classRow in classRows) {
      totalLevel += intOf(classRow['level']) ?? 0;
    }

    return CharacterEditSnapshot(
      characterId: row['id'] as String,
      name: row['name'] as String? ?? '',
      edition: row['edition'] as String? ?? '2014',
      raceId: intOf(row['race_id']),
      subraceId: intOf(row['subrace_id']),
      raceCustomText: row['race_custom_text'] as String?,
      backgroundId: intOf(row['background_id']),
      alignmentId: intOf(row['alignment_id']),
      primaryClassId: intOf(primary['class_id']),
      subclassId: intOf(primary['subclass_id']),
      primaryClassLevel: intOf(primary['level']) ?? 1,
      totalLevel: totalLevel == 0 ? 1 : totalLevel,
      maxHp: intOf(row['max_hp']) ?? 1,
      currentHp: intOf(row['current_hp']) ?? 0,
      portraitUrl: row['portrait_url'] as String?,
      abilityScores: {
        for (final scoreRow in rowsOf('character_ability_scores'))
          if (scoreRow['ability_id'] is String &&
              intOf(scoreRow['score']) != null)
            scoreRow['ability_id'] as String: intOf(scoreRow['score'])!,
      },
      identity: {
        for (final column in identityColumns)
          column: row[column] as String? ?? '',
      },
      texts: {
        for (final column in textColumns) column: row[column] as String? ?? '',
      },
      skills: [
        for (final skillRow in rowsOf('character_skill_proficiencies'))
          if (intOf(skillRow['skill_id']) != null)
            (
              skillId: intOf(skillRow['skill_id'])!,
              proficiency: skillRow['proficiency'] as String? ?? 'competente',
            ),
      ],
      tools: [
        for (final toolRow in rowsOf('character_tool_proficiencies'))
          (
            toolId: intOf(toolRow['tool_id']),
            customText: toolRow['custom_text'] as String?,
          ),
      ],
      languageIds: [
        for (final languageRow in rowsOf('character_languages'))
          ?intOf(languageRow['language_id']),
      ],
      spells: [
        for (final spellRow in rowsOf('character_spells'))
          if (intOf(spellRow['spell_id']) != null)
            (
              spellId: intOf(spellRow['spell_id'])!,
              status: SpellStatus.fromValue(spellRow['status'] as String?),
            ),
      ],
      classOptions: [
        for (final optionRow in rowsOf('character_class_options'))
          ?classOptionRowOf(optionRow),
      ],
    );
  }
}
