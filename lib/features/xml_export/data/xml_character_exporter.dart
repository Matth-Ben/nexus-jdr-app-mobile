import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../character_creation/domain/ability_score_rules.dart';
import '../../characters/domain/character_detail.dart';
import '../domain/aidedd_reverse_tables.dart';

/// Construit un export XML compatible aidedd.org (`<builder><character>`) à
/// partir d'un [CharacterDetail] — l'inverse de
/// `xml_import/data/xml_character_import_parser.dart` (Phase 3) : un fichier
/// produit par [XmlCharacterExporter.export] doit pouvoir être relu par
/// `XmlCharacterImportParser.parse` (puis résolu par
/// `XmlCharacterImportResolver`/`XmlImportSaveDataResolver`) sans perte sur
/// les champs que [CharacterDetail] modélise réellement — voir
/// `test/features/xml_export/data/xml_character_exporter_round_trip_test.dart`
/// pour la vérification par aller-retour qui sert de garantie principale de
/// correction de ce fichier (bien plus fiable qu'un audit champ par champ).
///
/// [XmlCharacterImportParser]/[XmlCharacterImportResolver] restent la
/// référence figée de ce format (jamais modifiés par ce chantier) : chaque
/// choix ci-dessous a été vérifié contre leur code réel, pas contre une
/// hypothèse sur le format. Les limites de fidélité ci-dessous ne sont donc
/// jamais des oublis, mais des lacunes soit du format aidedd.org lui-même,
/// soit du modèle de lecture actuel de [CharacterDetail] (champs écrits en
/// base mais jamais renvoyés par `CharacterRepository.fetchCharacterDetail`) :
///
/// - **Multiclassage** : le format aidedd.org ne modélise qu'une seule classe
///   par personnage (`<class>`/`<level>` sont des tags uniques, `<lvl>` n'a
///   aucun attribut de classe) — seule la classe primaire
///   ([CharacterDetail.primaryClass]) est exportée. Voir
///   [hasUnsupportedMulticlass], à vérifier par l'appelant *avant* d'appeler
///   [export] pour avertir l'utilisateur (voir
///   `presentation/character_xml_export_action.dart`) plutôt que de produire
///   un fichier silencieusement tronqué.
/// - **PV courants/temporaires** : absents du format aidedd.org lui-même (pas
///   une limite de cet export) — `XmlImportSaveDataResolver` initialise
///   toujours `current_hp = max_hp` et ne connaît pas les PV temporaires à
///   l'import. Un personnage réimporté revient donc toujours "à pleine vie",
///   quel que soit son état réel au moment de l'export.
/// - **Historique de PV par niveau** (`<lvl lvl="X"><hp_brut>`) :
///   [CharacterDetail] n'expose que l'agrégat [CharacterDetail.maxHp]
///   (`character_level_hp`, la table qui porte le détail par niveau, n'est
///   jamais relue par `fetchCharacterDetail`). [_writeLevels] reconstruit un
///   historique synthétique à **une seule entrée** (niveau 1) dont le
///   `hp_brut` est calculé pour que `XmlImportHitPointsCalculator.computeMaxHp`
///   retrouve exactement [CharacterDetail.maxHp] au réimport — voir sa
///   documentation de méthode pour le détail du calcul et son unique cas
///   limite (modificateur de Constitution anormalement élevé par rapport à
///   des PV maximum très bas).
/// - **Augmentations de caractéristiques par niveau** (`<aug_carac0/1/2>`) :
///   toujours `-1` (aucune) — [CharacterDetail] ne garde que le score final
///   par caractéristique, jamais un historique par niveau. Sans conséquence
///   sur la fidélité de l'aller-retour : `XmlCharacterImportResolver`/
///   `XmlImportSaveDataResolver` n'utilisent jamais ces 3 champs pour
///   reconstruire quoi que ce soit (`resolved.abilityScores` vient
///   directement de `raw.abilityScores`, jamais d'un recalcul depuis
///   `levels[].abilityIncreases`).
/// - **Sous-classe** (`<classPath>`), **style de combat**
///   (`<styleCombat1/2>`), **ennemis favoris** (`<favoredEnemy0/6/14>`),
///   **historique personnalisé** (`<backSpe>`), **paquetage de départ**
///   (`<pack>`), **invocations occultistes connues** (`<knownInvocation>`) :
///   jamais exportés (tags toujours absents) — aucun n'est exposé par
///   [CharacterDetail]/`CharacterRepository.fetchCharacterDetail`
///   aujourd'hui, alors même que certains sont bien écrits en base ailleurs
///   (`character_classes.subclass_id`, `character_invocations` — voir
///   `CharacterRepository.applyLevelUp`) : un vrai gap de lecture côté
///   fiche personnage, pas une limite du format d'export lui-même,
///   signalé au chef de projet plutôt que comblé silencieusement par ce
///   chantier (qui ne doit pas étendre `CharacterDetail`/
///   `fetchCharacterDetail`, hors périmètre de la tâche XML).
/// - **Compétences/outils/langues, source** (`id="0..3"` de `skillsProf`/
///   `toolsProf`/`languages`) : [CharacterDetail] ne garde pas trace de la
///   source d'octroi (race/classe/historique/autres) — tout est regroupé
///   sous l'id `3` ("Autres"), purement informatif côté import (jamais
///   utilisé pour la résolution elle-même, voir `XmlImportSaveDataResolver
///   ._resolveSkillLines`/`_resolveToolLines`/`_resolveLanguageIds`, qui
///   fusionnent les 4 groupes sans en garder la provenance) — round-trip
///   exact sur l'ensemble des compétences/outils/langues malgré ce
///   regroupement.
/// - **Maîtrise "expertise"** : le format aidedd.org ne distingue pas
///   "compétente"/"expertise" (limite déjà documentée côté import, voir
///   `XmlImportSaveData.skillProficiencyLines`) — une compétence en
///   expertise redescend en "compétente" au réimport, pas une perte propre à
///   cet export.
/// - **Sorts "préparés"** : `character_spells.status` distingue 'connu'/
///   'préparé'/'inné', mais le format aidedd.org n'a que `<innateSpell>`/
///   `<knownSpell>` — un sort "préparé" est exporté comme `<knownSpell>` et
///   redescend en statut "connu" au réimport (même rationale que
///   l'expertise ci-dessus).
/// - **Objets d'inventaire hors du périmètre fixe d'aidedd.org** (armes
///   exotiques/magiques hors des 39 armes de base, armures/objets non
///   listés dans les 13/99 entrées d'`AideddReferenceTables`...) : repli sur
///   `<itemX>` (texte libre), qui n'a ni quantité ni statut "équipé" dans le
///   format — voir [_writeEquipment]. Un objet dont le nom correspond
///   exactement à une entrée `AideddReferenceTables.weapons`/`.armor`/
///   `.shield`/`.toolsEquipment`/`.items` (comparaison insensible à la
///   casse/aux accents, voir [AideddReverseTables]) conserve en revanche sa
///   quantité exactement (`item`/`itemQ`/`weapon`/`weaponQ`) — seul `tools`
///   n'a jamais de quantité dans le format lui-même (même limite déjà
///   documentée côté import, voir `XmlCharacterImportRaw.toolEquipmentIds`).
/// - **Âge** : [CharacterDetail.age] est un texte libre (`characters.age`
///   est une colonne texte, pas numérique — voir sa documentation de champ),
///   alors qu'`<age>` est strictement numérique dans le format aidedd.org :
///   un âge qui n'est pas un entier pur (ex. "une trentaine d'années") ne
///   peut pas être exporté, voir [_writeIdentity].
/// - **Sexe/alignement non standard** : `characters.sexe` est une colonne
///   texte libre (pas de FK, voir `CharacterDetail.sexe`) et
///   `characters.alignment_id` référence un `AlignmentCatalog` interne dont
///   les libellés ne sont pas garantis identiques aux 9 valeurs fixes
///   d'`AideddReferenceTables.alignments` — un texte qui ne correspond à
///   aucune des valeurs codées attendues par aidedd.org fait retomber le tag
///   correspondant sur l'absence (voir [_writeIdentity]), jamais une valeur
///   fausse.
abstract final class XmlCharacterExporter {
  /// `true` si [detail] a plus d'une classe (`character_classes`,
  /// multiclassage RAW complet supporté par ce dépôt) — le format
  /// aidedd.org ne modélisant qu'une seule classe (voir la documentation de
  /// classe), l'appelant doit avertir l'utilisateur *avant* d'appeler
  /// [export] plutôt que de laisser l'export tronquer silencieusement les
  /// classes secondaires (voir
  /// `presentation/character_xml_export_action.dart`).
  static bool hasUnsupportedMulticlass(CharacterDetail detail) =>
      detail.classes.length > 1;

