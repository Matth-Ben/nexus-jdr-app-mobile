import 'package:freezed_annotation/freezed_annotation.dart';

import '../../character_creation/domain/background_option.dart';
import '../../character_creation/domain/class_option.dart';
import '../../character_creation/domain/language_option.dart';
import '../../character_creation/domain/race_option.dart';
import '../../character_creation/domain/spell_option.dart';
import '../../character_creation/domain/tool_option.dart';
import 'xml_field_resolution.dart';
import 'xml_named_option.dart';
import 'xml_raw_level_entry.dart';

part 'xml_character_import_resolved.freezed.dart';

/// Une ligne d'objet/arme codée résolue (`weapon`+`weaponQ`, `tools`,
/// `item`+`itemQ`) — [resolution] est [XmlFieldResolution.recognized] avec
/// le libellé aidedd (`AideddReferenceTables`), ou
/// [XmlFieldResolution.unrecognized] si l'identifiant est inconnu. Les
/// emplacements vides (identifiant `0`, voir `AideddReferenceTables
/// .weapons`/`.toolsEquipment`/`.items`) n'apparaissent jamais dans les
/// listes qui portent ce type — filtrés en amont par
/// `XmlCharacterImportResolver`, pas au niveau de ce modèle.
typedef XmlQuantifiedResolution = ({
  XmlFieldResolution<String> resolution,
  int quantity,
});

/// Une entrée de sort résolue (`innateSpell`/`knownSpell`) — [level] est le
/// niveau du sort tel qu'exporté (0 = mineur), [resolution] le résultat de
/// la recherche par nom dans le `SpellCatalog` de la classe déjà résolue.
typedef XmlSpellResolution = ({
  int level,
  XmlFieldResolution<SpellOption> resolution,
});

