// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'xml_character_import_raw.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$XmlCharacterImportRaw {

 String get race;/// `<raceCustom>` — flag brut non interprété, voir
/// `xml-import-reference-mapping.md` section "Point encore ouvert :
/// raceCustom" (son sens exact reste incertain, traité comme informatif
/// par [XmlCharacterImportResolver], jamais bloquant).
 String? get raceCustom;/// `<class>` — champ nommé `characterClass` plutôt que `class`, mot
/// réservé Dart.
 String get characterClass;/// `<classPath>` — `null` si absent du XML (personnage n'ayant pas
/// encore choisi de sous-classe), jamais une chaîne vide.
 String? get classPath; int get level; String get background;/// `<backSpe>` — note libre d'historique personnalisé, jamais résolue
/// par nom (ce n'est pas un nom d'historique, juste un complément
/// textuel).
 String? get backSpe;/// `<str>`,`<dex>`,`<con>`,`<int>`,`<wis>`,`<cha>`, clés `'str'`/`'dex'`/
/// `'con'`/`'int'`/`'wis'`/`'cha'` — même convention de clés que
/// `CharacterCreationDraft.abilityScores`.
 Map<String, int> get abilityScores;/// `<lvl lvl="X">` — une entrée par niveau présent dans le XML (20 dans
/// les deux fixtures réelles, 1 à 20).
 List<XmlRawLevelEntry> get levels; String? get styleCombat1; String? get styleCombat2; String? get favoredEnemy0; String? get favoredEnemy6; String? get favoredEnemy14;/// `<pack>` — `null` si absent du XML.
 int? get pack;/// `<skillsProf id="0..3">` — clé = id de source (0 = race, 1 = classe,
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
 Map<int, List<String>> get skillsProf;/// `<toolsProf id="0..3">` — déjà en texte clair (noms d'outils), à la
/// différence de `skillsProf`, voir la documentation de classe.
 Map<int, List<String>> get toolsProf;/// `<languages id="0..3">` — déjà en texte clair (noms de langues).
 Map<int, List<String>> get languages; List<XmlRawSpellEntry> get innateSpells; List<XmlRawSpellEntry> get knownSpells;/// `<knownInvocation>` — noms d'invocations occultes en clair, liste
/// vide si le personnage n'en a aucune (cas normal pour toute classe
/// autre qu'Occultiste).
 List<String> get knownInvocations; int get gp; int get pp; int get ep; int get sp; int get cp;/// `<armor>` — `null` si absent du XML (ne devrait pas arriver sur un
/// export réel, ce tag existe toujours, mais un défaut défensif reste
/// préférable à une exception de parsing).
 int? get armor; int? get shield;/// `<weapon>` — liste positionnelle de jetons bruts (identifiants
/// d'arme attendus, non encore parsés en `int`, même rationale que
/// [skillsProf]), voir [weaponQuantities] (même index = même arme,
/// `AideddReferenceTables.weapons`).
 List<String> get weaponIds; List<int> get weaponQuantities;/// `<tools>` — objets physiques possédés (positionnel, jetons bruts non
/// encore parsés, sans liste de quantité dédiée dans le XML, quantité
/// toujours 1), *différent* de [toolsProf] — voir `AideddReferenceTables
/// .toolsEquipment`.
 List<String> get toolEquipmentIds;/// `<item>`/`<itemQ>` — listes positionnelles (jetons bruts non encore
/// parsés pour les identifiants, `AideddReferenceTables.items`).
 List<String> get itemIds; List<int> get itemQuantities;/// `<itemX>` — objets personnalisés en texte libre, séparés par
/// virgules dans le XML, déjà éclatés ici en liste. Pas positionnel par
/// rapport à [itemIds]/[itemQuantities] (nombre d'entrées différent,
/// voir `docs/xml-import-reference-mapping.md`).
 List<String> get customItemTexts; String get name;/// `<sexe>` — `null` si absent du XML.
 int? get sexe; int? get age; String? get height; String? get weight;/// `<alignment>` — `null` si absent du XML.
 int? get alignment; int? get xp; String? get eyes; String? get skin; String? get hair; String get appearanceText; String get traitsText; String get idealsText; String get bondsText; String get flawsText; String get backstoryText; String get alliesText; String get featuresText; String get treasureText;
/// Create a copy of XmlCharacterImportRaw
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlCharacterImportRawCopyWith<XmlCharacterImportRaw> get copyWith => _$XmlCharacterImportRawCopyWithImpl<XmlCharacterImportRaw>(this as XmlCharacterImportRaw, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlCharacterImportRaw&&(identical(other.race, race) || other.race == race)&&(identical(other.raceCustom, raceCustom) || other.raceCustom == raceCustom)&&(identical(other.characterClass, characterClass) || other.characterClass == characterClass)&&(identical(other.classPath, classPath) || other.classPath == classPath)&&(identical(other.level, level) || other.level == level)&&(identical(other.background, background) || other.background == background)&&(identical(other.backSpe, backSpe) || other.backSpe == backSpe)&&const DeepCollectionEquality().equals(other.abilityScores, abilityScores)&&const DeepCollectionEquality().equals(other.levels, levels)&&(identical(other.styleCombat1, styleCombat1) || other.styleCombat1 == styleCombat1)&&(identical(other.styleCombat2, styleCombat2) || other.styleCombat2 == styleCombat2)&&(identical(other.favoredEnemy0, favoredEnemy0) || other.favoredEnemy0 == favoredEnemy0)&&(identical(other.favoredEnemy6, favoredEnemy6) || other.favoredEnemy6 == favoredEnemy6)&&(identical(other.favoredEnemy14, favoredEnemy14) || other.favoredEnemy14 == favoredEnemy14)&&(identical(other.pack, pack) || other.pack == pack)&&const DeepCollectionEquality().equals(other.skillsProf, skillsProf)&&const DeepCollectionEquality().equals(other.toolsProf, toolsProf)&&const DeepCollectionEquality().equals(other.languages, languages)&&const DeepCollectionEquality().equals(other.innateSpells, innateSpells)&&const DeepCollectionEquality().equals(other.knownSpells, knownSpells)&&const DeepCollectionEquality().equals(other.knownInvocations, knownInvocations)&&(identical(other.gp, gp) || other.gp == gp)&&(identical(other.pp, pp) || other.pp == pp)&&(identical(other.ep, ep) || other.ep == ep)&&(identical(other.sp, sp) || other.sp == sp)&&(identical(other.cp, cp) || other.cp == cp)&&(identical(other.armor, armor) || other.armor == armor)&&(identical(other.shield, shield) || other.shield == shield)&&const DeepCollectionEquality().equals(other.weaponIds, weaponIds)&&const DeepCollectionEquality().equals(other.weaponQuantities, weaponQuantities)&&const DeepCollectionEquality().equals(other.toolEquipmentIds, toolEquipmentIds)&&const DeepCollectionEquality().equals(other.itemIds, itemIds)&&const DeepCollectionEquality().equals(other.itemQuantities, itemQuantities)&&const DeepCollectionEquality().equals(other.customItemTexts, customItemTexts)&&(identical(other.name, name) || other.name == name)&&(identical(other.sexe, sexe) || other.sexe == sexe)&&(identical(other.age, age) || other.age == age)&&(identical(other.height, height) || other.height == height)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.eyes, eyes) || other.eyes == eyes)&&(identical(other.skin, skin) || other.skin == skin)&&(identical(other.hair, hair) || other.hair == hair)&&(identical(other.appearanceText, appearanceText) || other.appearanceText == appearanceText)&&(identical(other.traitsText, traitsText) || other.traitsText == traitsText)&&(identical(other.idealsText, idealsText) || other.idealsText == idealsText)&&(identical(other.bondsText, bondsText) || other.bondsText == bondsText)&&(identical(other.flawsText, flawsText) || other.flawsText == flawsText)&&(identical(other.backstoryText, backstoryText) || other.backstoryText == backstoryText)&&(identical(other.alliesText, alliesText) || other.alliesText == alliesText)&&(identical(other.featuresText, featuresText) || other.featuresText == featuresText)&&(identical(other.treasureText, treasureText) || other.treasureText == treasureText));
}