  /// Le format aidedd.org sépare plusieurs entrées d'un même champ par une
  /// simple virgule (`<itemX>`/`<toolsProf>`/`<languages>`...), sans aucun
  /// mécanisme d'échappement (voir `XmlCharacterImportParser._parseCommaTexts`,
  /// qui redécoupe par `split(',')` sans jamais tenir compte d'une virgule
  /// "littérale") — une limite du format lui-même, pas de ce parseur. Un
  /// texte libre saisi dans l'app (nom d'objet personnalisé, maîtrise d'outil
  /// personnalisée) PEUT contenir une virgule, ce qui scinderait
  /// silencieusement une seule entrée en deux au réimport — pire que la perte
  /// de fidélité déjà documentée ailleurs dans ce fichier, car invisible et
  /// corruptrice de données plutôt qu'une simple omission. Remplace toute
  /// virgule par un point-virgule avant jointure : substitution visible et
  /// non corruptrice (préférée à un rejet du champ), jamais appliquée aux
  /// identifiants numériques déjà générés par ce fichier (qui ne peuvent
  /// structurellement pas contenir de virgule).
  static String _sanitizeForCommaJoin(String value) =>
      value.replaceAll(',', ';');

  /// Construit le document XML complet, joliment indenté (`pretty: true`,
  /// même lisibilité qu'un export réel aidedd.org) — jamais d'exception :
  /// tous les champs de [detail] sont déjà des types simples (`String`/`int`/
  /// `List`/`Map`), aucune conversion ci-dessous ne peut échouer autrement
  /// que par un repli documenté (voir la documentation de classe).
  static String export(CharacterDetail detail) {
    final builder = XmlBuilder();
    builder.element(
      'builder',
      nest: () {
        builder.element(
          'character',
          nest: () {
            _writeIdentity(builder, detail);
            _writeAbilityScores(builder, detail);
            _writeLevels(builder, detail);
            _writeProficiencies(builder, detail);
            _writeSpells(builder, detail);
            _writeCurrency(builder, detail);
            _writeEquipment(builder, detail);
            _writeAppearanceAndStory(builder, detail);
          },
        );
      },
    );
    return builder.buildDocument().toXmlString(pretty: true);
  }