/// Personnage exporté au format XML aidedd.org, après résolution complète
/// (voir `domain/xml_character_import_resolver.dart`) — chaque champ "en
/// clair" ou "codé" du XML brut (`XmlCharacterImportRaw`) est ici soit une
/// valeur simple (champs jamais résolus : textes narratifs, âge, taille...),
/// soit un [XmlFieldResolution] (voir sa documentation pour les 3 états
/// possibles).
///
/// Pas d'écran de vérification/récapitulatif construit sur ce modèle dans
/// cet increment (voir la consigne d'origine de la tâche) : [
/// XmlCharacterImportResolved] est le point d'arrivée de cet increment,
/// prêt à être consommé par l'écran de l'increment suivant.
@freezed
abstract class XmlCharacterImportResolved with _$XmlCharacterImportResolved {
  const factory XmlCharacterImportResolved({
    required XmlFieldResolution<RaceOption> race,

    /// `<raceCustom>` — jamais résolu par nom (voir `XmlCharacterImportRaw
    /// .raceCustom`), passé tel quel pour affichage informatif éventuel.
    String? raceCustomText,
    required XmlFieldResolution<ClassOption> characterClass,

    /// `null` si `<classPath>` est absent/vide du XML (personnage n'ayant
    /// pas encore choisi de sous-classe) — pas un [XmlFieldResolution
    /// .unrecognized], qui signifierait "un nom était présent mais non
    /// reconnu".
    XmlFieldResolution<XmlNamedOption>? subclass,
    required int level,
    required XmlFieldResolution<BackgroundOption> background,
    String? backgroundCustomText,
    required Map<String, int> abilityScores,
    required List<XmlRawLevelEntry> levels,

    /// `<styleCombat1>`/`<styleCombat2>` (Guerrier/Paladin/Rôdeur) — champs
    /// numériques (voir la correction de `xml-import-reference-mapping.md`,
    /// section "styleCombat1/2 et favoredEnemyN sont NUMÉRIQUES, pas
    /// texte") dont la table de correspondance id→nom n'est pas encore
    /// reconstituée (sélecteur verrouillé derrière un compte aidedd.org
    /// premium). Toujours [XmlFieldResolution.unrecognized] avec
    /// l'identifiant brut quand le tag XML est non vide — jamais
    /// [XmlFieldResolution.recognized] (aucune table fiable), jamais
    /// [XmlFieldResolution.custom] (ce n'est pas du texte libre par
    /// construction, contrairement à `itemX`). `null` si le tag est
    /// absent/vide du XML (cas normal pour la plupart des classes/niveaux,
    /// voir les deux fixtures réelles).
    XmlFieldResolution<String>? styleCombat1,
    XmlFieldResolution<String>? styleCombat2,

    /// `<favoredEnemy0>`/`<favoredEnemy6>`/`<favoredEnemy14>` (Rôdeur) —
    /// mêmes règles que [styleCombat1]/[styleCombat2].
    XmlFieldResolution<String>? favoredEnemy0,
    XmlFieldResolution<String>? favoredEnemy6,
    XmlFieldResolution<String>? favoredEnemy14,

    /// `skillsProf`, clé = id de source (0 = race, 1 = classe, 2 =
    /// historique, 3 = autres, voir `AideddReferenceTables
    /// .proficiencySources`) — chaque compétence résolue via
    /// `AideddReferenceTables.skills` (libellé aidedd, pas un `skill_id`
    /// réel de l'app, voir la documentation de classe de
    /// `AideddReferenceTables`).
    required Map<int, List<XmlFieldResolution<String>>> skillProficiencies,

    /// `toolsProf` (déjà en texte clair dans le XML) — résolu par nom contre
    /// le `ToolCatalog` réel de l'app, à la différence de
    /// [skillProficiencies].
    required Map<int, List<XmlFieldResolution<ToolOption>>> toolProficiencies,

    /// `languages` (déjà en texte clair) — résolu par nom contre le
    /// `LanguageCatalog` réel de l'app.
    required Map<int, List<XmlFieldResolution<LanguageOption>>> languages,
    required List<XmlSpellResolution> innateSpells,
    required List<XmlSpellResolution> knownSpells,
    required List<XmlFieldResolution<XmlNamedOption>> knownInvocations,
    required int gp,
    required int pp,
    required int ep,
    required int sp,
    required int cp,
    required XmlFieldResolution<String> armor,
    required XmlFieldResolution<String> shield,

    /// `weapon`+`weaponQ` combinées — les emplacements vides (id `0`) ont
    /// été filtrés (voir la documentation de [XmlQuantifiedResolution]).
    required List<XmlQuantifiedResolution> weapons,

    /// `tools` (objets physiques possédés) — mêmes règles que [weapons],
    /// quantité toujours 1 (pas de liste de quantité dans le XML pour ce
    /// champ).
    required List<XmlQuantifiedResolution> toolEquipment,

    /// `item`+`itemQ` combinées — mêmes règles que [weapons].
    required List<XmlQuantifiedResolution> items,

    /// `itemX` — toujours [XmlFieldResolution.custom], jamais [recognized]
    /// ni [unrecognized] (voir la documentation de classe de
    /// [XmlFieldResolution]).
    required List<XmlFieldResolution<String>> customItems,
    required String name,
    required XmlFieldResolution<String> sexe,
    int? age,
    String? height,
    String? weight,
    required XmlFieldResolution<String> alignment,
    int? xp,
    String? eyes,
    String? skin,
    String? hair,

    /// `<pack>` — `null` si absent du XML, voir la documentation de
    /// `AideddReferenceTables.packs` (traçabilité/validation croisée
    /// uniquement, pas exploité pour reconstruire l'inventaire).
    XmlFieldResolution<String>? pack,
    required String appearanceText,
    required String traitsText,
    required String idealsText,
    required String bondsText,
    required String flawsText,
    required String backstoryText,
    required String alliesText,
    required String featuresText,
    required String treasureText,
  }) = _XmlCharacterImportResolved;
}