@override
int get hashCode => Object.hashAll([runtimeType,race,raceCustom,characterClass,classPath,level,background,backSpe,const DeepCollectionEquality().hash(abilityScores),const DeepCollectionEquality().hash(levels),styleCombat1,styleCombat2,favoredEnemy0,favoredEnemy6,favoredEnemy14,pack,const DeepCollectionEquality().hash(skillsProf),const DeepCollectionEquality().hash(toolsProf),const DeepCollectionEquality().hash(languages),const DeepCollectionEquality().hash(innateSpells),const DeepCollectionEquality().hash(knownSpells),const DeepCollectionEquality().hash(knownInvocations),gp,pp,ep,sp,cp,armor,shield,const DeepCollectionEquality().hash(weaponIds),const DeepCollectionEquality().hash(weaponQuantities),const DeepCollectionEquality().hash(toolEquipmentIds),const DeepCollectionEquality().hash(itemIds),const DeepCollectionEquality().hash(itemQuantities),const DeepCollectionEquality().hash(customItemTexts),name,sexe,age,height,weight,alignment,xp,eyes,skin,hair,appearanceText,traitsText,idealsText,bondsText,flawsText,backstoryText,alliesText,featuresText,treasureText]);

@override
String toString() {
  return 'XmlCharacterImportRaw(race: $race, raceCustom: $raceCustom, characterClass: $characterClass, classPath: $classPath, level: $level, background: $background, backSpe: $backSpe, abilityScores: $abilityScores, levels: $levels, styleCombat1: $styleCombat1, styleCombat2: $styleCombat2, favoredEnemy0: $favoredEnemy0, favoredEnemy6: $favoredEnemy6, favoredEnemy14: $favoredEnemy14, pack: $pack, skillsProf: $skillsProf, toolsProf: $toolsProf, languages: $languages, innateSpells: $innateSpells, knownSpells: $knownSpells, knownInvocations: $knownInvocations, gp: $gp, pp: $pp, ep: $ep, sp: $sp, cp: $cp, armor: $armor, shield: $shield, weaponIds: $weaponIds, weaponQuantities: $weaponQuantities, toolEquipmentIds: $toolEquipmentIds, itemIds: $itemIds, itemQuantities: $itemQuantities, customItemTexts: $customItemTexts, name: $name, sexe: $sexe, age: $age, height: $height, weight: $weight, alignment: $alignment, xp: $xp, eyes: $eyes, skin: $skin, hair: $hair, appearanceText: $appearanceText, traitsText: $traitsText, idealsText: $idealsText, bondsText: $bondsText, flawsText: $flawsText, backstoryText: $backstoryText, alliesText: $alliesText, featuresText: $featuresText, treasureText: $treasureText)';
}


}

