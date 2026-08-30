import '../../character_creation/domain/ability_score_rules.dart';
import '../../character_creation/domain/alignment_catalog.dart';
import '../../character_creation/domain/alignment_option.dart';
import '../../character_creation/domain/item_catalog.dart';
import '../../character_creation/domain/item_option.dart';
import '../../character_creation/domain/language_option.dart';
import '../../character_creation/domain/skill_catalog.dart';
import '../../character_creation/domain/skill_option.dart';
import '../../character_creation/domain/tool_option.dart';
import 'aidedd_reference_tables.dart';
import 'xml_character_import_resolved.dart';
import 'xml_field_resolution.dart';
import 'xml_import_hit_points_calculator.dart';
import 'xml_import_save_data.dart';
import 'xml_name_resolver.dart';

/// Ferme le chaînon manquant laissé ouvert par l'increment 1 (voir la
/// documentation de classe de `aidedd_reference_tables.dart`) : convertit un
/// `XmlCharacterImportResolved` (potentiellement déjà corrigé manuellement
/// par l'utilisateur sur l'écran de vérification) — dont les champs "codés"
/// (armure, arme, objets, compétences, alignement) ne sont résolus qu'au
/// **libellé aidedd** (`String`) — vers de vrais identifiants des tables de
/// référence internes de l'app (`items.id`/`skills.id`/`alignments.id`),
/// prêts à être écrits par `data/xml_import_repository.dart`.
///
/// Race/classe/historique/outils/langues/sorts n'ont **pas** besoin de ce
/// second passage : `xml_character_import_resolver.dart` (increment 1) les
/// résout déjà directement vers un `RaceOption`/`ClassOption`/
/// `BackgroundOption`/`ToolOption`/`LanguageOption`/`SpellOption` réel (donc
/// un vrai id) — seuls les champs "codés" au sens de
/// `docs/cahier-des-charges/03-import-xml-aidedd.md` (armure, bouclier,
/// armes, outils physiques, objets, compétences, alignement) transitaient
/// encore par un simple libellé `String` avant ce résolveur.
///
/// [sexe]/[age]/[height]/[weight]/[eyes]/[skin]/[hair] n'ont, à l'inverse,
/// **jamais** besoin de câblage vers un catalogue : `characters.sexe` est une
/// colonne texte directe (pas de FK, voir `02-modele-donnees.md`), la
/// résolution "codé → libellé" de l'increment 1
/// (`AideddReferenceTables.sexes`) est donc déjà la valeur finale à écrire.
///
/// Une correspondance de nom qui échoue malgré un champ [XmlFieldResolution
/// .recognized] au niveau aidedd (libellé aidedd sans équivalent dans le
/// catalogue interne réel, ex. différence de formulation entre aidedd.org et
/// le contenu peuplé par l'équipe `dev-backend-supabase`) ne bloque jamais
/// l'import : voir [_matchItem]/[_matchSkill]/[_matchAlignment], qui
/// retombent respectivement sur `customName`/absence de ligne/`null` plutôt
/// que de lancer une exception — cohérent avec le principe "aucun champ non
/// résolu ne doit bloquer silencieusement la progression" déjà appliqué à
/// l'écran de vérification lui-même.
abstract final class XmlImportSaveDataResolver {
  static XmlImportSaveData resolve({
    required XmlCharacterImportResolved resolved,
    required ItemCatalog itemCatalog,
    required SkillCatalog skillCatalog,
    required AlignmentCatalog alignmentCatalog,
  }) {
    final constitutionModifier = AbilityScoreRules.abilityModifier(
      resolved.abilityScores['con'] ?? 10,
    );
    final maxHp = XmlImportHitPointsCalculator.computeMaxHp(
      levels: resolved.levels,
      constitutionModifier: constitutionModifier,
    );

    final raceValue = _recognizedValue(resolved.race);
    final classValue = _recognizedValue(resolved.characterClass);
    final backgroundValue = _recognizedValue(resolved.background);

    final sexeLabel =
        _recognizedValue(resolved.sexe) ??
        _rawValueOf(resolved.sexe) ??
        'Non renseigné';

    final alignmentLabel = _recognizedValue(resolved.alignment);
    final alignmentOption = alignmentLabel == null
        ? null
        : _matchAlignment(alignmentLabel, alignmentCatalog);

    return (
      raceId: raceValue?.id,
      raceCustomText: resolved.raceCustomText,
      backgroundId: backgroundValue?.id,
      backgroundCustomText: resolved.backgroundCustomText,
      alignmentId: alignmentOption?.id,
      xp: resolved.xp ?? 0,
      maxHp: maxHp,
      sexe: sexeLabel,
      age: resolved.age,
      height: resolved.height,
      weight: resolved.weight,
      eyes: resolved.eyes,
      skin: resolved.skin,
      hair: resolved.hair,
      appearanceText: resolved.appearanceText,
      traitsText: resolved.traitsText,
      idealsText: resolved.idealsText,
      bondsText: resolved.bondsText,
      flawsText: resolved.flawsText,
      backstoryText: resolved.backstoryText,
      alliesText: resolved.alliesText,
      featuresText: resolved.featuresText,
      treasureText: resolved.treasureText,
      currencyGp: resolved.gp,
      currencyPp: resolved.pp,
      currencyEp: resolved.ep,
      currencySp: resolved.sp,
      currencyCp: resolved.cp,
      classId: classValue?.id,
      level: resolved.level,
      abilityScores: resolved.abilityScores,
      levelHp: [
        for (final entry in resolved.levels)
          if (entry.hpBrut > 0) (level: entry.level, hpRolled: entry.hpBrut),
      ],
      skillProficiencyLines: _resolveSkillLines(
        resolved.skillProficiencies,
        skillCatalog,
      ),
      toolProficiencyLines: _resolveToolLines(resolved.toolProficiencies),
      languageIds: _resolveLanguageIds(resolved.languages),
      spellLines: _resolveSpellLines(
        innateSpells: resolved.innateSpells,
        knownSpells: resolved.knownSpells,
        sourceClassId: classValue?.id,
      ),
      inventoryLines: _resolveInventoryLines(resolved, itemCatalog),
    );
  }