  static void _writeIdentity(XmlBuilder builder, CharacterDetail detail) {
    builder.element('name', nest: detail.name);

    // Race : `<race>` doit toujours être présent pour que
    // `XmlCharacterImportParser.parse` accepte le fichier (voir sa
    // documentation, "informations minimales") ; le contenu texte peut en
    // revanche rester vide sans faire échouer le parsing (seule l'absence du
    // tag lui-même est bloquante). Une race entièrement personnalisée
    // (`raceName` nul, voir sa documentation de champ) exporte son texte
    // libre à la fois dans `<race>` (pour ne jamais laisser le tag vide) et
    // dans `<raceCustom>` (passthrough informatif exact, jamais résolu par
    // nom au réimport — voir `XmlCharacterImportRaw.raceCustom`) : `<race>`
    // ressortira alors `unrecognized` au réimport, cohérent avec le fait que
    // ce texte n'a jamais été un nom de race du catalogue.
    final raceName = detail.raceName;
    final raceCustomText = detail.raceCustomText;
    builder.element('race', nest: raceName ?? raceCustomText ?? '');
    if (raceCustomText != null && raceCustomText.isNotEmpty) {
      builder.element('raceCustom', nest: raceCustomText);
    }

    final primaryClass = detail.primaryClass;
    builder.element('class', nest: primaryClass?.className ?? '');
    // `<classPath>` (sous-classe) jamais exporté : voir la documentation de
    // classe ("gap de lecture", `character_classes.subclass_id` n'est jamais
    // renvoyé par `fetchCharacterDetail`).
    builder.element(
      'level',
      nest: (primaryClass?.level ?? math.max(detail.totalLevel, 1)).toString(),
    );
    builder.element('background', nest: detail.backgroundName ?? '');
    // `<backSpe>` jamais exporté : voir la documentation de classe
    // (`CharacterDetail` ne modélise pas d'équivalent de
    // `characters.background_custom_text`).

    builder.element('xp', nest: detail.xp.toString());

    final sexeId = AideddReverseTables.lookup(
      AideddReverseTables.sexes,
      detail.sexe,
    );
    if (sexeId != null) builder.element('sexe', nest: sexeId.toString());

    final age = int.tryParse(detail.age.trim());
    if (age != null) builder.element('age', nest: age.toString());

    if (detail.height.isNotEmpty) {
      builder.element('height', nest: detail.height);
    }
    if (detail.weight.isNotEmpty) {
      builder.element('weight', nest: detail.weight);
    }
    if (detail.eyes.isNotEmpty) builder.element('eyes', nest: detail.eyes);
    if (detail.skin.isNotEmpty) builder.element('skin', nest: detail.skin);
    if (detail.hair.isNotEmpty) builder.element('hair', nest: detail.hair);

    final alignmentId = AideddReverseTables.lookup(
      AideddReverseTables.alignments,
      detail.alignmentName,
    );
    if (alignmentId != null) {
      builder.element('alignment', nest: alignmentId.toString());
    }
  }