/// @nodoc
abstract mixin class $XmlCharacterImportRawCopyWith<$Res>  {
  factory $XmlCharacterImportRawCopyWith(XmlCharacterImportRaw value, $Res Function(XmlCharacterImportRaw) _then) = _$XmlCharacterImportRawCopyWithImpl;
@useResult
$Res call({
 String race, String? raceCustom, String characterClass, String? classPath, int level, String background, String? backSpe, Map<String, int> abilityScores, List<XmlRawLevelEntry> levels, String? styleCombat1, String? styleCombat2, String? favoredEnemy0, String? favoredEnemy6, String? favoredEnemy14, int? pack, Map<int, List<String>> skillsProf, Map<int, List<String>> toolsProf, Map<int, List<String>> languages, List<XmlRawSpellEntry> innateSpells, List<XmlRawSpellEntry> knownSpells, List<String> knownInvocations, int gp, int pp, int ep, int sp, int cp, int? armor, int? shield, List<String> weaponIds, List<int> weaponQuantities, List<String> toolEquipmentIds, List<String> itemIds, List<int> itemQuantities, List<String> customItemTexts, String name, int? sexe, int? age, String? height, String? weight, int? alignment, int? xp, String? eyes, String? skin, String? hair, String appearanceText, String traitsText, String idealsText, String bondsText, String flawsText, String backstoryText, String alliesText, String featuresText, String treasureText
});




}
/// @nodoc
class _$XmlCharacterImportRawCopyWithImpl<$Res>
    implements $XmlCharacterImportRawCopyWith<$Res> {
  _$XmlCharacterImportRawCopyWithImpl(this._self, this._then);

  final XmlCharacterImportRaw _self;
  final $Res Function(XmlCharacterImportRaw) _then;

/// Create a copy of XmlCharacterImportRaw
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? race = null,Object? raceCustom = freezed,Object? characterClass = null,Object? classPath = freezed,Object? level = null,Object? background = null,Object? backSpe = freezed,Object? abilityScores = null,Object? levels = null,Object? styleCombat1 = freezed,Object? styleCombat2 = freezed,Object? favoredEnemy0 = freezed,Object? favoredEnemy6 = freezed,Object? favoredEnemy14 = freezed,Object? pack = freezed,Object? skillsProf = null,Object? toolsProf = null,Object? languages = null,Object? innateSpells = null,Object? knownSpells = null,Object? knownInvocations = null,Object? gp = null,Object? pp = null,Object? ep = null,Object? sp = null,Object? cp = null,Object? armor = freezed,Object? shield = freezed,Object? weaponIds = null,Object? weaponQuantities = null,Object? toolEquipmentIds = null,Object? itemIds = null,Object? itemQuantities = null,Object? customItemTexts = null,Object? name = null,Object? sexe = freezed,Object? age = freezed,Object? height = freezed,Object? weight = freezed,Object? alignment = freezed,Object? xp = freezed,Object? eyes = freezed,Object? skin = freezed,Object? hair = freezed,Object? appearanceText = null,Object? traitsText = null,Object? idealsText = null,Object? bondsText = null,Object? flawsText = null,Object? backstoryText = null,Object? alliesText = null,Object? featuresText = null,Object? treasureText = null,}) {
  return _then(XmlCharacterImportRaw(
race: null == race ? _self.race : race // ignore: cast_nullable_to_non_nullable
as String,raceCustom: freezed == raceCustom ? _self.raceCustom : raceCustom // ignore: cast_nullable_to_non_nullable
as String?,characterClass: null == characterClass ? _self.characterClass : characterClass // ignore: cast_nullable_to_non_nullable
as String,classPath: freezed == classPath ? _self.classPath : classPath // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String,backSpe: freezed == backSpe ? _self.backSpe : backSpe // ignore: cast_nullable_to_non_nullable
as String?,abilityScores: null == abilityScores ? _self.abilityScores : abilityScores // ignore: cast_nullable_to_non_nullable
as Map<String, int>,levels: null == levels ? _self.levels : levels // ignore: cast_nullable_to_non_nullable
as List<XmlRawLevelEntry>,styleCombat1: freezed == styleCombat1 ? _self.styleCombat1 : styleCombat1 // ignore: cast_nullable_to_non_nullable
as String?,styleCombat2: freezed == styleCombat2 ? _self.styleCombat2 : styleCombat2 // ignore: cast_nullable_to_non_nullable
as String?,favoredEnemy0: freezed == favoredEnemy0 ? _self.favoredEnemy0 : favoredEnemy0 // ignore: cast_nullable_to_non_nullable
as String?,favoredEnemy6: freezed == favoredEnemy6 ? _self.favoredEnemy6 : favoredEnemy6 // ignore: cast_nullable_to_non_nullable
as String?,favoredEnemy14: freezed == favoredEnemy14 ? _self.favoredEnemy14 : favoredEnemy14 // ignore: cast_nullable_to_non_nullable
as String?,pack: freezed == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as int?,skillsProf: null == skillsProf ? _self.skillsProf : skillsProf // ignore: cast_nullable_to_non_nullable
as Map<int, List<String>>,toolsProf: null == toolsProf ? _self.toolsProf : toolsProf // ignore: cast_nullable_to_non_nullable
as Map<int, List<String>>,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as Map<int, List<String>>,innateSpells: null == innateSpells ? _self.innateSpells : innateSpells // ignore: cast_nullable_to_non_nullable
as List<XmlRawSpellEntry>,knownSpells: null == knownSpells ? _self.knownSpells : knownSpells // ignore: cast_nullable_to_non_nullable
as List<XmlRawSpellEntry>,knownInvocations: null == knownInvocations ? _self.knownInvocations : knownInvocations // ignore: cast_nullable_to_non_nullable
as List<String>,gp: null == gp ? _self.gp : gp // ignore: cast_nullable_to_non_nullable
as int,pp: null == pp ? _self.pp : pp // ignore: cast_nullable_to_non_nullable
as int,ep: null == ep ? _self.ep : ep // ignore: cast_nullable_to_non_nullable
as int,sp: null == sp ? _self.sp : sp // ignore: cast_nullable_to_non_nullable
as int,cp: null == cp ? _self.cp : cp // ignore: cast_nullable_to_non_nullable
as int,armor: freezed == armor ? _self.armor : armor // ignore: cast_nullable_to_non_nullable
as int?,shield: freezed == shield ? _self.shield : shield // ignore: cast_nullable_to_non_nullable
as int?,weaponIds: null == weaponIds ? _self.weaponIds : weaponIds // ignore: cast_nullable_to_non_nullable
as List<String>,weaponQuantities: null == weaponQuantities ? _self.weaponQuantities : weaponQuantities // ignore: cast_nullable_to_non_nullable
as List<int>,toolEquipmentIds: null == toolEquipmentIds ? _self.toolEquipmentIds : toolEquipmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,itemIds: null == itemIds ? _self.itemIds : itemIds // ignore: cast_nullable_to_non_nullable
as List<String>,itemQuantities: null == itemQuantities ? _self.itemQuantities : itemQuantities // ignore: cast_nullable_to_non_nullable
as List<int>,customItemTexts: null == customItemTexts ? _self.customItemTexts : customItemTexts // ignore: cast_nullable_to_non_nullable
as List<String>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sexe: freezed == sexe ? _self.sexe : sexe // ignore: cast_nullable_to_non_nullable
as int?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,alignment: freezed == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as int?,xp: freezed == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int?,eyes: freezed == eyes ? _self.eyes : eyes // ignore: cast_nullable_to_non_nullable
as String?,skin: freezed == skin ? _self.skin : skin // ignore: cast_nullable_to_non_nullable
as String?,hair: freezed == hair ? _self.hair : hair // ignore: cast_nullable_to_non_nullable
as String?,appearanceText: null == appearanceText ? _self.appearanceText : appearanceText // ignore: cast_nullable_to_non_nullable
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

}


/// Adds pattern-matching-related methods to [XmlCharacterImportRaw].
extension XmlCharacterImportRawPatterns on XmlCharacterImportRaw {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XmlCharacterImportRaw value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XmlCharacterImportRaw() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XmlCharacterImportRaw value)  $default,){
final _that = this;
switch (_that) {
case _XmlCharacterImportRaw():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XmlCharacterImportRaw value)?  $default,){
final _that = this;
switch (_that) {
case _XmlCharacterImportRaw() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String race,  String? raceCustom,  String characterClass,  String? classPath,  int level,  String background,  String? backSpe,  Map<String, int> abilityScores,  List<XmlRawLevelEntry> levels,  String? styleCombat1,  String? styleCombat2,  String? favoredEnemy0,  String? favoredEnemy6,  String? favoredEnemy14,  int? pack,  Map<int, List<String>> skillsProf,  Map<int, List<String>> toolsProf,  Map<int, List<String>> languages,  List<XmlRawSpellEntry> innateSpells,  List<XmlRawSpellEntry> knownSpells,  List<String> knownInvocations,  int gp,  int pp,  int ep,  int sp,  int cp,  int? armor,  int? shield,  List<String> weaponIds,  List<int> weaponQuantities,  List<String> toolEquipmentIds,  List<String> itemIds,  List<int> itemQuantities,  List<String> customItemTexts,  String name,  int? sexe,  int? age,  String? height,  String? weight,  int? alignment,  int? xp,  String? eyes,  String? skin,  String? hair,  String appearanceText,  String traitsText,  String idealsText,  String bondsText,  String flawsText,  String backstoryText,  String alliesText,  String featuresText,  String treasureText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XmlCharacterImportRaw() when $default != null:
return $default(_that.race,_that.raceCustom,_that.characterClass,_that.classPath,_that.level,_that.background,_that.backSpe,_that.abilityScores,_that.levels,_that.styleCombat1,_that.styleCombat2,_that.favoredEnemy0,_that.favoredEnemy6,_that.favoredEnemy14,_that.pack,_that.skillsProf,_that.toolsProf,_that.languages,_that.innateSpells,_that.knownSpells,_that.knownInvocations,_that.gp,_that.pp,_that.ep,_that.sp,_that.cp,_that.armor,_that.shield,_that.weaponIds,_that.weaponQuantities,_that.toolEquipmentIds,_that.itemIds,_that.itemQuantities,_that.customItemTexts,_that.name,_that.sexe,_that.age,_that.height,_that.weight,_that.alignment,_that.xp,_that.eyes,_that.skin,_that.hair,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String race,  String? raceCustom,  String characterClass,  String? classPath,  int level,  String background,  String? backSpe,  Map<String, int> abilityScores,  List<XmlRawLevelEntry> levels,  String? styleCombat1,  String? styleCombat2,  String? favoredEnemy0,  String? favoredEnemy6,  String? favoredEnemy14,  int? pack,  Map<int, List<String>> skillsProf,  Map<int, List<String>> toolsProf,  Map<int, List<String>> languages,  List<XmlRawSpellEntry> innateSpells,  List<XmlRawSpellEntry> knownSpells,  List<String> knownInvocations,  int gp,  int pp,  int ep,  int sp,  int cp,  int? armor,  int? shield,  List<String> weaponIds,  List<int> weaponQuantities,  List<String> toolEquipmentIds,  List<String> itemIds,  List<int> itemQuantities,  List<String> customItemTexts,  String name,  int? sexe,  int? age,  String? height,  String? weight,  int? alignment,  int? xp,  String? eyes,  String? skin,  String? hair,  String appearanceText,  String traitsText,  String idealsText,  String bondsText,  String flawsText,  String backstoryText,  String alliesText,  String featuresText,  String treasureText)  $default,) {final _that = this;
switch (_that) {
case _XmlCharacterImportRaw():
return $default(_that.race,_that.raceCustom,_that.characterClass,_that.classPath,_that.level,_that.background,_that.backSpe,_that.abilityScores,_that.levels,_that.styleCombat1,_that.styleCombat2,_that.favoredEnemy0,_that.favoredEnemy6,_that.favoredEnemy14,_that.pack,_that.skillsProf,_that.toolsProf,_that.languages,_that.innateSpells,_that.knownSpells,_that.knownInvocations,_that.gp,_that.pp,_that.ep,_that.sp,_that.cp,_that.armor,_that.shield,_that.weaponIds,_that.weaponQuantities,_that.toolEquipmentIds,_that.itemIds,_that.itemQuantities,_that.customItemTexts,_that.name,_that.sexe,_that.age,_that.height,_that.weight,_that.alignment,_that.xp,_that.eyes,_that.skin,_that.hair,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String race,  String? raceCustom,  String characterClass,  String? classPath,  int level,  String background,  String? backSpe,  Map<String, int> abilityScores,  List<XmlRawLevelEntry> levels,  String? styleCombat1,  String? styleCombat2,  String? favoredEnemy0,  String? favoredEnemy6,  String? favoredEnemy14,  int? pack,  Map<int, List<String>> skillsProf,  Map<int, List<String>> toolsProf,  Map<int, List<String>> languages,  List<XmlRawSpellEntry> innateSpells,  List<XmlRawSpellEntry> knownSpells,  List<String> knownInvocations,  int gp,  int pp,  int ep,  int sp,  int cp,  int? armor,  int? shield,  List<String> weaponIds,  List<int> weaponQuantities,  List<String> toolEquipmentIds,  List<String> itemIds,  List<int> itemQuantities,  List<String> customItemTexts,  String name,  int? sexe,  int? age,  String? height,  String? weight,  int? alignment,  int? xp,  String? eyes,  String? skin,  String? hair,  String appearanceText,  String traitsText,  String idealsText,  String bondsText,  String flawsText,  String backstoryText,  String alliesText,  String featuresText,  String treasureText)?  $default,) {final _that = this;
switch (_that) {
case _XmlCharacterImportRaw() when $default != null:
return $default(_that.race,_that.raceCustom,_that.characterClass,_that.classPath,_that.level,_that.background,_that.backSpe,_that.abilityScores,_that.levels,_that.styleCombat1,_that.styleCombat2,_that.favoredEnemy0,_that.favoredEnemy6,_that.favoredEnemy14,_that.pack,_that.skillsProf,_that.toolsProf,_that.languages,_that.innateSpells,_that.knownSpells,_that.knownInvocations,_that.gp,_that.pp,_that.ep,_that.sp,_that.cp,_that.armor,_that.shield,_that.weaponIds,_that.weaponQuantities,_that.toolEquipmentIds,_that.itemIds,_that.itemQuantities,_that.customItemTexts,_that.name,_that.sexe,_that.age,_that.height,_that.weight,_that.alignment,_that.xp,_that.eyes,_that.skin,_that.hair,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
  return null;

}
}

}

/// @nodoc


class _XmlCharacterImportRaw implements XmlCharacterImportRaw {
  const _XmlCharacterImportRaw({required this.race, this.raceCustom, required this.characterClass, this.classPath, required this.level, required this.background, this.backSpe, required  Map<String, int> abilityScores, required  List<XmlRawLevelEntry> levels, this.styleCombat1, this.styleCombat2, this.favoredEnemy0, this.favoredEnemy6, this.favoredEnemy14, this.pack, required  Map<int, List<String>> skillsProf, required  Map<int, List<String>> toolsProf, required  Map<int, List<String>> languages,  List<XmlRawSpellEntry> innateSpells = const <XmlRawSpellEntry>[],  List<XmlRawSpellEntry> knownSpells = const <XmlRawSpellEntry>[],  List<String> knownInvocations = const <String>[], required this.gp, required this.pp, required this.ep, required this.sp, required this.cp, this.armor, this.shield,  List<String> weaponIds = const <String>[],  List<int> weaponQuantities = const <int>[],  List<String> toolEquipmentIds = const <String>[],  List<String> itemIds = const <String>[],  List<int> itemQuantities = const <int>[],  List<String> customItemTexts = const <String>[], required this.name, this.sexe, this.age, this.height, this.weight, this.alignment, this.xp, this.eyes, this.skin, this.hair, this.appearanceText = '', this.traitsText = '', this.idealsText = '', this.bondsText = '', this.flawsText = '', this.backstoryText = '', this.alliesText = '', this.featuresText = '', this.treasureText = ''}): _abilityScores = abilityScores,_levels = levels,_skillsProf = skillsProf,_toolsProf = toolsProf,_languages = languages,_innateSpells = innateSpells,_knownSpells = knownSpells,_knownInvocations = knownInvocations,_weaponIds = weaponIds,_weaponQuantities = weaponQuantities,_toolEquipmentIds = toolEquipmentIds,_itemIds = itemIds,_itemQuantities = itemQuantities,_customItemTexts = customItemTexts;
  

@override final  String race;
/// `<raceCustom>` — flag brut non interprété, voir
/// `xml-import-reference-mapping.md` section "Point encore ouvert :
/// raceCustom" (son sens exact reste incertain, traité comme informatif
/// par [XmlCharacterImportResolver], jamais bloquant).
@override final  String? raceCustom;
/// `<class>` — champ nommé `characterClass` plutôt que `class`, mot
/// réservé Dart.
@override final  String characterClass;
/// `<classPath>` — `null` si absent du XML (personnage n'ayant pas
/// encore choisi de sous-classe), jamais une chaîne vide.
@override final  String? classPath;
@override final  int level;
@override final  String background;
/// `<backSpe>` — note libre d'historique personnalisé, jamais résolue
/// par nom (ce n'est pas un nom d'historique, juste un complément
/// textuel).
@override final  String? backSpe;
/// `<str>`,`<dex>`,`<con>`,`<int>`,`<wis>`,`<cha>`, clés `'str'`/`'dex'`/
/// `'con'`/`'int'`/`'wis'`/`'cha'` — même convention de clés que
/// `CharacterCreationDraft.abilityScores`.
 final  Map<String, int> _abilityScores;
/// `<str>`,`<dex>`,`<con>`,`<int>`,`<wis>`,`<cha>`, clés `'str'`/`'dex'`/
/// `'con'`/`'int'`/`'wis'`/`'cha'` — même convention de clés que
/// `CharacterCreationDraft.abilityScores`.
@override Map<String, int> get abilityScores {
  if (_abilityScores is EqualUnmodifiableMapView) return _abilityScores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_abilityScores);
}

/// `<lvl lvl="X">` — une entrée par niveau présent dans le XML (20 dans
/// les deux fixtures réelles, 1 à 20).
 final  List<XmlRawLevelEntry> _levels;
/// `<lvl lvl="X">` — une entrée par niveau présent dans le XML (20 dans
/// les deux fixtures réelles, 1 à 20).
@override List<XmlRawLevelEntry> get levels {
  if (_levels is EqualUnmodifiableListView) return _levels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_levels);
}

@override final  String? styleCombat1;
@override final  String? styleCombat2;
@override final  String? favoredEnemy0;
@override final  String? favoredEnemy6;
@override final  String? favoredEnemy14;
/// `<pack>` — `null` si absent du XML.
@override final  int? pack;
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
 final  Map<int, List<String>> _skillsProf;
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
@override Map<int, List<String>> get skillsProf {
  if (_skillsProf is EqualUnmodifiableMapView) return _skillsProf;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_skillsProf);
}

/// `<toolsProf id="0..3">` — déjà en texte clair (noms d'outils), à la
/// différence de `skillsProf`, voir la documentation de classe.
 final  Map<int, List<String>> _toolsProf;
/// `<toolsProf id="0..3">` — déjà en texte clair (noms d'outils), à la
/// différence de `skillsProf`, voir la documentation de classe.
@override Map<int, List<String>> get toolsProf {
  if (_toolsProf is EqualUnmodifiableMapView) return _toolsProf;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_toolsProf);
}

