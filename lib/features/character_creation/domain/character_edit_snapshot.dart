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
  });

  final String characterId;
  final String name;
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
  final List<({int spellId, String status})> spells;

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

  static CharacterEditSnapshot fromRow(Map<String, dynamic> row) {
    List<Map<String, dynamic>> rowsOf(String key) =>
        (row[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    int? intOf(Object? value) => value is num ? value.toInt() : null;

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
              status: spellRow['status'] as String? ?? 'connu',
            ),
      ],
    );
  }
}
