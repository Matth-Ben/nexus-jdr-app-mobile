import 'package:freezed_annotation/freezed_annotation.dart';

import 'xml_raw_level_entry.dart';
import 'xml_raw_spell_entry.dart';

part 'xml_character_import_raw.freezed.dart';

/// Personnage exporté au format XML aidedd.org (`<builder><character>`),
/// après parsing pur (`data/xml_character_import_parser.dart`) mais avant
/// toute résolution (`domain/xml_character_import_resolver.dart`) — reflète
/// fidèlement la structure du XML, tags à plat, voir le tableau
/// champ-par-champ complet de
/// `docs/cahier-des-charges/03-import-xml-aidedd.md`.
///
/// Champs volontairement laissés à l'état brut ici (`int`/`String`/`List`
/// bruts, jamais un identifiant Supabase ni une entrée de catalogue) : la
/// résolution "en clair" (race/classe/sous-classe/historique/sorts/
/// invocations/langues) et "codée" (compétences/armure/bouclier/armes/
/// outils physiques/objets/alignement/sexe) est entièrement portée par
/// `XmlCharacterImportResolver`, jamais mélangée au parsing — pour garder
/// [XmlCharacterImportRaw] testable indépendamment de tout catalogue.
///
/// Un tag XML absent ou vide retombe systématiquement sur une valeur neutre
/// (`null`/liste vide/`0`) plutôt que de faire échouer tout le parsing — cas
/// normal et fréquent dans un export réel (voir les deux fixtures de
/// `test/fixtures/xml_import/`, ex. `<classPath>` absent pour un personnage
/// n'ayant pas encore choisi de sous-classe).
@freezed
abstract class XmlCharacterImportRaw with _$XmlCharacterImportRaw {
  const factory XmlCharacterImportRaw({
    required String race,

    /// `<raceCustom>` — flag brut non interprété, voir
    /// `xml-import-reference-mapping.md` section "Point encore ouvert :
    /// raceCustom" (son sens exact reste incertain, traité comme informatif
    /// par [XmlCharacterImportResolver], jamais bloquant).
    String? raceCustom,

    /// `<class>` — champ nommé `characterClass` plutôt que `class`, mot
    /// réservé Dart.
    required String characterClass,

    /// `<classPath>` — `null` si absent du XML (personnage n'ayant pas
    /// encore choisi de sous-classe), jamais une chaîne vide.
    String? classPath,
    required int level,
    required String background,

    /// `<backSpe>` — note libre d'historique personnalisé, jamais résolue
    /// par nom (ce n'est pas un nom d'historique, juste un complément
    /// textuel).
    String? backSpe,

    /// `<str>`,`<dex>`,`<con>`,`<int>`,`<wis>`,`<cha>`, clés `'str'`/`'dex'`/
    /// `'con'`/`'int'`/`'wis'`/`'cha'` — même convention de clés que
    /// `CharacterCreationDraft.abilityScores`.
    required Map<String, int> abilityScores,

    /// `<lvl lvl="X">` — une entrée par niveau présent dans le XML (20 dans
    /// les deux fixtures réelles, 1 à 20).
    required List<XmlRawLevelEntry> levels,
    String? styleCombat1,
    String? styleCombat2,
    String? favoredEnemy0,
    String? favoredEnemy6,
    String? favoredEnemy14,

    /// `<pack>` — `null` si absent du XML.
    int? pack,

    /// `<skillsProf id="0..3">` — clé = id de source (0 = race, 1 = classe,
    /// 2 = historique, 3 = autres, voir `AideddReferenceTables
    /// .proficiencySources`), valeur = liste de jetons bruts (identifiants de
    /// compétence attendus, `AideddReferenceTables.skills`), **en `String`
    /// non encore parsée en `int`** — un jeton corrompu/non numérique
    /// (export malformé) doit rester distinguable d'un identifiant `0`
    /// légitime plutôt que d'être silencieusement confondu avec lui par un
    /// repli `int.tryParse(...) ?? 0` au parsing (voir la revue QA de
    /// l'increment 1 : un tel repli ferait disparaître l'entrée corrompue au
    /// lieu de la remonter `unrecognized`, voir `XmlCodedFieldResolver
    /// .resolveByRawToken`). Une entrée manquante pour un id équivaut à une
    /// liste vide.
    required Map<int, List<String>> skillsProf,

    /// `<toolsProf id="0..3">` — déjà en texte clair (noms d'outils), à la
    /// différence de `skillsProf`, voir la documentation de classe.
    required Map<int, List<String>> toolsProf,

    /// `<languages id="0..3">` — déjà en texte clair (noms de langues).
    required Map<int, List<String>> languages,
    @Default(<XmlRawSpellEntry>[]) List<XmlRawSpellEntry> innateSpells,
    @Default(<XmlRawSpellEntry>[]) List<XmlRawSpellEntry> knownSpells,

    /// `<knownInvocation>` — noms d'invocations occultes en clair, liste
    /// vide si le personnage n'en a aucune (cas normal pour toute classe
    /// autre qu'Occultiste).
    @Default(<String>[]) List<String> knownInvocations,
    required int gp,
    required int pp,
    required int ep,
    required int sp,
    required int cp,

    /// `<armor>` — `null` si absent du XML (ne devrait pas arriver sur un
    /// export réel, ce tag existe toujours, mais un défaut défensif reste
    /// préférable à une exception de parsing).
    int? armor,
    int? shield,

    /// `<weapon>` — liste positionnelle de jetons bruts (identifiants
    /// d'arme attendus, non encore parsés en `int`, même rationale que
    /// [skillsProf]), voir [weaponQuantities] (même index = même arme,
    /// `AideddReferenceTables.weapons`).
    @Default(<String>[]) List<String> weaponIds,
    @Default(<int>[]) List<int> weaponQuantities,

    /// `<tools>` — objets physiques possédés (positionnel, jetons bruts non
    /// encore parsés, sans liste de quantité dédiée dans le XML, quantité
    /// toujours 1), *différent* de [toolsProf] — voir `AideddReferenceTables
    /// .toolsEquipment`.
    @Default(<String>[]) List<String> toolEquipmentIds,

    /// `<item>`/`<itemQ>` — listes positionnelles (jetons bruts non encore
    /// parsés pour les identifiants, `AideddReferenceTables.items`).
    @Default(<String>[]) List<String> itemIds,
    @Default(<int>[]) List<int> itemQuantities,

    /// `<itemX>` — objets personnalisés en texte libre, séparés par
    /// virgules dans le XML, déjà éclatés ici en liste. Pas positionnel par
    /// rapport à [itemIds]/[itemQuantities] (nombre d'entrées différent,
    /// voir `docs/xml-import-reference-mapping.md`).
    @Default(<String>[]) List<String> customItemTexts,
    required String name,

    /// `<sexe>` — `null` si absent du XML.
    int? sexe,
    int? age,
    String? height,
    String? weight,

    /// `<alignment>` — `null` si absent du XML.
    int? alignment,
    int? xp,
    String? eyes,
    String? skin,
    String? hair,
    @Default('') String appearanceText,
    @Default('') String traitsText,
    @Default('') String idealsText,
    @Default('') String bondsText,
    @Default('') String flawsText,
    @Default('') String backstoryText,
    @Default('') String alliesText,
    @Default('') String featuresText,
    @Default('') String treasureText,
  }) = _XmlCharacterImportRaw;
}