/// `<languages id="0..3">` — déjà en texte clair (noms de langues).
 final  Map<int, List<String>> _languages;
/// `<languages id="0..3">` — déjà en texte clair (noms de langues).
@override Map<int, List<String>> get languages {
  if (_languages is EqualUnmodifiableMapView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_languages);
}

 final  List<XmlRawSpellEntry> _innateSpells;
@override@JsonKey() List<XmlRawSpellEntry> get innateSpells {
  if (_innateSpells is EqualUnmodifiableListView) return _innateSpells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_innateSpells);
}

 final  List<XmlRawSpellEntry> _knownSpells;
@override@JsonKey() List<XmlRawSpellEntry> get knownSpells {
  if (_knownSpells is EqualUnmodifiableListView) return _knownSpells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownSpells);
}

/// `<knownInvocation>` — noms d'invocations occultes en clair, liste
/// vide si le personnage n'en a aucune (cas normal pour toute classe
/// autre qu'Occultiste).
 final  List<String> _knownInvocations;
/// `<knownInvocation>` — noms d'invocations occultes en clair, liste
/// vide si le personnage n'en a aucune (cas normal pour toute classe
/// autre qu'Occultiste).
@override@JsonKey() List<String> get knownInvocations {
  if (_knownInvocations is EqualUnmodifiableListView) return _knownInvocations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownInvocations);
}