  /// Dédoublonne par `skill_id` (une compétence octroyée à la fois par la
  /// race et la classe, par exemple, ne doit produire qu'une seule ligne —
  /// `character_skill_proficiencies` a `character_id`+`skill_id` pour clé,
  /// voir `02-modele-donnees.md`) ; une étiquette aidedd sans correspondance
  /// dans [skillCatalog] est omise plutôt que d'écrire une ligne invalide
  /// (`skill_id` n'est pas nullable).
  static List<XmlImportSkillProficiencyLine> _resolveSkillLines(
    Map<int, List<XmlFieldResolution<String>>> groups,
    SkillCatalog skillCatalog,
  ) {
    final skillIds = <int>{};
    for (var groupId = 0; groupId <= 3; groupId++) {
      for (final resolution in groups[groupId] ?? const []) {
        final label = _recognizedValue(resolution);
        if (label == null) continue;
        final match = _matchSkill(label, skillCatalog);
        if (match != null) skillIds.add(match.id);
      }
    }
    return [for (final id in skillIds) (skillId: id)];
  }

  /// `toolProficiencies` est déjà résolu vers de vrais `ToolOption` par
  /// l'increment 1 (voir la documentation de classe) : simple conversion de
  /// forme, dédoublonnée par `tool_id`/`custom_text` (même rationale que
  /// [_resolveSkillLines]).
  static List<XmlImportToolProficiencyLine> _resolveToolLines(
    Map<int, List<XmlFieldResolution<ToolOption>>> groups,
  ) {
    final toolIds = <int>{};
    final customTexts = <String>{};
    for (var groupId = 0; groupId <= 3; groupId++) {
      for (final resolution in groups[groupId] ?? const []) {
        final tool = _recognizedValue(resolution);
        if (tool != null) {
          toolIds.add(tool.id);
          continue;
        }
        final rawValue = _rawValueOf(resolution);
        if (rawValue != null) customTexts.add(rawValue);
      }
    }
    return [
      for (final id in toolIds) (toolId: id, customText: null),
      for (final text in customTexts) (toolId: null, customText: text),
    ];
  }

