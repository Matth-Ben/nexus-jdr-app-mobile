// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'xml_character_import_resolved.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$XmlCharacterImportResolved {

 XmlFieldResolution<RaceOption> get race;/// `<raceCustom>` — jamais résolu par nom (voir `XmlCharacterImportRaw
/// .raceCustom`), passé tel quel pour affichage informatif éventuel.
 String? get raceCustomText; XmlFieldResolution<ClassOption> get characterClass;/// `null` si `<classPath>` est absent/vide du XML (personnage n'ayant
/// pas encore choisi de sous-classe) — pas un [XmlFieldResolution
/// .unrecognized], qui signifierait "un nom était présent mais non
/// reconnu".
 XmlFieldResolution<XmlNamedOption>? get subclass; int get level; XmlFieldResolution<BackgroundOption> get background; String? get backgroundCustomText; Map<String, int> get abilityScores; List<XmlRawLevelEntry> get levels;/// `<styleCombat1>`/`<styleCombat2>` (Guerrier/Paladin/Rôdeur) — champs
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
 XmlFieldResolution<String>? get styleCombat1; XmlFieldResolution<String>? get styleCombat2;/// `<favoredEnemy0>`/`<favoredEnemy6>`/`<favoredEnemy14>` (Rôdeur) —
/// mêmes règles que [styleCombat1]/[styleCombat2].
 XmlFieldResolution<String>? get favoredEnemy0; XmlFieldResolution<String>? get favoredEnemy6; XmlFieldResolution<String>? get favoredEnemy14;/// `skillsProf`, clé = id de source (0 = race, 1 = classe, 2 =
/// historique, 3 = autres, voir `AideddReferenceTables
/// .proficiencySources`) — chaque compétence résolue via
/// `AideddReferenceTables.skills` (libellé aidedd, pas un `skill_id`
/// réel de l'app, voir la documentation de classe de
/// `AideddReferenceTables`).
 Map<int, List<XmlFieldResolution<String>>> get skillProficiencies;/// `toolsProf` (déjà en texte clair dans le XML) — résolu par nom contre
/// le `ToolCatalog` réel de l'app, à la différence de
/// [skillProficiencies].
 Map<int, List<XmlFieldResolution<ToolOption>>> get toolProficiencies;/// `languages` (déjà en texte clair) — résolu par nom contre le
/// `LanguageCatalog` réel de l'app.
 Map<int, List<XmlFieldResolution<LanguageOption>>> get languages; List<XmlSpellResolution> get innateSpells; List<XmlSpellResolution> get knownSpells; List<XmlFieldResolution<XmlNamedOption>> get knownInvocations; int get gp; int get pp; int get ep; int get sp; int get cp; XmlFieldResolution<String> get armor; XmlFieldResolution<String> get shield;/// `weapon`+`weaponQ` combinées — les emplacements vides (id `0`) ont
/// été filtrés (voir la documentation de [XmlQuantifiedResolution]).
 List<XmlQuantifiedResolution> get weapons;/// `tools` (objets physiques possédés) — mêmes règles que [weapons],
/// quantité toujours 1 (pas de liste de quantité dans le XML pour ce
/// champ).
 List<XmlQuantifiedResolution> get toolEquipment;/// `item`+`itemQ` combinées — mêmes règles que [weapons].
 List<XmlQuantifiedResolution> get items;/// `itemX` — toujours [XmlFieldResolution.custom], jamais [recognized]
/// ni [unrecognized] (voir la documentation de classe de
/// [XmlFieldResolution]).
 List<XmlFieldResolution<String>> get customItems; String get name; XmlFieldResolution<String> get sexe; int? get age; String? get height; String? get weight; XmlFieldResolution<String> get alignment; int? get xp; String? get eyes; String? get skin; String? get hair;/// `<pack>` — `null` si absent du XML, voir la documentation de
/// `AideddReferenceTables.packs` (traçabilité/validation croisée
/// uniquement, pas exploité pour reconstruire l'inventaire).
 XmlFieldResolution<String>? get pack; String get appearanceText; String get traitsText; String get idealsText; String get bondsText; String get flawsText; String get backstoryText; String get alliesText; String get featuresText; String get treasureText;
/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlCharacterImportResolvedCopyWith<XmlCharacterImportResolved> get copyWith => _$XmlCharacterImportResolvedCopyWithImpl<XmlCharacterImportResolved>(this as XmlCharacterImportResolved, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlCharacterImportResolved&&(identical(other.race, race) || other.race == race)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.characterClass, characterClass) || other.characterClass == characterClass)&&(identical(other.subclass, subclass) || other.subclass == subclass)&&(identical(other.level, level) || other.level == level)&&(identical(other.background, background) || other.background == background)&&(identical(other.backgroundCustomText, backgroundCustomText) || other.backgroundCustomText == backgroundCustomText)&&const DeepCollectionEquality().equals(other.abilityScores, abilityScores)&&const DeepCollectionEquality().equals(other.levels, levels)&&(identical(other.styleCombat1, styleCombat1) || other.styleCombat1 == styleCombat1)&&(identical(other.styleCombat2, styleCombat2) || other.styleCombat2 == styleCombat2)&&(identical(other.favoredEnemy0, favoredEnemy0) || other.favoredEnemy0 == favoredEnemy0)&&(identical(other.favoredEnemy6, favoredEnemy6) || other.favoredEnemy6 == favoredEnemy6)&&(identical(other.favoredEnemy14, favoredEnemy14) || other.favoredEnemy14 == favoredEnemy14)&&const DeepCollectionEquality().equals(other.skillProficiencies, skillProficiencies)&&const DeepCollectionEquality().equals(other.toolProficiencies, toolProficiencies)&&const DeepCollectionEquality().equals(other.languages, languages)&&const DeepCollectionEquality().equals(other.innateSpells, innateSpells)&&const DeepCollectionEquality().equals(other.knownSpells, knownSpells)&&const DeepCollectionEquality().equals(other.knownInvocations, knownInvocations)&&(identical(other.gp, gp) || other.gp == gp)&&(identical(other.pp, pp) || other.pp == pp)&&(identical(other.ep, ep) || other.ep == ep)&&(identical(other.sp, sp) || other.sp == sp)&&(identical(other.cp, cp) || other.cp == cp)&&(identical(other.armor, armor) || other.armor == armor)&&(identical(other.shield, shield) || other.shield == shield)&&const DeepCollectionEquality().equals(other.weapons, weapons)&&const DeepCollectionEquality().equals(other.toolEquipment, toolEquipment)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.customItems, customItems)&&(identical(other.name, name) || other.name == name)&&(identical(other.sexe, sexe) || other.sexe == sexe)&&(identical(other.age, age) || other.age == age)&&(identical(other.height, height) || other.height == height)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.eyes, eyes) || other.eyes == eyes)&&(identical(other.skin, skin) || other.skin == skin)&&(identical(other.hair, hair) || other.hair == hair)&&(identical(other.pack, pack) || other.pack == pack)&&(identical(other.appearanceText, appearanceText) || other.appearanceText == appearanceText)&&(identical(other.traitsText, traitsText) || other.traitsText == traitsText)&&(identical(other.idealsText, idealsText) || other.idealsText == idealsText)&&(identical(other.bondsText, bondsText) || other.bondsText == bondsText)&&(identical(other.flawsText, flawsText) || other.flawsText == flawsText)&&(identical(other.backstoryText, backstoryText) || other.backstoryText == backstoryText)&&(identical(other.alliesText, alliesText) || other.alliesText == alliesText)&&(identical(other.featuresText, featuresText) || other.featuresText == featuresText)&&(identical(other.treasureText, treasureText) || other.treasureText == treasureText));
}


