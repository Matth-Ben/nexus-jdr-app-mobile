import 'package:xml/xml.dart';

import '../domain/xml_character_import_raw.dart';
import '../domain/xml_import_parse_result.dart';
import '../domain/xml_raw_level_entry.dart';
import '../domain/xml_raw_spell_entry.dart';

/// Parse un export XML aidedd.org (racine `builder`/`character`) en
/// [XmlCharacterImportRaw] — pur parsing, aucune résolution
/// (voir `domain/xml_character_import_resolver.dart` pour l'étape
/// suivante).
///
/// [parse] ne lance jamais d'exception : tout XML illisible ou de structure
/// non reconnue retombe sur [XmlImportParseResult.failure] plutôt que de
/// laisser une [XmlParserException]/[FormatException] remonter jusqu'à
/// l'appelant (voir `docs/cahier-des-charges/03-import-xml-aidedd.md`).
abstract final class XmlCharacterImportParser {
  static XmlImportParseResult parse(String xmlSource) {
    final XmlDocument document;
    final XmlElement root;
    try {
      document = XmlDocument.parse(xmlSource);
      root = document.rootElement;
    } catch (_) {
      return const XmlImportParseResult.failure(
        'Ce fichier n\'est pas un XML valide.',
      );
    }

    if (root.name.local != 'builder') {
      return const XmlImportParseResult.failure(
        'Ce fichier ne semble pas être un export aidedd.org '
        '(racine <builder> introuvable).',
      );
    }

    final character = root.getElement('character');
    if (character == null) {
      return const XmlImportParseResult.failure(
        'Ce fichier ne semble pas être un export aidedd.org '
        '(balise <character> introuvable).',
      );
    }

    final name = _text(character, 'name');
    final race = _text(character, 'race');
    final characterClass = _text(character, 'class');
    final background = _text(character, 'background');
    if (name == null ||
        race == null ||
        characterClass == null ||
        background == null) {
      return const XmlImportParseResult.failure(
        'Ce fichier ne contient pas les informations minimales d\'un '
        'personnage (nom, race, classe, historique).',
      );
    }

    // Pas de try/catch ici (contrairement à une version précédente) : tous
    // les helpers ci-dessous (`_text`/`_optionalText`/`_int`/
    // `_parseCommaTexts`/`_parseIndexedTextLists`/`_parseLevels`/
    // `_parseSpells`/`_parseTextList`) sont déjà défensifs par construction
    // (jamais de `!`, toujours un repli `null`/liste vide), donc la
    // construction de [XmlCharacterImportRaw] ci-dessous ne peut pas lancer
    // d'exception — un try/catch autour n'aurait jamais été atteignable en
    // pratique (relevé en revue de code de l'increment 1) — voir [parse]
    // pour le seul point d'entrée qui peut réellement échouer (XML
    // illisible, structure `<builder><character>` absente).
    final raw = XmlCharacterImportRaw(
      race: race,
      raceCustom: _optionalText(character, 'raceCustom'),
      characterClass: characterClass,
      classPath: _optionalText(character, 'classPath'),
      level: _int(character, 'level') ?? 1,
      background: background,
      backSpe: _optionalText(character, 'backSpe'),
      abilityScores: {
        'str': _int(character, 'str') ?? 0,
        'dex': _int(character, 'dex') ?? 0,
        'con': _int(character, 'con') ?? 0,
        'int': _int(character, 'int') ?? 0,
        'wis': _int(character, 'wis') ?? 0,
        'cha': _int(character, 'cha') ?? 0,
      },
      levels: _parseLevels(character),
      styleCombat1: _optionalText(character, 'styleCombat1'),
      styleCombat2: _optionalText(character, 'styleCombat2'),
      favoredEnemy0: _optionalText(character, 'favoredEnemy0'),
      favoredEnemy6: _optionalText(character, 'favoredEnemy6'),
      favoredEnemy14: _optionalText(character, 'favoredEnemy14'),
      pack: _int(character, 'pack'),
      skillsProf: _parseIndexedTextLists(character, 'skillsProf'),
      toolsProf: _parseIndexedTextLists(character, 'toolsProf'),
      languages: _parseIndexedTextLists(character, 'languages'),
      innateSpells: _parseSpells(character, 'innateSpell'),
      knownSpells: _parseSpells(character, 'knownSpell'),
      knownInvocations: _parseTextList(character, 'knownInvocation'),
      gp: _int(character, 'gp') ?? 0,
      pp: _int(character, 'pp') ?? 0,
      ep: _int(character, 'ep') ?? 0,
      sp: _int(character, 'sp') ?? 0,
      cp: _int(character, 'cp') ?? 0,
      armor: _int(character, 'armor'),
      shield: _int(character, 'shield'),
      weaponIds: _parseCommaTexts(_text(character, 'weapon')),
      weaponQuantities: _parseCommaInts(_text(character, 'weaponQ')),
      toolEquipmentIds: _parseCommaTexts(_text(character, 'tools')),
      itemIds: _parseCommaTexts(_text(character, 'item')),
      itemQuantities: _parseCommaInts(_text(character, 'itemQ')),
      customItemTexts: _parseCommaTexts(_text(character, 'itemX')),
      name: name,
      sexe: _int(character, 'sexe'),
      age: _int(character, 'age'),
      height: _optionalText(character, 'height'),
      weight: _optionalText(character, 'weight'),
      alignment: _int(character, 'alignment'),
      xp: _int(character, 'xp'),
      eyes: _optionalText(character, 'eyes'),
      skin: _optionalText(character, 'skin'),
      hair: _optionalText(character, 'hair'),
      appearanceText: _text(character, 'appearance') ?? '',
      traitsText: _text(character, 'traits') ?? '',
      idealsText: _text(character, 'ideals') ?? '',
      bondsText: _text(character, 'bonds') ?? '',
      flawsText: _text(character, 'flaws') ?? '',
      backstoryText: _text(character, 'backstory') ?? '',
      alliesText: _text(character, 'allies') ?? '',
      featuresText: _text(character, 'features') ?? '',
      treasureText: _text(character, 'treasure') ?? '',
    );
    return XmlImportParseResult.success(raw);
  }