@override final  int gp;
@override final  int pp;
@override final  int ep;
@override final  int sp;
@override final  int cp;
/// `<armor>` — `null` si absent du XML (ne devrait pas arriver sur un
/// export réel, ce tag existe toujours, mais un défaut défensif reste
/// préférable à une exception de parsing).
@override final  int? armor;
@override final  int? shield;
/// `<weapon>` — liste positionnelle de jetons bruts (identifiants
/// d'arme attendus, non encore parsés en `int`, même rationale que
/// [skillsProf]), voir [weaponQuantities] (même index = même arme,
/// `AideddReferenceTables.weapons`).
 final  List<String> _weaponIds;
/// `<weapon>` — liste positionnelle de jetons bruts (identifiants
/// d'arme attendus, non encore parsés en `int`, même rationale que
/// [skillsProf]), voir [weaponQuantities] (même index = même arme,
/// `AideddReferenceTables.weapons`).
@override@JsonKey() List<String> get weaponIds {
  if (_weaponIds is EqualUnmodifiableListView) return _weaponIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weaponIds);
}

 final  List<int> _weaponQuantities;
@override@JsonKey() List<int> get weaponQuantities {
  if (_weaponQuantities is EqualUnmodifiableListView) return _weaponQuantities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weaponQuantities);
}