@override
int get hashCode => Object.hashAll([runtimeType,race,raceCustomText,characterClass,subclass,level,background,backgroundCustomText,const DeepCollectionEquality().hash(abilityScores),const DeepCollectionEquality().hash(levels),styleCombat1,styleCombat2,favoredEnemy0,favoredEnemy6,favoredEnemy14,const DeepCollectionEquality().hash(skillProficiencies),const DeepCollectionEquality().hash(toolProficiencies),const DeepCollectionEquality().hash(languages),const DeepCollectionEquality().hash(innateSpells),const DeepCollectionEquality().hash(knownSpells),const DeepCollectionEquality().hash(knownInvocations),gp,pp,ep,sp,cp,armor,shield,const DeepCollectionEquality().hash(weapons),const DeepCollectionEquality().hash(toolEquipment),const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(customItems),name,sexe,age,height,weight,alignment,xp,eyes,skin,hair,pack,appearanceText,traitsText,idealsText,bondsText,flawsText,backstoryText,alliesText,featuresText,treasureText]);

@override
String toString() {
  return 'XmlCharacterImportResolved(race: $race, raceCustomText: $raceCustomText, characterClass: $characterClass, subclass: $subclass, level: $level, background: $background, backgroundCustomText: $backgroundCustomText, abilityScores: $abilityScores, levels: $levels, styleCombat1: $styleCombat1, styleCombat2: $styleCombat2, favoredEnemy0: $favoredEnemy0, favoredEnemy6: $favoredEnemy6, favoredEnemy14: $favoredEnemy14, skillProficiencies: $skillProficiencies, toolProficiencies: $toolProficiencies, languages: $languages, innateSpells: $innateSpells, knownSpells: $knownSpells, knownInvocations: $knownInvocations, gp: $gp, pp: $pp, ep: $ep, sp: $sp, cp: $cp, armor: $armor, shield: $shield, weapons: $weapons, toolEquipment: $toolEquipment, items: $items, customItems: $customItems, name: $name, sexe: $sexe, age: $age, height: $height, weight: $weight, alignment: $alignment, xp: $xp, eyes: $eyes, skin: $skin, hair: $hair, pack: $pack, appearanceText: $appearanceText, traitsText: $traitsText, idealsText: $idealsText, bondsText: $bondsText, flawsText: $flawsText, backstoryText: $backstoryText, alliesText: $alliesText, featuresText: $featuresText, treasureText: $treasureText)';
}


}