  static List<XmlRawLevelEntry> _parseLevels(XmlElement character) {
    return [
      for (final element in character.findElements('lvl'))
        XmlRawLevelEntry(
          level: int.tryParse(element.getAttribute('lvl') ?? '') ?? 0,
          hpBrut: _int(element, 'hp_brut') ?? 0,
          abilityIncreases: [
            _int(element, 'aug_carac0') ?? -1,
            _int(element, 'aug_carac1') ?? -1,
            _int(element, 'aug_carac2') ?? -1,
          ],
        ),
    ];
  }

  static List<XmlRawSpellEntry> _parseSpells(
    XmlElement character,
    String tagName,
  ) {
    return [
      for (final element in character.findElements(tagName))
        if (element.innerText.trim().isNotEmpty)
          XmlRawSpellEntry(
            level: int.tryParse(element.getAttribute('lvl') ?? '') ?? 0,
            name: element.innerText.trim(),
          ),
    ];
  }

  static List<String> _parseTextList(XmlElement character, String tagName) {
    return [
      for (final element in character.findElements(tagName))
        if (element.innerText.trim().isNotEmpty) element.innerText.trim(),
    ];
  }

  /// `<skillsProf id="0..3">12,4</skillsProf>` répétées → `{0: ['12', '4']}`
  /// — mêmes valeurs que `toolsProf`/`languages` en apparence (jetons bruts
  /// en `String`), mais `skillsProf` reste un champ "codé" : ses jetons sont
  /// des identifiants numériques attendus, pas des noms, résolus par
  /// `XmlCodedFieldResolver.resolveByRawToken` (voir la documentation de
  /// `XmlCharacterImportRaw.skillsProf` pour le rationale de ce choix de
  /// type). Un id absent du XML n'apparaît pas dans la map (l'appelant
  /// traite l'absence comme une liste vide).
  static Map<int, List<String>> _parseIndexedTextLists(
    XmlElement character,
    String tagName,
  ) {
    final result = <int, List<String>>{};
    for (final element in character.findElements(tagName)) {
      final id = int.tryParse(element.getAttribute('id') ?? '');
      if (id == null) continue;
      result[id] = _parseCommaTexts(element.innerText);
    }
    return result;
  }

  /// Réservé aux listes de **quantités** (`weaponQ`/`itemQ`) : un jeton
  /// corrompu y retombe sur `0` sans conséquence grave (juste une quantité
  /// fausse, jamais une identité d'objet perdue). **Ne pas** l'utiliser pour
  /// une liste d'identifiants codés (`weapon`/`tools`/`item`/`skillsProf`) —
  /// voir [_parseCommaTexts]/[_parseIndexedTextLists], qui préservent le
  /// jeton brut pour que `XmlCodedFieldResolver.resolveByRawToken` puisse le
  /// distinguer d'un `0` légitime ("emplacement vide") plutôt que de le
  /// confondre silencieusement avec lui (bug relevé en revue QA de
  /// l'increment 1, voir `XmlCharacterImportRaw.skillsProf`).
  static List<int> _parseCommaInts(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty) int.tryParse(part.trim()) ?? 0,
    ];
  }

  static List<String> _parseCommaTexts(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static String? _text(XmlElement parent, String tagName) {
    final element = parent.getElement(tagName);
    if (element == null) return null;
    final text = element.innerText.trim();
    return text;
  }

  /// Comme [_text], mais retourne `null` (plutôt qu'une chaîne vide) pour un
  /// tag présent mais vide — utilisé pour tous les champs optionnels où
  /// "absent" et "vide" doivent être traités de la même façon par
  /// [XmlCharacterImportRaw].
  static String? _optionalText(XmlElement parent, String tagName) {
    final text = _text(parent, tagName);
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static int? _int(XmlElement parent, String tagName) {
    final text = _text(parent, tagName);
    if (text == null || text.isEmpty) return null;
    return int.tryParse(text);
  }
}