  static void _writeAbilityScores(XmlBuilder builder, CharacterDetail detail) {
    for (final key in const ['str', 'dex', 'con', 'int', 'wis', 'cha']) {
      builder.element(key, nest: (detail.abilityScores[key] ?? 10).toString());
    }
  }

  /// Voir la documentation de classe pour le rationale complet (historique de
  /// PV synthétique à une seule entrée). Le modificateur de Constitution est
  /// recalculé depuis [CharacterDetail.abilityScores] (les mêmes valeurs
  /// exportées par [_writeAbilityScores]) via
  /// `AbilityScoreRules.abilityModifier`, exactement la formule utilisée par
  /// `XmlImportHitPointsCalculator.computeMaxHp` au réimport — garantit que
  /// `characters.max_hp` retrouve exactement [CharacterDetail.maxHp], sauf
  /// dans le seul cas limite où `maxHp - modificateurConstitution <= 0`
  /// (modificateur de Constitution anormalement élevé par rapport à des PV
  /// maximum très bas, ne devrait jamais arriver avec des données RAW
  /// valides) : `hp_brut` est alors plancher à 1, comme
  /// `XmlImportHitPointsCalculator.computeMaxHp` elle-même le fait pour le
  /// total final.
  static void _writeLevels(XmlBuilder builder, CharacterDetail detail) {
    final constitutionModifier = AbilityScoreRules.abilityModifier(
      detail.abilityScores['con'] ?? 10,
    );
    final hpBrut = math.max(1, detail.maxHp - constitutionModifier);
    builder.element(
      'lvl',
      attributes: {'lvl': '1'},
      nest: () {
        builder.element('hp_brut', nest: hpBrut.toString());
        builder.element('aug_carac0', nest: '-1');
        builder.element('aug_carac1', nest: '-1');
        builder.element('aug_carac2', nest: '-1');
      },
    );
  }

  /// `skillsProf`/`toolsProf`/`languages` : tout regroupé sous l'id `3`
  /// ("Autres", `AideddReferenceTables.proficiencySources`) — voir la
  /// documentation de classe pour le rationale (source d'octroi non
  /// modélisée par [CharacterDetail], sans impact sur le round-trip du
  /// contenu lui-même).
  static void _writeProficiencies(XmlBuilder builder, CharacterDetail detail) {
    final skillIds = <int>[];
    for (final skill in detail.skills) {
      if (skill.proficiency == 'aucune') continue;
      final id = AideddReverseTables.lookup(
        AideddReverseTables.skills,
        skill.name,
      );
      // Une compétence du catalogue interne qui ne correspond à aucune des
      // 18 entrées d'`AideddReferenceTables.skills` ne devrait jamais
      // arriver (les 18 compétences D&D 5e sont fixes) — omise plutôt que de
      // planter si jamais un libellé divergeait un jour.
      if (id != null) skillIds.add(id);
    }
    if (skillIds.isNotEmpty) {
      builder.element(
        'skillsProf',
        attributes: {'id': '3'},
        nest: skillIds.join(','),
      );
    }

    if (detail.toolProficiencyNames.isNotEmpty) {
      builder.element(
        'toolsProf',
        attributes: {'id': '3'},
        nest: detail.toolProficiencyNames.map(_sanitizeForCommaJoin).join(','),
      );
    }

    if (detail.knownLanguageNames.isNotEmpty) {
      builder.element(
        'languages',
        attributes: {'id': '3'},
        nest: detail.knownLanguageNames.map(_sanitizeForCommaJoin).join(','),
      );
    }
    // `<knownInvocation>` jamais exporté : voir la documentation de classe
    // ("gap de lecture", `character_invocations` n'est jamais renvoyé par
    // `fetchCharacterDetail`).
  }

  /// Un sort "préparé" (`status == 'préparé'`) est exporté comme
  /// `<knownSpell>`, exactement comme un sort "connu" — voir la
  /// documentation de classe (limite du format lui-même, déjà présente côté
  /// import).
  static void _writeSpells(XmlBuilder builder, CharacterDetail detail) {
    for (final spell in detail.spells) {
      final tagName = spell.status == 'inné' ? 'innateSpell' : 'knownSpell';
      builder.element(
        tagName,
        attributes: {'lvl': spell.level.toString()},
        nest: spell.name,
      );
    }
  }

