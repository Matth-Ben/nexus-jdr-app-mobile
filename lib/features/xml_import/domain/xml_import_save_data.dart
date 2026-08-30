/// Une ligne prête pour `character_level_hp` (`level`/`hp_rolled`, `method`
/// toujours `'lance'` à l'écriture — voir `data/xml_import_repository.dart`) :
/// un personnage importé a une valeur de PV **réellement gagnée** par niveau
/// exportée par aidedd.org (`<hp_brut>`), contrairement à
/// `character_creation` qui ne calcule que le niveau 1 (voir
/// `domain/xml_import_hit_points_calculator.dart`).
typedef XmlImportLevelHpLine = ({int level, int hpRolled});

/// Une ligne prête pour `character_skill_proficiencies` — `proficiency`
/// toujours `'competente'` (le XML aidedd.org ne distingue pas
/// "compétente"/"expertise", voir `docs/cahier-des-charges/03-import-xml-aidedd.md`).
typedef XmlImportSkillProficiencyLine = ({int skillId});

/// Une ligne prête pour `character_tool_proficiencies` (`tool_id` nullable +
/// `custom_text`, voir le modèle de données) — [toolId] non nul pour un outil
/// déjà résolu vers un `ToolOption` réel par
/// `xml_character_import_resolver.dart` (increment 1), [customText] pour un
/// nom d'outil non reconnu (jamais perdu silencieusement).
typedef XmlImportToolProficiencyLine = ({int? toolId, String? customText});

/// Une ligne prête pour `character_spells` — `sourceClassId` reprend l'`id`
/// de la classe déjà résolue (`null` si la classe elle-même n'a pas été
/// reconnue).
typedef XmlImportSpellLine = ({int spellId, String status, int? sourceClassId});

/// Une ligne prête pour `character_inventory` (`item_id` nullable +
/// `custom_name`, même forme que `CharacterCreationEquipmentResolver
/// .InventoryLineDraft`, `equipped` en plus ici — voir la documentation de
/// [XmlImportSaveDataResolver.resolve]).
typedef XmlImportInventoryLine = ({
  int? itemId,
  String? customName,
  int quantity,
  bool equipped,
});

/// Données entièrement prêtes à écrire dans les tables `characters` et
/// enfants (voir `data/xml_import_repository.dart`), produites par
/// [XmlImportSaveDataResolver.resolve] à partir d'un
/// `XmlCharacterImportResolved` (potentiellement déjà corrigé manuellement
/// par l'utilisateur sur l'écran de vérification) et des catalogues internes
/// réels de l'app.
///
/// Ne porte volontairement **pas** [XmlImportSaveDataResolver] lui-même ni le
/// nom du personnage (paramètre séparé de
/// `XmlImportRepository.saveImportedCharacter`, même convention que
/// `characterName` de `CharacterCreationRepository.createCharacter`).
typedef XmlImportSaveData = ({
  int? raceId,
  String? raceCustomText,
  int? backgroundId,

  /// `characters.background_custom_text` (`<backSpe>` du XML) — même
  /// rationale que [raceCustomText] : passthrough informatif, jamais résolu
  /// par nom (voir `xml_character_import_resolver.dart`,
  /// `XmlCharacterImportRaw.backSpe`).
  String? backgroundCustomText,
  int? alignmentId,
  int xp,

  /// `characters.max_hp`/`current_hp` (les deux colonnes reçoivent la même
  /// valeur à l'import, comme un personnage "à pleine vie" — pas de notion de
  /// dégâts déjà subis dans le format aidedd.org).
  int maxHp,

  /// `characters.sexe` — texte direct (`AideddReferenceTables.sexes`,
  /// jamais un id), voir la documentation de classe de
  /// [XmlImportSaveDataResolver] pour le rationale de l'absence de câblage
  /// vers un catalogue réel pour ce champ.
  String sexe,
  int? age,
  String? height,
  String? weight,
  String? eyes,
  String? skin,
  String? hair,
  String appearanceText,
  String traitsText,
  String idealsText,
  String bondsText,
  String flawsText,
  String backstoryText,
  String alliesText,
  String featuresText,
  String treasureText,
  int currencyGp,
  int currencyPp,
  int currencyEp,
  int currencySp,
  int currencyCp,
  int? classId,
  int level,
  Map<String, int> abilityScores,
  List<XmlImportLevelHpLine> levelHp,
  List<XmlImportSkillProficiencyLine> skillProficiencyLines,
  List<XmlImportToolProficiencyLine> toolProficiencyLines,
  List<int> languageIds,
  List<XmlImportSpellLine> spellLines,
  List<XmlImportInventoryLine> inventoryLines,
});