  static T? _recognizedValue<T>(XmlFieldResolution<T> resolution) {
    return switch (resolution) {
      XmlFieldResolutionRecognized<T>(:final value) => value,
      _ => null,
    };
  }

  static String? _rawValueOf<T>(XmlFieldResolution<T> resolution) {
    return switch (resolution) {
      XmlFieldResolutionUnrecognized<T>(:final rawValue) => rawValue,
      _ => null,
    };
  }

  static ItemOption? _matchItem(String label, ItemCatalog itemCatalog) {
    final result = XmlNameResolver.resolveByName<ItemOption>(
      rawName: label,
      candidates: itemCatalog.items,
      nameOf: (item) => item.name,
    );
    return _recognizedValue(result);
  }

  static SkillOption? _matchSkill(String label, SkillCatalog skillCatalog) {
    final result = XmlNameResolver.resolveByName<SkillOption>(
      rawName: label,
      candidates: skillCatalog.skills,
      nameOf: (skill) => skill.name,
    );
    return _recognizedValue(result);
  }

  static AlignmentOption? _matchAlignment(
    String label,
    AlignmentCatalog alignmentCatalog,
  ) {
    final result = XmlNameResolver.resolveByName<AlignmentOption>(
      rawName: label,
      candidates: alignmentCatalog.alignments,
      nameOf: (alignment) => alignment.name,
    );
    return _recognizedValue(result);
  }

  /// `languages` est déjà résolu vers de vrais `LanguageOption` par
  /// l'increment 1 — dédoublonné par `language_id` (une langue octroyée par
  /// deux sources à la fois, ex. race ET historique, ne doit produire qu'une
  /// seule ligne `character_languages`), une langue non reconnue est omise
  /// (`language_id` n'est pas nullable, pas de colonne `custom_text` sur
  /// cette table contrairement à `character_tool_proficiencies`).
  static List<int> _resolveLanguageIds(
    Map<int, List<XmlFieldResolution<LanguageOption>>> groups,
  ) {
    final languageIds = <int>{};
    for (var groupId = 0; groupId <= 3; groupId++) {
      for (final resolution in groups[groupId] ?? const []) {
        final language = _recognizedValue(resolution);
        if (language != null) languageIds.add(language.id);
      }
    }
    return languageIds.toList();
  }

  /// `innateSpells`/`knownSpells` sont déjà résolus vers de vrais
  /// `SpellOption` par l'increment 1 — un sort non reconnu est omis
  /// (`spell_id` n'est pas nullable). Pas de dédoublonnage ici (contrairement
  /// à [_resolveSkillLines]/[_resolveToolLines]/[_resolveLanguageIds]) : un
  /// même sort connu à la fois "inné" et "connu" (ex. un sort de départ d'un
  /// Occultiste retrouvé dans sa liste de sorts connus) produit légitimement
  /// deux lignes distinctes, `character_spells.id` est une clé synthétique
  /// (`uuid`), pas une clé composite sur `spell_id`.
  static List<XmlImportSpellLine> _resolveSpellLines({
    required List<XmlSpellResolution> innateSpells,
    required List<XmlSpellResolution> knownSpells,
    required int? sourceClassId,
  }) {
    return [
      for (final entry in innateSpells)
        if (_recognizedValue(entry.resolution) != null)
          (
            spellId: _recognizedValue(entry.resolution)!.id,
            status: 'inné',
            sourceClassId: sourceClassId,
          ),
      for (final entry in knownSpells)
        if (_recognizedValue(entry.resolution) != null)
          (
            spellId: _recognizedValue(entry.resolution)!.id,
            status: 'connu',
            sourceClassId: sourceClassId,
          ),
    ];
  }