/// `<tools>` — objets physiques possédés (positionnel, jetons bruts non
/// encore parsés, sans liste de quantité dédiée dans le XML, quantité
/// toujours 1), *différent* de [toolsProf] — voir `AideddReferenceTables
/// .toolsEquipment`.
 final  List<String> _toolEquipmentIds;
/// `<tools>` — objets physiques possédés (positionnel, jetons bruts non
/// encore parsés, sans liste de quantité dédiée dans le XML, quantité
/// toujours 1), *différent* de [toolsProf] — voir `AideddReferenceTables
/// .toolsEquipment`.
@override@JsonKey() List<String> get toolEquipmentIds {
  if (_toolEquipmentIds is EqualUnmodifiableListView) return _toolEquipmentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolEquipmentIds);
}

/// `<item>`/`<itemQ>` — listes positionnelles (jetons bruts non encore
/// parsés pour les identifiants, `AideddReferenceTables.items`).
 final  List<String> _itemIds;
/// `<item>`/`<itemQ>` — listes positionnelles (jetons bruts non encore
/// parsés pour les identifiants, `AideddReferenceTables.items`).
@override@JsonKey() List<String> get itemIds {
  if (_itemIds is EqualUnmodifiableListView) return _itemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itemIds);
}

 final  List<int> _itemQuantities;
@override@JsonKey() List<int> get itemQuantities {
  if (_itemQuantities is EqualUnmodifiableListView) return _itemQuantities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itemQuantities);
}

/// `<itemX>` — objets personnalisés en texte libre, séparés par
/// virgules dans le XML, déjà éclatés ici en liste. Pas positionnel par
/// rapport à [itemIds]/[itemQuantities] (nombre d'entrées différent,
/// voir `docs/xml-import-reference-mapping.md`).
 final  List<String> _customItemTexts;
/// `<itemX>` — objets personnalisés en texte libre, séparés par
/// virgules dans le XML, déjà éclatés ici en liste. Pas positionnel par
/// rapport à [itemIds]/[itemQuantities] (nombre d'entrées différent,
/// voir `docs/xml-import-reference-mapping.md`).
@override@JsonKey() List<String> get customItemTexts {
  if (_customItemTexts is EqualUnmodifiableListView) return _customItemTexts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customItemTexts);
}

@override final  String name;
/// `<sexe>` — `null` si absent du XML.
@override final  int? sexe;
@override final  int? age;
@override final  String? height;
@override final  String? weight;
/// `<alignment>` — `null` si absent du XML.
@override final  int? alignment;
@override final  int? xp;
@override final  String? eyes;
@override final  String? skin;
@override final  String? hair;
@override@JsonKey() final  String appearanceText;
@override@JsonKey() final  String traitsText;
@override@JsonKey() final  String idealsText;
@override@JsonKey() final  String bondsText;
@override@JsonKey() final  String flawsText;
@override@JsonKey() final  String backstoryText;
@override@JsonKey() final  String alliesText;
@override@JsonKey() final  String featuresText;
@override@JsonKey() final  String treasureText;