/// @nodoc
abstract mixin class $XmlCharacterImportResolvedCopyWith<$Res>  {
  factory $XmlCharacterImportResolvedCopyWith(XmlCharacterImportResolved value, $Res Function(XmlCharacterImportResolved) _then) = _$XmlCharacterImportResolvedCopyWithImpl;
@useResult
$Res call({
 XmlFieldResolution<RaceOption> race, String? raceCustomText, XmlFieldResolution<ClassOption> characterClass, XmlFieldResolution<XmlNamedOption>? subclass, int level, XmlFieldResolution<BackgroundOption> background, String? backgroundCustomText, Map<String, int> abilityScores, List<XmlRawLevelEntry> levels, XmlFieldResolution<String>? styleCombat1, XmlFieldResolution<String>? styleCombat2, XmlFieldResolution<String>? favoredEnemy0, XmlFieldResolution<String>? favoredEnemy6, XmlFieldResolution<String>? favoredEnemy14, Map<int, List<XmlFieldResolution<String>>> skillProficiencies, Map<int, List<XmlFieldResolution<ToolOption>>> toolProficiencies, Map<int, List<XmlFieldResolution<LanguageOption>>> languages, List<XmlSpellResolution> innateSpells, List<XmlSpellResolution> knownSpells, List<XmlFieldResolution<XmlNamedOption>> knownInvocations, int gp, int pp, int ep, int sp, int cp, XmlFieldResolution<String> armor, XmlFieldResolution<String> shield, List<XmlQuantifiedResolution> weapons, List<XmlQuantifiedResolution> toolEquipment, List<XmlQuantifiedResolution> items, List<XmlFieldResolution<String>> customItems, String name, XmlFieldResolution<String> sexe, int? age, String? height, String? weight, XmlFieldResolution<String> alignment, int? xp, String? eyes, String? skin, String? hair, XmlFieldResolution<String>? pack, String appearanceText, String traitsText, String idealsText, String bondsText, String flawsText, String backstoryText, String alliesText, String featuresText, String treasureText
});


$XmlFieldResolutionCopyWith<RaceOption, $Res> get race;$XmlFieldResolutionCopyWith<ClassOption, $Res> get characterClass;$XmlFieldResolutionCopyWith<XmlNamedOption, $Res>? get subclass;$XmlFieldResolutionCopyWith<BackgroundOption, $Res> get background;$XmlFieldResolutionCopyWith<String, $Res>? get styleCombat1;$XmlFieldResolutionCopyWith<String, $Res>? get styleCombat2;$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy0;$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy6;$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy14;$XmlFieldResolutionCopyWith<String, $Res> get armor;$XmlFieldResolutionCopyWith<String, $Res> get shield;$XmlFieldResolutionCopyWith<String, $Res> get sexe;$XmlFieldResolutionCopyWith<String, $Res> get alignment;$XmlFieldResolutionCopyWith<String, $Res>? get pack;

}
/// @nodoc
class _$XmlCharacterImportResolvedCopyWithImpl<$Res>
    implements $XmlCharacterImportResolvedCopyWith<$Res> {
  _$XmlCharacterImportResolvedCopyWithImpl(this._self, this._then);

  final XmlCharacterImportResolved _self;
  final $Res Function(XmlCharacterImportResolved) _then;

/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? race = null,Object? raceCustomText = freezed,Object? characterClass = null,Object? subclass = freezed,Object? level = null,Object? background = null,Object? backgroundCustomText = freezed,Object? abilityScores = null,Object? levels = null,Object? styleCombat1 = freezed,Object? styleCombat2 = freezed,Object? favoredEnemy0 = freezed,Object? favoredEnemy6 = freezed,Object? favoredEnemy14 = freezed,Object? skillProficiencies = null,Object? toolProficiencies = null,Object? languages = null,Object? innateSpells = null,Object? knownSpells = null,Object? knownInvocations = null,Object? gp = null,Object? pp = null,Object? ep = null,Object? sp = null,Object? cp = null,Object? armor = null,Object? shield = null,Object? weapons = null,Object? toolEquipment = null,Object? items = null,Object? customItems = null,Object? name = null,Object? sexe = null,Object? age = freezed,Object? height = freezed,Object? weight = freezed,Object? alignment = null,Object? xp = freezed,Object? eyes = freezed,Object? skin = freezed,Object? hair = freezed,Object? pack = freezed,Object? appearanceText = null,Object? traitsText = null,Object? idealsText = null,Object? bondsText = null,Object? flawsText = null,Object? backstoryText = null,Object? alliesText = null,Object? featuresText = null,Object? treasureText = null,}) {
  return _then(XmlCharacterImportResolved(
race: null == race ? _self.race : race // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<RaceOption>,raceCustomText: freezed == raceCustomText ? _self.raceCustomText : raceCustomText // ignore: cast_nullable_to_non_nullable
as String?,characterClass: null == characterClass ? _self.characterClass : characterClass // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<ClassOption>,subclass: freezed == subclass ? _self.subclass : subclass // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<XmlNamedOption>?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<BackgroundOption>,backgroundCustomText: freezed == backgroundCustomText ? _self.backgroundCustomText : backgroundCustomText // ignore: cast_nullable_to_non_nullable
as String?,abilityScores: null == abilityScores ? _self.abilityScores : abilityScores // ignore: cast_nullable_to_non_nullable
as Map<String, int>,levels: null == levels ? _self.levels : levels // ignore: cast_nullable_to_non_nullable
as List<XmlRawLevelEntry>,styleCombat1: freezed == styleCombat1 ? _self.styleCombat1 : styleCombat1 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,styleCombat2: freezed == styleCombat2 ? _self.styleCombat2 : styleCombat2 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,favoredEnemy0: freezed == favoredEnemy0 ? _self.favoredEnemy0 : favoredEnemy0 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,favoredEnemy6: freezed == favoredEnemy6 ? _self.favoredEnemy6 : favoredEnemy6 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,favoredEnemy14: freezed == favoredEnemy14 ? _self.favoredEnemy14 : favoredEnemy14 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,skillProficiencies: null == skillProficiencies ? _self.skillProficiencies : skillProficiencies // ignore: cast_nullable_to_non_nullable
as Map<int, List<XmlFieldResolution<String>>>,toolProficiencies: null == toolProficiencies ? _self.toolProficiencies : toolProficiencies // ignore: cast_nullable_to_non_nullable
as Map<int, List<XmlFieldResolution<ToolOption>>>,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as Map<int, List<XmlFieldResolution<LanguageOption>>>,innateSpells: null == innateSpells ? _self.innateSpells : innateSpells // ignore: cast_nullable_to_non_nullable
as List<XmlSpellResolution>,knownSpells: null == knownSpells ? _self.knownSpells : knownSpells // ignore: cast_nullable_to_non_nullable
as List<XmlSpellResolution>,knownInvocations: null == knownInvocations ? _self.knownInvocations : knownInvocations // ignore: cast_nullable_to_non_nullable
as List<XmlFieldResolution<XmlNamedOption>>,gp: null == gp ? _self.gp : gp // ignore: cast_nullable_to_non_nullable
as int,pp: null == pp ? _self.pp : pp // ignore: cast_nullable_to_non_nullable
as int,ep: null == ep ? _self.ep : ep // ignore: cast_nullable_to_non_nullable
as int,sp: null == sp ? _self.sp : sp // ignore: cast_nullable_to_non_nullable
as int,cp: null == cp ? _self.cp : cp // ignore: cast_nullable_to_non_nullable
as int,armor: null == armor ? _self.armor : armor // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>,shield: null == shield ? _self.shield : shield // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>,weapons: null == weapons ? _self.weapons : weapons // ignore: cast_nullable_to_non_nullable
as List<XmlQuantifiedResolution>,toolEquipment: null == toolEquipment ? _self.toolEquipment : toolEquipment // ignore: cast_nullable_to_non_nullable
as List<XmlQuantifiedResolution>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<XmlQuantifiedResolution>,customItems: null == customItems ? _self.customItems : customItems // ignore: cast_nullable_to_non_nullable
as List<XmlFieldResolution<String>>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sexe: null == sexe ? _self.sexe : sexe // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>,xp: freezed == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int?,eyes: freezed == eyes ? _self.eyes : eyes // ignore: cast_nullable_to_non_nullable
as String?,skin: freezed == skin ? _self.skin : skin // ignore: cast_nullable_to_non_nullable
as String?,hair: freezed == hair ? _self.hair : hair // ignore: cast_nullable_to_non_nullable
as String?,pack: freezed == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,appearanceText: null == appearanceText ? _self.appearanceText : appearanceText // ignore: cast_nullable_to_non_nullable
as String,traitsText: null == traitsText ? _self.traitsText : traitsText // ignore: cast_nullable_to_non_nullable
as String,idealsText: null == idealsText ? _self.idealsText : idealsText // ignore: cast_nullable_to_non_nullable
as String,bondsText: null == bondsText ? _self.bondsText : bondsText // ignore: cast_nullable_to_non_nullable
as String,flawsText: null == flawsText ? _self.flawsText : flawsText // ignore: cast_nullable_to_non_nullable
as String,backstoryText: null == backstoryText ? _self.backstoryText : backstoryText // ignore: cast_nullable_to_non_nullable
as String,alliesText: null == alliesText ? _self.alliesText : alliesText // ignore: cast_nullable_to_non_nullable
as String,featuresText: null == featuresText ? _self.featuresText : featuresText // ignore: cast_nullable_to_non_nullable
as String,treasureText: null == treasureText ? _self.treasureText : treasureText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<RaceOption, $Res> get race {
  
  return $XmlFieldResolutionCopyWith<RaceOption, $Res>(_self.race, (value) {
    return _then(_self.copyWith(race: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<ClassOption, $Res> get characterClass {
  
  return $XmlFieldResolutionCopyWith<ClassOption, $Res>(_self.characterClass, (value) {
    return _then(_self.copyWith(characterClass: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<XmlNamedOption, $Res>? get subclass {
    if (_self.subclass == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<XmlNamedOption, $Res>(_self.subclass!, (value) {
    return _then(_self.copyWith(subclass: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<BackgroundOption, $Res> get background {
  
  return $XmlFieldResolutionCopyWith<BackgroundOption, $Res>(_self.background, (value) {
    return _then(_self.copyWith(background: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get styleCombat1 {
    if (_self.styleCombat1 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.styleCombat1!, (value) {
    return _then(_self.copyWith(styleCombat1: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get styleCombat2 {
    if (_self.styleCombat2 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.styleCombat2!, (value) {
    return _then(_self.copyWith(styleCombat2: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy0 {
    if (_self.favoredEnemy0 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.favoredEnemy0!, (value) {
    return _then(_self.copyWith(favoredEnemy0: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy6 {
    if (_self.favoredEnemy6 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.favoredEnemy6!, (value) {
    return _then(_self.copyWith(favoredEnemy6: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy14 {
    if (_self.favoredEnemy14 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.favoredEnemy14!, (value) {
    return _then(_self.copyWith(favoredEnemy14: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res> get armor {
  
  return $XmlFieldResolutionCopyWith<String, $Res>(_self.armor, (value) {
    return _then(_self.copyWith(armor: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res> get shield {
  
  return $XmlFieldResolutionCopyWith<String, $Res>(_self.shield, (value) {
    return _then(_self.copyWith(shield: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res> get sexe {
  
  return $XmlFieldResolutionCopyWith<String, $Res>(_self.sexe, (value) {
    return _then(_self.copyWith(sexe: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res> get alignment {
  
  return $XmlFieldResolutionCopyWith<String, $Res>(_self.alignment, (value) {
    return _then(_self.copyWith(alignment: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get pack {
    if (_self.pack == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.pack!, (value) {
    return _then(_self.copyWith(pack: value));
  });
}
}


/// Adds pattern-matching-related methods to [XmlCharacterImportResolved].
extension XmlCharacterImportResolvedPatterns on XmlCharacterImportResolved {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XmlCharacterImportResolved value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XmlCharacterImportResolved() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XmlCharacterImportResolved value)  $default,){
final _that = this;
switch (_that) {
case _XmlCharacterImportResolved():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XmlCharacterImportResolved value)?  $default,){
final _that = this;
switch (_that) {
case _XmlCharacterImportResolved() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( XmlFieldResolution<RaceOption> race,  String? raceCustomText,  XmlFieldResolution<ClassOption> characterClass,  XmlFieldResolution<XmlNamedOption>? subclass,  int level,  XmlFieldResolution<BackgroundOption> background,  String? backgroundCustomText,  Map<String, int> abilityScores,  List<XmlRawLevelEntry> levels,  XmlFieldResolution<String>? styleCombat1,  XmlFieldResolution<String>? styleCombat2,  XmlFieldResolution<String>? favoredEnemy0,  XmlFieldResolution<String>? favoredEnemy6,  XmlFieldResolution<String>? favoredEnemy14,  Map<int, List<XmlFieldResolution<String>>> skillProficiencies,  Map<int, List<XmlFieldResolution<ToolOption>>> toolProficiencies,  Map<int, List<XmlFieldResolution<LanguageOption>>> languages,  List<XmlSpellResolution> innateSpells,  List<XmlSpellResolution> knownSpells,  List<XmlFieldResolution<XmlNamedOption>> knownInvocations,  int gp,  int pp,  int ep,  int sp,  int cp,  XmlFieldResolution<String> armor,  XmlFieldResolution<String> shield,  List<XmlQuantifiedResolution> weapons,  List<XmlQuantifiedResolution> toolEquipment,  List<XmlQuantifiedResolution> items,  List<XmlFieldResolution<String>> customItems,  String name,  XmlFieldResolution<String> sexe,  int? age,  String? height,  String? weight,  XmlFieldResolution<String> alignment,  int? xp,  String? eyes,  String? skin,  String? hair,  XmlFieldResolution<String>? pack,  String appearanceText,  String traitsText,  String idealsText,  String bondsText,  String flawsText,  String backstoryText,  String alliesText,  String featuresText,  String treasureText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XmlCharacterImportResolved() when $default != null:
return $default(_that.race,_that.raceCustomText,_that.characterClass,_that.subclass,_that.level,_that.background,_that.backgroundCustomText,_that.abilityScores,_that.levels,_that.styleCombat1,_that.styleCombat2,_that.favoredEnemy0,_that.favoredEnemy6,_that.favoredEnemy14,_that.skillProficiencies,_that.toolProficiencies,_that.languages,_that.innateSpells,_that.knownSpells,_that.knownInvocations,_that.gp,_that.pp,_that.ep,_that.sp,_that.cp,_that.armor,_that.shield,_that.weapons,_that.toolEquipment,_that.items,_that.customItems,_that.name,_that.sexe,_that.age,_that.height,_that.weight,_that.alignment,_that.xp,_that.eyes,_that.skin,_that.hair,_that.pack,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( XmlFieldResolution<RaceOption> race,  String? raceCustomText,  XmlFieldResolution<ClassOption> characterClass,  XmlFieldResolution<XmlNamedOption>? subclass,  int level,  XmlFieldResolution<BackgroundOption> background,  String? backgroundCustomText,  Map<String, int> abilityScores,  List<XmlRawLevelEntry> levels,  XmlFieldResolution<String>? styleCombat1,  XmlFieldResolution<String>? styleCombat2,  XmlFieldResolution<String>? favoredEnemy0,  XmlFieldResolution<String>? favoredEnemy6,  XmlFieldResolution<String>? favoredEnemy14,  Map<int, List<XmlFieldResolution<String>>> skillProficiencies,  Map<int, List<XmlFieldResolution<ToolOption>>> toolProficiencies,  Map<int, List<XmlFieldResolution<LanguageOption>>> languages,  List<XmlSpellResolution> innateSpells,  List<XmlSpellResolution> knownSpells,  List<XmlFieldResolution<XmlNamedOption>> knownInvocations,  int gp,  int pp,  int ep,  int sp,  int cp,  XmlFieldResolution<String> armor,  XmlFieldResolution<String> shield,  List<XmlQuantifiedResolution> weapons,  List<XmlQuantifiedResolution> toolEquipment,  List<XmlQuantifiedResolution> items,  List<XmlFieldResolution<String>> customItems,  String name,  XmlFieldResolution<String> sexe,  int? age,  String? height,  String? weight,  XmlFieldResolution<String> alignment,  int? xp,  String? eyes,  String? skin,  String? hair,  XmlFieldResolution<String>? pack,  String appearanceText,  String traitsText,  String idealsText,  String bondsText,  String flawsText,  String backstoryText,  String alliesText,  String featuresText,  String treasureText)  $default,) {final _that = this;
switch (_that) {
case _XmlCharacterImportResolved():
return $default(_that.race,_that.raceCustomText,_that.characterClass,_that.subclass,_that.level,_that.background,_that.backgroundCustomText,_that.abilityScores,_that.levels,_that.styleCombat1,_that.styleCombat2,_that.favoredEnemy0,_that.favoredEnemy6,_that.favoredEnemy14,_that.skillProficiencies,_that.toolProficiencies,_that.languages,_that.innateSpells,_that.knownSpells,_that.knownInvocations,_that.gp,_that.pp,_that.ep,_that.sp,_that.cp,_that.armor,_that.shield,_that.weapons,_that.toolEquipment,_that.items,_that.customItems,_that.name,_that.sexe,_that.age,_that.height,_that.weight,_that.alignment,_that.xp,_that.eyes,_that.skin,_that.hair,_that.pack,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( XmlFieldResolution<RaceOption> race,  String? raceCustomText,  XmlFieldResolution<ClassOption> characterClass,  XmlFieldResolution<XmlNamedOption>? subclass,  int level,  XmlFieldResolution<BackgroundOption> background,  String? backgroundCustomText,  Map<String, int> abilityScores,  List<XmlRawLevelEntry> levels,  XmlFieldResolution<String>? styleCombat1,  XmlFieldResolution<String>? styleCombat2,  XmlFieldResolution<String>? favoredEnemy0,  XmlFieldResolution<String>? favoredEnemy6,  XmlFieldResolution<String>? favoredEnemy14,  Map<int, List<XmlFieldResolution<String>>> skillProficiencies,  Map<int, List<XmlFieldResolution<ToolOption>>> toolProficiencies,  Map<int, List<XmlFieldResolution<LanguageOption>>> languages,  List<XmlSpellResolution> innateSpells,  List<XmlSpellResolution> knownSpells,  List<XmlFieldResolution<XmlNamedOption>> knownInvocations,  int gp,  int pp,  int ep,  int sp,  int cp,  XmlFieldResolution<String> armor,  XmlFieldResolution<String> shield,  List<XmlQuantifiedResolution> weapons,  List<XmlQuantifiedResolution> toolEquipment,  List<XmlQuantifiedResolution> items,  List<XmlFieldResolution<String>> customItems,  String name,  XmlFieldResolution<String> sexe,  int? age,  String? height,  String? weight,  XmlFieldResolution<String> alignment,  int? xp,  String? eyes,  String? skin,  String? hair,  XmlFieldResolution<String>? pack,  String appearanceText,  String traitsText,  String idealsText,  String bondsText,  String flawsText,  String backstoryText,  String alliesText,  String featuresText,  String treasureText)?  $default,) {final _that = this;
switch (_that) {
case _XmlCharacterImportResolved() when $default != null:
return $default(_that.race,_that.raceCustomText,_that.characterClass,_that.subclass,_that.level,_that.background,_that.backgroundCustomText,_that.abilityScores,_that.levels,_that.styleCombat1,_that.styleCombat2,_that.favoredEnemy0,_that.favoredEnemy6,_that.favoredEnemy14,_that.skillProficiencies,_that.toolProficiencies,_that.languages,_that.innateSpells,_that.knownSpells,_that.knownInvocations,_that.gp,_that.pp,_that.ep,_that.sp,_that.cp,_that.armor,_that.shield,_that.weapons,_that.toolEquipment,_that.items,_that.customItems,_that.name,_that.sexe,_that.age,_that.height,_that.weight,_that.alignment,_that.xp,_that.eyes,_that.skin,_that.hair,_that.pack,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
  return null;

}
}

}

/// @nodoc


class _XmlCharacterImportResolved implements XmlCharacterImportResolved {
  const _XmlCharacterImportResolved({required this.race, this.raceCustomText, required this.characterClass, this.subclass, required this.level, required this.background, this.backgroundCustomText, required  Map<String, int> abilityScores, required  List<XmlRawLevelEntry> levels, this.styleCombat1, this.styleCombat2, this.favoredEnemy0, this.favoredEnemy6, this.favoredEnemy14, required  Map<int, List<XmlFieldResolution<String>>> skillProficiencies, required  Map<int, List<XmlFieldResolution<ToolOption>>> toolProficiencies, required  Map<int, List<XmlFieldResolution<LanguageOption>>> languages, required  List<XmlSpellResolution> innateSpells, required  List<XmlSpellResolution> knownSpells, required  List<XmlFieldResolution<XmlNamedOption>> knownInvocations, required this.gp, required this.pp, required this.ep, required this.sp, required this.cp, required this.armor, required this.shield, required  List<XmlQuantifiedResolution> weapons, required  List<XmlQuantifiedResolution> toolEquipment, required  List<XmlQuantifiedResolution> items, required  List<XmlFieldResolution<String>> customItems, required this.name, required this.sexe, this.age, this.height, this.weight, required this.alignment, this.xp, this.eyes, this.skin, this.hair, this.pack, required this.appearanceText, required this.traitsText, required this.idealsText, required this.bondsText, required this.flawsText, required this.backstoryText, required this.alliesText, required this.featuresText, required this.treasureText}): _abilityScores = abilityScores,_levels = levels,_skillProficiencies = skillProficiencies,_toolProficiencies = toolProficiencies,_languages = languages,_innateSpells = innateSpells,_knownSpells = knownSpells,_knownInvocations = knownInvocations,_weapons = weapons,_toolEquipment = toolEquipment,_items = items,_customItems = customItems;
  

@override final  XmlFieldResolution<RaceOption> race;
/// `<raceCustom>` — jamais résolu par nom (voir `XmlCharacterImportRaw
/// .raceCustom`), passé tel quel pour affichage informatif éventuel.
@override final  String? raceCustomText;
@override final  XmlFieldResolution<ClassOption> characterClass;
/// `null` si `<classPath>` est absent/vide du XML (personnage n'ayant
/// pas encore choisi de sous-classe) — pas un [XmlFieldResolution
/// .unrecognized], qui signifierait "un nom était présent mais non
/// reconnu".
@override final  XmlFieldResolution<XmlNamedOption>? subclass;
@override final  int level;
@override final  XmlFieldResolution<BackgroundOption> background;
@override final  String? backgroundCustomText;
 final  Map<String, int> _abilityScores;
@override Map<String, int> get abilityScores {
  if (_abilityScores is EqualUnmodifiableMapView) return _abilityScores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_abilityScores);
}

 final  List<XmlRawLevelEntry> _levels;
@override List<XmlRawLevelEntry> get levels {
  if (_levels is EqualUnmodifiableListView) return _levels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_levels);
}

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
@override final  XmlFieldResolution<String>? styleCombat1;
@override final  XmlFieldResolution<String>? styleCombat2;
/// `<favoredEnemy0>`/`<favoredEnemy6>`/`<favoredEnemy14>` (Rôdeur) —
/// mêmes règles que [styleCombat1]/[styleCombat2].
@override final  XmlFieldResolution<String>? favoredEnemy0;
@override final  XmlFieldResolution<String>? favoredEnemy6;
@override final  XmlFieldResolution<String>? favoredEnemy14;
/// `skillsProf`, clé = id de source (0 = race, 1 = classe, 2 =
/// historique, 3 = autres, voir `AideddReferenceTables
/// .proficiencySources`) — chaque compétence résolue via
/// `AideddReferenceTables.skills` (libellé aidedd, pas un `skill_id`
/// réel de l'app, voir la documentation de classe de
/// `AideddReferenceTables`).
 final  Map<int, List<XmlFieldResolution<String>>> _skillProficiencies;
/// `skillsProf`, clé = id de source (0 = race, 1 = classe, 2 =
/// historique, 3 = autres, voir `AideddReferenceTables
/// .proficiencySources`) — chaque compétence résolue via
/// `AideddReferenceTables.skills` (libellé aidedd, pas un `skill_id`
/// réel de l'app, voir la documentation de classe de
/// `AideddReferenceTables`).
@override Map<int, List<XmlFieldResolution<String>>> get skillProficiencies {
  if (_skillProficiencies is EqualUnmodifiableMapView) return _skillProficiencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_skillProficiencies);
}

/// `toolsProf` (déjà en texte clair dans le XML) — résolu par nom contre
/// le `ToolCatalog` réel de l'app, à la différence de
/// [skillProficiencies].
 final  Map<int, List<XmlFieldResolution<ToolOption>>> _toolProficiencies;
/// `toolsProf` (déjà en texte clair dans le XML) — résolu par nom contre
/// le `ToolCatalog` réel de l'app, à la différence de
/// [skillProficiencies].
@override Map<int, List<XmlFieldResolution<ToolOption>>> get toolProficiencies {
  if (_toolProficiencies is EqualUnmodifiableMapView) return _toolProficiencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_toolProficiencies);
}

/// `languages` (déjà en texte clair) — résolu par nom contre le
/// `LanguageCatalog` réel de l'app.
 final  Map<int, List<XmlFieldResolution<LanguageOption>>> _languages;
/// `languages` (déjà en texte clair) — résolu par nom contre le
/// `LanguageCatalog` réel de l'app.
@override Map<int, List<XmlFieldResolution<LanguageOption>>> get languages {
  if (_languages is EqualUnmodifiableMapView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_languages);
}

 final  List<XmlSpellResolution> _innateSpells;
@override List<XmlSpellResolution> get innateSpells {
  if (_innateSpells is EqualUnmodifiableListView) return _innateSpells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_innateSpells);
}

 final  List<XmlSpellResolution> _knownSpells;
@override List<XmlSpellResolution> get knownSpells {
  if (_knownSpells is EqualUnmodifiableListView) return _knownSpells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownSpells);
}

 final  List<XmlFieldResolution<XmlNamedOption>> _knownInvocations;
@override List<XmlFieldResolution<XmlNamedOption>> get knownInvocations {
  if (_knownInvocations is EqualUnmodifiableListView) return _knownInvocations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownInvocations);
}

@override final  int gp;
@override final  int pp;
@override final  int ep;
@override final  int sp;
@override final  int cp;
@override final  XmlFieldResolution<String> armor;
@override final  XmlFieldResolution<String> shield;
/// `weapon`+`weaponQ` combinées — les emplacements vides (id `0`) ont
/// été filtrés (voir la documentation de [XmlQuantifiedResolution]).
 final  List<XmlQuantifiedResolution> _weapons;
/// `weapon`+`weaponQ` combinées — les emplacements vides (id `0`) ont
/// été filtrés (voir la documentation de [XmlQuantifiedResolution]).
@override List<XmlQuantifiedResolution> get weapons {
  if (_weapons is EqualUnmodifiableListView) return _weapons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weapons);
}

/// `tools` (objets physiques possédés) — mêmes règles que [weapons],
/// quantité toujours 1 (pas de liste de quantité dans le XML pour ce
/// champ).
 final  List<XmlQuantifiedResolution> _toolEquipment;
/// `tools` (objets physiques possédés) — mêmes règles que [weapons],
/// quantité toujours 1 (pas de liste de quantité dans le XML pour ce
/// champ).
@override List<XmlQuantifiedResolution> get toolEquipment {
  if (_toolEquipment is EqualUnmodifiableListView) return _toolEquipment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolEquipment);
}

/// `item`+`itemQ` combinées — mêmes règles que [weapons].
 final  List<XmlQuantifiedResolution> _items;
/// `item`+`itemQ` combinées — mêmes règles que [weapons].
@override List<XmlQuantifiedResolution> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// `itemX` — toujours [XmlFieldResolution.custom], jamais [recognized]
/// ni [unrecognized] (voir la documentation de classe de
/// [XmlFieldResolution]).
 final  List<XmlFieldResolution<String>> _customItems;
/// `itemX` — toujours [XmlFieldResolution.custom], jamais [recognized]
/// ni [unrecognized] (voir la documentation de classe de
/// [XmlFieldResolution]).
@override List<XmlFieldResolution<String>> get customItems {
  if (_customItems is EqualUnmodifiableListView) return _customItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customItems);
}

@override final  String name;
@override final  XmlFieldResolution<String> sexe;
@override final  int? age;
@override final  String? height;
@override final  String? weight;
@override final  XmlFieldResolution<String> alignment;
@override final  int? xp;
@override final  String? eyes;
@override final  String? skin;
@override final  String? hair;
/// `<pack>` — `null` si absent du XML, voir la documentation de
/// `AideddReferenceTables.packs` (traçabilité/validation croisée
/// uniquement, pas exploité pour reconstruire l'inventaire).
@override final  XmlFieldResolution<String>? pack;
@override final  String appearanceText;
@override final  String traitsText;
@override final  String idealsText;
@override final  String bondsText;
@override final  String flawsText;
@override final  String backstoryText;
@override final  String alliesText;
@override final  String featuresText;
@override final  String treasureText;

/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XmlCharacterImportResolvedCopyWith<_XmlCharacterImportResolved> get copyWith => __$XmlCharacterImportResolvedCopyWithImpl<_XmlCharacterImportResolved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _XmlCharacterImportResolved&&(identical(other.race, race) || other.race == race)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.characterClass, characterClass) || other.characterClass == characterClass)&&(identical(other.subclass, subclass) || other.subclass == subclass)&&(identical(other.level, level) || other.level == level)&&(identical(other.background, background) || other.background == background)&&(identical(other.backgroundCustomText, backgroundCustomText) || other.backgroundCustomText == backgroundCustomText)&&const DeepCollectionEquality().equals(other._abilityScores, _abilityScores)&&const DeepCollectionEquality().equals(other._levels, _levels)&&(identical(other.styleCombat1, styleCombat1) || other.styleCombat1 == styleCombat1)&&(identical(other.styleCombat2, styleCombat2) || other.styleCombat2 == styleCombat2)&&(identical(other.favoredEnemy0, favoredEnemy0) || other.favoredEnemy0 == favoredEnemy0)&&(identical(other.favoredEnemy6, favoredEnemy6) || other.favoredEnemy6 == favoredEnemy6)&&(identical(other.favoredEnemy14, favoredEnemy14) || other.favoredEnemy14 == favoredEnemy14)&&const DeepCollectionEquality().equals(other._skillProficiencies, _skillProficiencies)&&const DeepCollectionEquality().equals(other._toolProficiencies, _toolProficiencies)&&const DeepCollectionEquality().equals(other._languages, _languages)&&const DeepCollectionEquality().equals(other._innateSpells, _innateSpells)&&const DeepCollectionEquality().equals(other._knownSpells, _knownSpells)&&const DeepCollectionEquality().equals(other._knownInvocations, _knownInvocations)&&(identical(other.gp, gp) || other.gp == gp)&&(identical(other.pp, pp) || other.pp == pp)&&(identical(other.ep, ep) || other.ep == ep)&&(identical(other.sp, sp) || other.sp == sp)&&(identical(other.cp, cp) || other.cp == cp)&&(identical(other.armor, armor) || other.armor == armor)&&(identical(other.shield, shield) || other.shield == shield)&&const DeepCollectionEquality().equals(other._weapons, _weapons)&&const DeepCollectionEquality().equals(other._toolEquipment, _toolEquipment)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._customItems, _customItems)&&(identical(other.name, name) || other.name == name)&&(identical(other.sexe, sexe) || other.sexe == sexe)&&(identical(other.age, age) || other.age == age)&&(identical(other.height, height) || other.height == height)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.eyes, eyes) || other.eyes == eyes)&&(identical(other.skin, skin) || other.skin == skin)&&(identical(other.hair, hair) || other.hair == hair)&&(identical(other.pack, pack) || other.pack == pack)&&(identical(other.appearanceText, appearanceText) || other.appearanceText == appearanceText)&&(identical(other.traitsText, traitsText) || other.traitsText == traitsText)&&(identical(other.idealsText, idealsText) || other.idealsText == idealsText)&&(identical(other.bondsText, bondsText) || other.bondsText == bondsText)&&(identical(other.flawsText, flawsText) || other.flawsText == flawsText)&&(identical(other.backstoryText, backstoryText) || other.backstoryText == backstoryText)&&(identical(other.alliesText, alliesText) || other.alliesText == alliesText)&&(identical(other.featuresText, featuresText) || other.featuresText == featuresText)&&(identical(other.treasureText, treasureText) || other.treasureText == treasureText));
}


@override
int get hashCode => Object.hashAll([runtimeType,race,raceCustomText,characterClass,subclass,level,background,backgroundCustomText,const DeepCollectionEquality().hash(_abilityScores),const DeepCollectionEquality().hash(_levels),styleCombat1,styleCombat2,favoredEnemy0,favoredEnemy6,favoredEnemy14,const DeepCollectionEquality().hash(_skillProficiencies),const DeepCollectionEquality().hash(_toolProficiencies),const DeepCollectionEquality().hash(_languages),const DeepCollectionEquality().hash(_innateSpells),const DeepCollectionEquality().hash(_knownSpells),const DeepCollectionEquality().hash(_knownInvocations),gp,pp,ep,sp,cp,armor,shield,const DeepCollectionEquality().hash(_weapons),const DeepCollectionEquality().hash(_toolEquipment),const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_customItems),name,sexe,age,height,weight,alignment,xp,eyes,skin,hair,pack,appearanceText,traitsText,idealsText,bondsText,flawsText,backstoryText,alliesText,featuresText,treasureText]);

@override
String toString() {
  return 'XmlCharacterImportResolved(race: $race, raceCustomText: $raceCustomText, characterClass: $characterClass, subclass: $subclass, level: $level, background: $background, backgroundCustomText: $backgroundCustomText, abilityScores: $abilityScores, levels: $levels, styleCombat1: $styleCombat1, styleCombat2: $styleCombat2, favoredEnemy0: $favoredEnemy0, favoredEnemy6: $favoredEnemy6, favoredEnemy14: $favoredEnemy14, skillProficiencies: $skillProficiencies, toolProficiencies: $toolProficiencies, languages: $languages, innateSpells: $innateSpells, knownSpells: $knownSpells, knownInvocations: $knownInvocations, gp: $gp, pp: $pp, ep: $ep, sp: $sp, cp: $cp, armor: $armor, shield: $shield, weapons: $weapons, toolEquipment: $toolEquipment, items: $items, customItems: $customItems, name: $name, sexe: $sexe, age: $age, height: $height, weight: $weight, alignment: $alignment, xp: $xp, eyes: $eyes, skin: $skin, hair: $hair, pack: $pack, appearanceText: $appearanceText, traitsText: $traitsText, idealsText: $idealsText, bondsText: $bondsText, flawsText: $flawsText, backstoryText: $backstoryText, alliesText: $alliesText, featuresText: $featuresText, treasureText: $treasureText)';
}


}

/// @nodoc
abstract mixin class _$XmlCharacterImportResolvedCopyWith<$Res> implements $XmlCharacterImportResolvedCopyWith<$Res> {
  factory _$XmlCharacterImportResolvedCopyWith(_XmlCharacterImportResolved value, $Res Function(_XmlCharacterImportResolved) _then) = __$XmlCharacterImportResolvedCopyWithImpl;
@override @useResult
$Res call({
 XmlFieldResolution<RaceOption> race, String? raceCustomText, XmlFieldResolution<ClassOption> characterClass, XmlFieldResolution<XmlNamedOption>? subclass, int level, XmlFieldResolution<BackgroundOption> background, String? backgroundCustomText, Map<String, int> abilityScores, List<XmlRawLevelEntry> levels, XmlFieldResolution<String>? styleCombat1, XmlFieldResolution<String>? styleCombat2, XmlFieldResolution<String>? favoredEnemy0, XmlFieldResolution<String>? favoredEnemy6, XmlFieldResolution<String>? favoredEnemy14, Map<int, List<XmlFieldResolution<String>>> skillProficiencies, Map<int, List<XmlFieldResolution<ToolOption>>> toolProficiencies, Map<int, List<XmlFieldResolution<LanguageOption>>> languages, List<XmlSpellResolution> innateSpells, List<XmlSpellResolution> knownSpells, List<XmlFieldResolution<XmlNamedOption>> knownInvocations, int gp, int pp, int ep, int sp, int cp, XmlFieldResolution<String> armor, XmlFieldResolution<String> shield, List<XmlQuantifiedResolution> weapons, List<XmlQuantifiedResolution> toolEquipment, List<XmlQuantifiedResolution> items, List<XmlFieldResolution<String>> customItems, String name, XmlFieldResolution<String> sexe, int? age, String? height, String? weight, XmlFieldResolution<String> alignment, int? xp, String? eyes, String? skin, String? hair, XmlFieldResolution<String>? pack, String appearanceText, String traitsText, String idealsText, String bondsText, String flawsText, String backstoryText, String alliesText, String featuresText, String treasureText
});


@override $XmlFieldResolutionCopyWith<RaceOption, $Res> get race;@override $XmlFieldResolutionCopyWith<ClassOption, $Res> get characterClass;@override $XmlFieldResolutionCopyWith<XmlNamedOption, $Res>? get subclass;@override $XmlFieldResolutionCopyWith<BackgroundOption, $Res> get background;@override $XmlFieldResolutionCopyWith<String, $Res>? get styleCombat1;@override $XmlFieldResolutionCopyWith<String, $Res>? get styleCombat2;@override $XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy0;@override $XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy6;@override $XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy14;@override $XmlFieldResolutionCopyWith<String, $Res> get armor;@override $XmlFieldResolutionCopyWith<String, $Res> get shield;@override $XmlFieldResolutionCopyWith<String, $Res> get sexe;@override $XmlFieldResolutionCopyWith<String, $Res> get alignment;@override $XmlFieldResolutionCopyWith<String, $Res>? get pack;

}
/// @nodoc
class __$XmlCharacterImportResolvedCopyWithImpl<$Res>
    implements _$XmlCharacterImportResolvedCopyWith<$Res> {
  __$XmlCharacterImportResolvedCopyWithImpl(this._self, this._then);

  final _XmlCharacterImportResolved _self;
  final $Res Function(_XmlCharacterImportResolved) _then;

/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? race = null,Object? raceCustomText = freezed,Object? characterClass = null,Object? subclass = freezed,Object? level = null,Object? background = null,Object? backgroundCustomText = freezed,Object? abilityScores = null,Object? levels = null,Object? styleCombat1 = freezed,Object? styleCombat2 = freezed,Object? favoredEnemy0 = freezed,Object? favoredEnemy6 = freezed,Object? favoredEnemy14 = freezed,Object? skillProficiencies = null,Object? toolProficiencies = null,Object? languages = null,Object? innateSpells = null,Object? knownSpells = null,Object? knownInvocations = null,Object? gp = null,Object? pp = null,Object? ep = null,Object? sp = null,Object? cp = null,Object? armor = null,Object? shield = null,Object? weapons = null,Object? toolEquipment = null,Object? items = null,Object? customItems = null,Object? name = null,Object? sexe = null,Object? age = freezed,Object? height = freezed,Object? weight = freezed,Object? alignment = null,Object? xp = freezed,Object? eyes = freezed,Object? skin = freezed,Object? hair = freezed,Object? pack = freezed,Object? appearanceText = null,Object? traitsText = null,Object? idealsText = null,Object? bondsText = null,Object? flawsText = null,Object? backstoryText = null,Object? alliesText = null,Object? featuresText = null,Object? treasureText = null,}) {
  return _then(_XmlCharacterImportResolved(
race: null == race ? _self.race : race // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<RaceOption>,raceCustomText: freezed == raceCustomText ? _self.raceCustomText : raceCustomText // ignore: cast_nullable_to_non_nullable
as String?,characterClass: null == characterClass ? _self.characterClass : characterClass // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<ClassOption>,subclass: freezed == subclass ? _self.subclass : subclass // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<XmlNamedOption>?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<BackgroundOption>,backgroundCustomText: freezed == backgroundCustomText ? _self.backgroundCustomText : backgroundCustomText // ignore: cast_nullable_to_non_nullable
as String?,abilityScores: null == abilityScores ? _self._abilityScores : abilityScores // ignore: cast_nullable_to_non_nullable
as Map<String, int>,levels: null == levels ? _self._levels : levels // ignore: cast_nullable_to_non_nullable
as List<XmlRawLevelEntry>,styleCombat1: freezed == styleCombat1 ? _self.styleCombat1 : styleCombat1 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,styleCombat2: freezed == styleCombat2 ? _self.styleCombat2 : styleCombat2 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,favoredEnemy0: freezed == favoredEnemy0 ? _self.favoredEnemy0 : favoredEnemy0 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,favoredEnemy6: freezed == favoredEnemy6 ? _self.favoredEnemy6 : favoredEnemy6 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,favoredEnemy14: freezed == favoredEnemy14 ? _self.favoredEnemy14 : favoredEnemy14 // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,skillProficiencies: null == skillProficiencies ? _self._skillProficiencies : skillProficiencies // ignore: cast_nullable_to_non_nullable
as Map<int, List<XmlFieldResolution<String>>>,toolProficiencies: null == toolProficiencies ? _self._toolProficiencies : toolProficiencies // ignore: cast_nullable_to_non_nullable
as Map<int, List<XmlFieldResolution<ToolOption>>>,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as Map<int, List<XmlFieldResolution<LanguageOption>>>,innateSpells: null == innateSpells ? _self._innateSpells : innateSpells // ignore: cast_nullable_to_non_nullable
as List<XmlSpellResolution>,knownSpells: null == knownSpells ? _self._knownSpells : knownSpells // ignore: cast_nullable_to_non_nullable
as List<XmlSpellResolution>,knownInvocations: null == knownInvocations ? _self._knownInvocations : knownInvocations // ignore: cast_nullable_to_non_nullable
as List<XmlFieldResolution<XmlNamedOption>>,gp: null == gp ? _self.gp : gp // ignore: cast_nullable_to_non_nullable
as int,pp: null == pp ? _self.pp : pp // ignore: cast_nullable_to_non_nullable
as int,ep: null == ep ? _self.ep : ep // ignore: cast_nullable_to_non_nullable
as int,sp: null == sp ? _self.sp : sp // ignore: cast_nullable_to_non_nullable
as int,cp: null == cp ? _self.cp : cp // ignore: cast_nullable_to_non_nullable
as int,armor: null == armor ? _self.armor : armor // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>,shield: null == shield ? _self.shield : shield // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>,weapons: null == weapons ? _self._weapons : weapons // ignore: cast_nullable_to_non_nullable
as List<XmlQuantifiedResolution>,toolEquipment: null == toolEquipment ? _self._toolEquipment : toolEquipment // ignore: cast_nullable_to_non_nullable
as List<XmlQuantifiedResolution>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<XmlQuantifiedResolution>,customItems: null == customItems ? _self._customItems : customItems // ignore: cast_nullable_to_non_nullable
as List<XmlFieldResolution<String>>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sexe: null == sexe ? _self.sexe : sexe // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>,xp: freezed == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int?,eyes: freezed == eyes ? _self.eyes : eyes // ignore: cast_nullable_to_non_nullable
as String?,skin: freezed == skin ? _self.skin : skin // ignore: cast_nullable_to_non_nullable
as String?,hair: freezed == hair ? _self.hair : hair // ignore: cast_nullable_to_non_nullable
as String?,pack: freezed == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as XmlFieldResolution<String>?,appearanceText: null == appearanceText ? _self.appearanceText : appearanceText // ignore: cast_nullable_to_non_nullable
as String,traitsText: null == traitsText ? _self.traitsText : traitsText // ignore: cast_nullable_to_non_nullable
as String,idealsText: null == idealsText ? _self.idealsText : idealsText // ignore: cast_nullable_to_non_nullable
as String,bondsText: null == bondsText ? _self.bondsText : bondsText // ignore: cast_nullable_to_non_nullable
as String,flawsText: null == flawsText ? _self.flawsText : flawsText // ignore: cast_nullable_to_non_nullable
as String,backstoryText: null == backstoryText ? _self.backstoryText : backstoryText // ignore: cast_nullable_to_non_nullable
as String,alliesText: null == alliesText ? _self.alliesText : alliesText // ignore: cast_nullable_to_non_nullable
as String,featuresText: null == featuresText ? _self.featuresText : featuresText // ignore: cast_nullable_to_non_nullable
as String,treasureText: null == treasureText ? _self.treasureText : treasureText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<RaceOption, $Res> get race {
  
  return $XmlFieldResolutionCopyWith<RaceOption, $Res>(_self.race, (value) {
    return _then(_self.copyWith(race: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<ClassOption, $Res> get characterClass {
  
  return $XmlFieldResolutionCopyWith<ClassOption, $Res>(_self.characterClass, (value) {
    return _then(_self.copyWith(characterClass: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<XmlNamedOption, $Res>? get subclass {
    if (_self.subclass == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<XmlNamedOption, $Res>(_self.subclass!, (value) {
    return _then(_self.copyWith(subclass: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<BackgroundOption, $Res> get background {
  
  return $XmlFieldResolutionCopyWith<BackgroundOption, $Res>(_self.background, (value) {
    return _then(_self.copyWith(background: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get styleCombat1 {
    if (_self.styleCombat1 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.styleCombat1!, (value) {
    return _then(_self.copyWith(styleCombat1: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get styleCombat2 {
    if (_self.styleCombat2 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.styleCombat2!, (value) {
    return _then(_self.copyWith(styleCombat2: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy0 {
    if (_self.favoredEnemy0 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.favoredEnemy0!, (value) {
    return _then(_self.copyWith(favoredEnemy0: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy6 {
    if (_self.favoredEnemy6 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.favoredEnemy6!, (value) {
    return _then(_self.copyWith(favoredEnemy6: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get favoredEnemy14 {
    if (_self.favoredEnemy14 == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.favoredEnemy14!, (value) {
    return _then(_self.copyWith(favoredEnemy14: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res> get armor {
  
  return $XmlFieldResolutionCopyWith<String, $Res>(_self.armor, (value) {
    return _then(_self.copyWith(armor: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res> get shield {
  
  return $XmlFieldResolutionCopyWith<String, $Res>(_self.shield, (value) {
    return _then(_self.copyWith(shield: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res> get sexe {
  
  return $XmlFieldResolutionCopyWith<String, $Res>(_self.sexe, (value) {
    return _then(_self.copyWith(sexe: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res> get alignment {
  
  return $XmlFieldResolutionCopyWith<String, $Res>(_self.alignment, (value) {
    return _then(_self.copyWith(alignment: value));
  });
}/// Create a copy of XmlCharacterImportResolved
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlFieldResolutionCopyWith<String, $Res>? get pack {
    if (_self.pack == null) {
    return null;
  }

  return $XmlFieldResolutionCopyWith<String, $Res>(_self.pack!, (value) {
    return _then(_self.copyWith(pack: value));
  });
}
}

// dart format on