  /// Résout `armor`/`shield`/`weapons`/`toolEquipment`/`items`/`customItems`
  /// en lignes `character_inventory`. `armor`/`shield` sont exclus quand leur
  /// libellé reconnu correspond à l'emplacement "vide" légitime de leur table
  /// (`AideddReferenceTables.armor[0]`/`.shield[0]`, "Sans armure"/"Sans
  /// bouclier" — un état réel, pas un objet à inventorier, voir la
  /// documentation de classe d'[AideddReferenceTables.armor]) ; sinon, chaque
  /// libellé (reconnu ou non, jamais silencieusement perdu) est recherché par
  /// nom dans [itemCatalog] via [_matchItem] — trouvé -> `item_id` réel, non
  /// trouvé -> `custom_name` (le libellé aidedd lui-même, ou le jeton brut
  /// pour un champ resté non reconnu) : jamais bloquant, voir la
  /// documentation de classe.
  ///
  /// `equipped: true` pour armure/bouclier/armes (portés/en main par
  /// construction dans un export aidedd.org), `false` pour le reste
  /// (outils/objets/objets personnalisés, portés à la main par l'utilisateur
  /// depuis la fiche personnage après import s'il y a lieu) — décision
  /// raisonnable en l'absence d'un indicateur "équipé" dédié dans le format
  /// aidedd.org, signalée ici plutôt qu'improvisée silencieusement.
  static List<XmlImportInventoryLine> _resolveInventoryLines(
    XmlCharacterImportResolved resolved,
    ItemCatalog itemCatalog,
  ) {
    final lines = <XmlImportInventoryLine>[];

    void addLabelLine(
      String? label, {
      required bool equipped,
      required int quantity,
    }) {
      if (label == null) return;
      final match = _matchItem(label, itemCatalog);
      lines.add((
        itemId: match?.id,
        customName: match == null ? label : null,
        quantity: quantity,
        equipped: equipped,
      ));
    }

    final armorLabel = _labelOf(resolved.armor);
    if (armorLabel != null && armorLabel != AideddReferenceTables.armor[0]) {
      addLabelLine(armorLabel, equipped: true, quantity: 1);
    }
    final shieldLabel = _labelOf(resolved.shield);
    if (shieldLabel != null && shieldLabel != AideddReferenceTables.shield[0]) {
      addLabelLine(shieldLabel, equipped: true, quantity: 1);
    }

    for (final entry in resolved.weapons) {
      addLabelLine(
        _labelOf(entry.resolution),
        equipped: true,
        quantity: entry.quantity,
      );
    }
    for (final entry in resolved.toolEquipment) {
      addLabelLine(
        _labelOf(entry.resolution),
        equipped: false,
        quantity: entry.quantity,
      );
    }
    for (final entry in resolved.items) {
      addLabelLine(
        _labelOf(entry.resolution),
        equipped: false,
        quantity: entry.quantity,
      );
    }
    for (final resolution in resolved.customItems) {
      final text = switch (resolution) {
        XmlFieldResolutionCustom<String>(:final text) => text,
        _ => null,
      };
      if (text == null || text.isEmpty) continue;
      lines.add((itemId: null, customName: text, quantity: 1, equipped: false));
    }

    return lines;
  }

  /// Libellé affichable d'un `XmlFieldResolution<String>`, qu'il soit
  /// [XmlFieldResolution.recognized] (libellé aidedd) ou
  /// [XmlFieldResolution.unrecognized] (jeton brut, jamais perdu) — `null`
  /// uniquement pour [XmlFieldResolution.custom] (ne s'applique à aucun des
  /// champs consommés ici) ou un jeton brut vide.
  static String? _labelOf(XmlFieldResolution<String> resolution) {
    final recognized = _recognizedValue(resolution);
    if (recognized != null) return recognized;
    final raw = _rawValueOf(resolution);
    if (raw == null || raw.isEmpty || raw == '(absent)') return null;
    return raw;
  }
}