/// Create a copy of XmlCharacterImportRaw
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XmlCharacterImportRawCopyWith<_XmlCharacterImportRaw> get copyWith => __$XmlCharacterImportRawCopyWithImpl<_XmlCharacterImportRaw>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _XmlCharacterImportRaw&&(identical(other.race, race) || other.race == race)&&(identical(other.raceCustom, raceCustom) || other.raceCustom == raceCustom)&&(identical(other.characterClass, characterClass) || other.characterClass == characterClass)&&(identical(other.classPath, classPath) || other.classPath == classPath)&&(identical(other.level, level) || other.level == level)&&(identical(other.background, background) || other.background == background)&&(identical(other.backSpe, backSpe) || other.backSpe == backSpe)&&const DeepCollectionEquality().equals(other._abilityScores, _abilityScores)&&const DeepCollectionEquality().equals(other._levels, _levels)&&(identical(other.styleCombat1, styleCombat1) || other.styleCombat1 == styleCombat1)&&(identical(other.styleCombat2, styleCombat2) || other.styleCombat2 == styleCombat2)&&(identical(other.favoredEnemy0, favoredEnemy0) || other.favoredEnemy0 == favoredEnemy0)&&(identical(other.favoredEnemy6, favoredEnemy6) || other.favoredEnemy6 == favoredEnemy6)&&(identical(other.favoredEnemy14, favoredEnemy14) || other.favoredEnemy14 == favoredEnemy14)&&(identical(other.pack, pack) || other.pack == pack)&&const DeepCollectionEquality().equals(other._skillsProf, _skillsProf)&&const DeepCollectionEquality().equals(other._toolsProf, _toolsProf)&&const DeepCollectionEquality().equals(other._languages, _languages)&&const DeepCollectionEquality().equals(other._innateSpells, _innateSpells)&&const DeepCollectionEquality().equals(other._knownSpells, _knownSpells)&&const DeepCollectionEquality().equals(other._knownInvocations, _knownInvocations)&&(identical(other.gp, gp) || other.gp == gp)&&(identical(other.pp, pp) || other.pp == pp)&&(identical(other.ep, ep) || other.ep == ep)&&(identical(other.sp, sp) || other.sp == sp)&&(identical(other.cp, cp) || other.cp == cp)&&(identical(other.armor, armor) || other.armor == armor)&&(identical(other.shield, shield) || other.shield == shield)&&const DeepCollectionEquality().equals(other._weaponIds, _weaponIds)&&const DeepCollectionEquality().equals(other._weaponQuantities, _weaponQuantities)&&const DeepCollectionEquality().equals(other._toolEquipmentIds, _toolEquipmentIds)&&const DeepCollectionEquality().equals(other._itemIds, _itemIds)&&const DeepCollectionEquality().equals(other._itemQuantities, _itemQuantities)&&const DeepCollectionEquality().equals(other._customItemTexts, _customItemTexts)&&(identical(other.name, name) || other.name == name)&&(identical(other.sexe, sexe) || other.sexe == sexe)&&(identical(other.age, age) || other.age == age)&&(identical(other.height, height) || other.height == height)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.eyes, eyes) || other.eyes == eyes)&&(identical(other.skin, skin) || other.skin == skin)&&(identical(other.hair, hair) || other.hair == hair)&&(identical(other.appearanceText, appearanceText) || other.appearanceText == appearanceText)&&(identical(other.traitsText, traitsText) || other.traitsText == traitsText)&&(identical(other.idealsText, idealsText) || other.idealsText == idealsText)&&(identical(other.bondsText, bondsText) || other.bondsText == bondsText)&&(identical(other.flawsText, flawsText) || other.flawsText == flawsText)&&(identical(other.backstoryText, backstoryText) || other.backstoryText == backstoryText)&&(identical(other.alliesText, alliesText) || other.alliesText == alliesText)&&(identical(other.featuresText, featuresText) || other.featuresText == featuresText)&&(identical(other.treasureText, treasureText) || other.treasureText == treasureText));
}


@override
int get hashCode => Object.hashAll([runtimeType,race,raceCustom,characterClass,classPath,level,background,backSpe,const DeepCollectionEquality().hash(_abilityScores),const DeepCollectionEquality().hash(_levels),styleCombat1,styleCombat2,favoredEnemy0,favoredEnemy6,favoredEnemy14,pack,const DeepCollectionEquality().hash(_skillsProf),const DeepCollectionEquality().hash(_toolsProf),const DeepCollectionEquality().hash(_languages),const DeepCollectionEquality().hash(_innateSpells),const DeepCollectionEquality().hash(_knownSpells),const DeepCollectionEquality().hash(_knownInvocations),gp,pp,ep,sp,cp,armor,shield,const DeepCollectionEquality().hash(_weaponIds),const DeepCollectionEquality().hash(_weaponQuantities),const DeepCollectionEquality().hash(_toolEquipmentIds),const DeepCollectionEquality().hash(_itemIds),const DeepCollectionEquality().hash(_itemQuantities),const DeepCollectionEquality().hash(_customItemTexts),name,sexe,age,height,weight,alignment,xp,eyes,skin,hair,appearanceText,traitsText,idealsText,bondsText,flawsText,backstoryText,alliesText,featuresText,treasureText]);

@override
String toString() {
  return 'XmlCharacterImportRaw(race: $race, raceCustom: $raceCustom, characterClass: $characterClass, classPath: $classPath, level: $level, background: $background, backSpe: $backSpe, abilityScores: $abilityScores, levels: $levels, styleCombat1: $styleCombat1, styleCombat2: $styleCombat2, favoredEnemy0: $favoredEnemy0, favoredEnemy6: $favoredEnemy6, favoredEnemy14: $favoredEnemy14, pack: $pack, skillsProf: $skillsProf, toolsProf: $toolsProf, languages: $languages, innateSpells: $innateSpells, knownSpells: $knownSpells, knownInvocations: $knownInvocations, gp: $gp, pp: $pp, ep: $ep, sp: $sp, cp: $cp, armor: $armor, shield: $shield, weaponIds: $weaponIds, weaponQuantities: $weaponQuantities, toolEquipmentIds: $toolEquipmentIds, itemIds: $itemIds, itemQuantities: $itemQuantities, customItemTexts: $customItemTexts, name: $name, sexe: $sexe, age: $age, height: $height, weight: $weight, alignment: $alignment, xp: $xp, eyes: $eyes, skin: $skin, hair: $hair, appearanceText: $appearanceText, traitsText: $traitsText, idealsText: $idealsText, bondsText: $bondsText, flawsText: $flawsText, backstoryText: $backstoryText, alliesText: $alliesText, featuresText: $featuresText, treasureText: $treasureText)';
}


}