  static void _writeCurrency(XmlBuilder builder, CharacterDetail detail) {
    builder.element('gp', nest: detail.currencyGp.toString());
    builder.element('pp', nest: detail.currencyPp.toString());
    builder.element('ep', nest: detail.currencyEp.toString());
    builder.element('sp', nest: detail.currencySp.toString());
    builder.element('cp', nest: detail.currencyCp.toString());
  }

  /// Répartit [CharacterDetail.inventory] entre les champs "codés"
  /// positionnels du format (`armor`/`shield`/`weapon`+`weaponQ`/`tools`/
  /// `item`+`itemQ`) quand le nom de l'objet correspond exactement (voir
  /// [AideddReverseTables]) à une entrée `AideddReferenceTables`
  /// correspondante, et sur `<itemX>` (texte libre, une entrée par objet non
  /// reconnu, quantité/statut équipé perdus — voir la documentation de
  /// classe) sinon. `armor`/`shield` n'acceptent qu'un seul objet chacun :
  /// seul le premier objet équipé de cette catégorie rencontré est retenu
  /// pour le tag codé, tout objet supplémentaire de la même catégorie (donnée
  /// incohérente, ne devrait pas arriver pour une armure/un bouclier)
  /// retombe sur `<itemX>` comme un objet non reconnu.
  static void _writeEquipment(XmlBuilder builder, CharacterDetail detail) {
    int? armorId;
    int? shieldId;
    final weaponIds = <String>[];
    final weaponQuantities = <String>[];
    final toolIds = <String>[];
    final itemIds = <String>[];
    final itemQuantities = <String>[];
    final customTexts = <String>[];

    for (final item in detail.inventory) {
      switch (item.category) {
        case 'armure' when item.equipped && armorId == null:
          final id = AideddReverseTables.lookup(
            AideddReverseTables.armor,
            item.name,
          );
          if (id != null) {
            armorId = id;
          } else {
            customTexts.add(item.name);
          }
        case 'bouclier' when item.equipped && shieldId == null:
          final id = AideddReverseTables.lookup(
            AideddReverseTables.shield,
            item.name,
          );
          if (id != null) {
            shieldId = id;
          } else {
            customTexts.add(item.name);
          }
        case 'arme':
          final id = AideddReverseTables.lookup(
            AideddReverseTables.weapons,
            item.name,
          );
          if (id != null) {
            weaponIds.add(id.toString());
            weaponQuantities.add(item.quantity.toString());
          } else {
            customTexts.add(item.name);
          }
        case 'outil':
          final id = AideddReverseTables.lookup(
            AideddReverseTables.toolsEquipment,
            item.name,
          );
          if (id != null) {
            toolIds.add(id.toString());
          } else {
            customTexts.add(item.name);
          }
        default:
          // `equipement_general`/`objet_magique`/`monture_vehicule`/`null`
          // (objet personnalisé), et toute armure/bouclier en surplus (voir
          // la documentation de méthode).
          final id = AideddReverseTables.lookup(
            AideddReverseTables.items,
            item.name,
          );
          if (id != null) {
            itemIds.add(id.toString());
            itemQuantities.add(item.quantity.toString());
          } else {
            customTexts.add(item.name);
          }
      }
    }

    builder.element('armor', nest: (armorId ?? 0).toString());
    builder.element('shield', nest: (shieldId ?? 0).toString());
    if (weaponIds.isNotEmpty) {
      builder.element('weapon', nest: weaponIds.join(','));
      builder.element('weaponQ', nest: weaponQuantities.join(','));
    }
    if (toolIds.isNotEmpty) {
      builder.element('tools', nest: toolIds.join(','));
    }
    if (itemIds.isNotEmpty) {
      builder.element('item', nest: itemIds.join(','));
      builder.element('itemQ', nest: itemQuantities.join(','));
    }
    if (customTexts.isNotEmpty) {
      builder.element(
        'itemX',
        nest: customTexts.map(_sanitizeForCommaJoin).join(','),
      );
    }
  }

  static void _writeAppearanceAndStory(
    XmlBuilder builder,
    CharacterDetail detail,
  ) {
    builder.element('appearance', nest: detail.appearanceText);
    builder.element('traits', nest: detail.traitsText);
    builder.element('ideals', nest: detail.idealsText);
    builder.element('bonds', nest: detail.bondsText);
    builder.element('flaws', nest: detail.flawsText);
    builder.element('backstory', nest: detail.backstoryText);
    builder.element('allies', nest: detail.alliesText);
    builder.element('features', nest: detail.featuresText);
    builder.element('treasure', nest: detail.treasureText);
  }
}