/// @nodoc
abstract mixin class _$XmlCharacterImportRawCopyWith<$Res> implements $XmlCharacterImportRawCopyWith<$Res> {
  factory _$XmlCharacterImportRawCopyWith(_XmlCharacterImportRaw value, $Res Function(_XmlCharacterImportRaw) _then) = __$XmlCharacterImportRawCopyWithImpl;
@override @useResult
$Res call({
 String race, String? raceCustom, String characterClass, String? classPath, int level, String background, String? backSpe, Map<String, int> abilityScores, List<XmlRawLevelEntry> levels, String? styleCombat1, String? styleCombat2, String? favoredEnemy0, String? favoredEnemy6, String? favoredEnemy14, int? pack, Map<int, List<String>> skillsProf, Map<int, List<String>> toolsProf, Map<int, List<String>> languages, List<XmlRawSpellEntry> innateSpells, List<XmlRawSpellEntry> knownSpells, List<String> knownInvocations, int gp, int pp, int ep, int sp, int cp, int? armor, int? shield, List<String> weaponIds, List<int> weaponQuantities, List<String> toolEquipmentIds, List<String> itemIds, List<int> itemQuantities, List<String> customItemTexts, String name, int? sexe, int? age, String? height, String? weight, int? alignment, int? xp, String? eyes, String? skin, String? hair, String appearanceText, String traitsText, String idealsText, String bondsText, String flawsText, String backstoryText, String alliesText, String featuresText, String treasureText
});




}
/// @nodoc
class __$XmlCharacterImportRawCopyWithImpl<$Res>
    implements _$XmlCharacterImportRawCopyWith<$Res> {
  __$XmlCharacterImportRawCopyWithImpl(this._self, this._then);

  final _XmlCharacterImportRaw _self;
  final $Res Function(_XmlCharacterImportRaw) _then;

/// Create a copy of XmlCharacterImportRaw
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? race = null,Object? raceCustom = freezed,Object? characterClass = null,Object? classPath = freezed,Object? level = null,Object? background = null,Object? backSpe = freezed,Object? abilityScores = null,Object? levels = null,Object? styleCombat1 = freezed,Object? styleCombat2 = freezed,Object? favoredEnemy0 = freezed,Object? favoredEnemy6 = freezed,Object? favoredEnemy14 = freezed,Object? pack = freezed,Object? skillsProf = null,Object? toolsProf = null,Object? languages = null,Object? innateSpells = null,Object? knownSpells = null,Object? knownInvocations = null,Object? gp = null,Object? pp = null,Object? ep = null,Object? sp = null,Object? cp = null,Object? armor = freezed,Object? shield = freezed,Object? weaponIds = null,Object? weaponQuantities = null,Object? toolEquipmentIds = null,Object? itemIds = null,Object? itemQuantities = null,Object? customItemTexts = null,Object? name = null,Object? sexe = freezed,Object? age = freezed,Object? height = freezed,Object? weight = freezed,Object? alignment = freezed,Object? xp = freezed,Object? eyes = freezed,Object? skin = freezed,Object? hair = freezed,Object? appearanceText = null,Object? traitsText = null,Object? idealsText = null,Object? bondsText = null,Object? flawsText = null,Object? backstoryText = null,Object? alliesText = null,Object? featuresText = null,Object? treasureText = null,}) {
  return _then(_XmlCharacterImportRaw(
race: null == race ? _self.race : race // ignore: cast_nullable_to_non_nullable
as String,raceCustom: freezed == raceCustom ? _self.raceCustom : raceCustom // ignore: cast_nullable_to_non_nullable
as String?,characterClass: null == characterClass ? _self.characterClass : characterClass // ignore: cast_nullable_to_non_nullable
as String,classPath: freezed == classPath ? _self.classPath : classPath // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String,backSpe: freezed == backSpe ? _self.backSpe : backSpe // ignore: cast_nullable_to_non_nullable
as String?,abilityScores: null == abilityScores ? _self._abilityScores : abilityScores // ignore: cast_nullable_to_non_nullable
as Map<String, int>,levels: null == levels ? _self._levels : levels // ignore: cast_nullable_to_non_nullable
as List<XmlRawLevelEntry>,styleCombat1: freezed == styleCombat1 ? _self.styleCombat1 : styleCombat1 // ignore: cast_nullable_to_non_nullable
as String?,styleCombat2: freezed == styleCombat2 ? _self.styleCombat2 : styleCombat2 // ignore: cast_nullable_to_non_nullable
as String?,favoredEnemy0: freezed == favoredEnemy0 ? _self.favoredEnemy0 : favoredEnemy0 // ignore: cast_nullable_to_non_nullable
as String?,favoredEnemy6: freezed == favoredEnemy6 ? _self.favoredEnemy6 : favoredEnemy6 // ignore: cast_nullable_to_non_nullable
as String?,favoredEnemy14: freezed == favoredEnemy14 ? _self.favoredEnemy14 : favoredEnemy14 // ignore: cast_nullable_to_non_nullable
as String?,pack: freezed == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as int?,skillsProf: null == skillsProf ? _self._skillsProf : skillsProf // ignore: cast_nullable_to_non_nullable
as Map<int, List<String>>,toolsProf: null == toolsProf ? _self._toolsProf : toolsProf // ignore: cast_nullable_to_non_nullable
as Map<int, List<String>>,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as Map<int, List<String>>,innateSpells: null == innateSpells ? _self._innateSpells : innateSpells // ignore: cast_nullable_to_non_nullable
as List<XmlRawSpellEntry>,knownSpells: null == knownSpells ? _self._knownSpells : knownSpells // ignore: cast_nullable_to_non_nullable
as List<XmlRawSpellEntry>,knownInvocations: null == knownInvocations ? _self._knownInvocations : knownInvocations // ignore: cast_nullable_to_non_nullable
as List<String>,gp: null == gp ? _self.gp : gp // ignore: cast_nullable_to_non_nullable
as int,pp: null == pp ? _self.pp : pp // ignore: cast_nullable_to_non_nullable
as int,ep: null == ep ? _self.ep : ep // ignore: cast_nullable_to_non_nullable
as int,sp: null == sp ? _self.sp : sp // ignore: cast_nullable_to_non_nullable
as int,cp: null == cp ? _self.cp : cp // ignore: cast_nullable_to_non_nullable
as int,armor: freezed == armor ? _self.armor : armor // ignore: cast_nullable_to_non_nullable
as int?,shield: freezed == shield ? _self.shield : shield // ignore: cast_nullable_to_non_nullable
as int?,weaponIds: null == weaponIds ? _self._weaponIds : weaponIds // ignore: cast_nullable_to_non_nullable
as List<String>,weaponQuantities: null == weaponQuantities ? _self._weaponQuantities : weaponQuantities // ignore: cast_nullable_to_non_nullable
as List<int>,toolEquipmentIds: null == toolEquipmentIds ? _self._toolEquipmentIds : toolEquipmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,itemIds: null == itemIds ? _self._itemIds : itemIds // ignore: cast_nullable_to_non_nullable
as List<String>,itemQuantities: null == itemQuantities ? _self._itemQuantities : itemQuantities // ignore: cast_nullable_to_non_nullable
as List<int>,customItemTexts: null == customItemTexts ? _self._customItemTexts : customItemTexts // ignore: cast_nullable_to_non_nullable
as List<String>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sexe: freezed == sexe ? _self.sexe : sexe // ignore: cast_nullable_to_non_nullable
as int?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,alignment: freezed == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as int?,xp: freezed == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int?,eyes: freezed == eyes ? _self.eyes : eyes // ignore: cast_nullable_to_non_nullable
as String?,skin: freezed == skin ? _self.skin : skin // ignore: cast_nullable_to_non_nullable
as String?,hair: freezed == hair ? _self.hair : hair // ignore: cast_nullable_to_non_nullable
as String?,appearanceText: null == appearanceText ? _self.appearanceText : appearanceText // ignore: cast_nullable_to_non_nullable
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


}

// dart format on
