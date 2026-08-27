// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CharacterDetail {

 String get id; String get name;/// URL publique du portrait (`characters.portrait_url`), `null` si le
/// joueur n'en a pas encore défini un.
 String? get portraitUrl;/// Nom de race traduit, `null` si non résolu (race personnalisée ou
/// `race_id` nul).
 String? get raceName;/// Nom de sous-race traduit, `null` si le personnage n'a pas de
/// sous-race.
 String? get subraceName;/// Texte libre de race personnalisée (`characters.race_custom_text`),
/// `null` si le personnage a une race du catalogue.
 String? get raceCustomText;/// Nom d'historique traduit, `null` si `background_id` est nul.
 String? get backgroundName;/// Nom d'alignement traduit, `null` si `alignment_id` est nul.
 String? get alignmentName;/// Toutes les lignes `character_classes` du personnage (multiclassage
/// inclus), dans l'ordre renvoyé par PostgREST.
 List<CharacterDetailClassRow> get classes; int get xp; int get currentHp; int get maxHp; int get temporaryHp;/// Scores finaux par caractéristique (`character_ability_scores`), clé
/// 'str'/'dex'/'con'/'int'/'wis'/'cha' — déjà le score final en base,
/// aucun bonus racial à recalculer ici (voir
/// `character_creation/domain/final_ability_scores_resolver.dart` pour
/// l'endroit où ce calcul a déjà eu lieu, à la création).
 Map<String, int> get abilityScores;/// Les 18 compétences résolues (nom, caractéristique, maîtrise) —
/// onglet "Compétences", carte "LES 18 COMPÉTENCES". Liste vide tant
/// qu'aucune compétence de référence n'a pu être résolue (ne devrait
/// arriver que pour un stack de contenu vide).
 List<CharacterSkillRow> get skills;/// Aptitudes de classe déjà atteintes par le niveau actuel du
/// personnage — onglet "Compétences", carte "APTITUDES DE CLASSE". Voir
/// la documentation de classe de [CharacterClassFeature] pour la portée
/// (aptitudes de sous-classe jamais incluses à cette itération).
 List<CharacterClassFeature> get classFeatures;/// Noms des outils dont le personnage est compétent (texte libre inclus)
/// — onglet "Compétences", carte "MAÎTRISES D'OUTILS".
 List<String> get toolProficiencyNames;/// Noms des langues connues — onglet "Compétences", carte "LANGUES
/// CONNUES".
 List<String> get knownLanguageNames;/// Sorts connus/préparés du personnage — onglet "Compétences", section
/// "SORTS". Liste vide pour un personnage qui ne lance pas de sorts (pas
/// de distinction stockée entre "classe non lanceuse" et "lanceuse sans
/// sort encore choisi" : les deux cas affichent simplement une section
/// absente, voir `presentation/widgets/character_skills_tab_body.dart`).
 List<CharacterSpellEntry> get spells;/// Emplacements de sorts par niveau (1 à 9) — onglet "Compétences",
/// section "SORTS".
 List<CharacterSpellSlot> get spellSlots;/// Monnaie du personnage (`characters.currency_gp/pp/ep/sp/cp`) — onglet
/// "Inventaire", rangée de stat boxes (voir
/// `domain/inventory_stat_boxes_resolver.dart`). `@Default(0)` comme les
/// autres champs ajoutés après la première version de ce modèle
/// (`skills`/`classFeatures`/...) : évite de devoir toucher tous les
/// sites de construction directe de [CharacterDetail] déjà existants
/// dans les tests (voir la même remarque sur ces champs ci-dessus).
 int get currencyGp; int get currencyPp; int get currencyEp; int get currencySp; int get currencyCp;/// Inventaire résolu du personnage — onglet "Inventaire", liste de
/// cartes. Comme [skills]/[classFeatures]/..., a besoin d'une requête
/// PostgREST séparée (résolution des noms d'objets du catalogue via
/// `translations`), voir `SupabaseCharacterRepository._fetchInventory`.
 List<CharacterInventoryItem> get inventory;
/// Create a copy of CharacterDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterDetailCopyWith<CharacterDetail> get copyWith => _$CharacterDetailCopyWithImpl<CharacterDetail>(this as CharacterDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.portraitUrl, portraitUrl) || other.portraitUrl == portraitUrl)&&(identical(other.raceName, raceName) || other.raceName == raceName)&&(identical(other.subraceName, subraceName) || other.subraceName == subraceName)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.backgroundName, backgroundName) || other.backgroundName == backgroundName)&&(identical(other.alignmentName, alignmentName) || other.alignmentName == alignmentName)&&const DeepCollectionEquality().equals(other.classes, classes)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.currentHp, currentHp) || other.currentHp == currentHp)&&(identical(other.maxHp, maxHp) || other.maxHp == maxHp)&&(identical(other.temporaryHp, temporaryHp) || other.temporaryHp == temporaryHp)&&const DeepCollectionEquality().equals(other.abilityScores, abilityScores)&&const DeepCollectionEquality().equals(other.skills, skills)&&const DeepCollectionEquality().equals(other.classFeatures, classFeatures)&&const DeepCollectionEquality().equals(other.toolProficiencyNames, toolProficiencyNames)&&const DeepCollectionEquality().equals(other.knownLanguageNames, knownLanguageNames)&&const DeepCollectionEquality().equals(other.spells, spells)&&const DeepCollectionEquality().equals(other.spellSlots, spellSlots)&&(identical(other.currencyGp, currencyGp) || other.currencyGp == currencyGp)&&(identical(other.currencyPp, currencyPp) || other.currencyPp == currencyPp)&&(identical(other.currencyEp, currencyEp) || other.currencyEp == currencyEp)&&(identical(other.currencySp, currencySp) || other.currencySp == currencySp)&&(identical(other.currencyCp, currencyCp) || other.currencyCp == currencyCp)&&const DeepCollectionEquality().equals(other.inventory, inventory));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,portraitUrl,raceName,subraceName,raceCustomText,backgroundName,alignmentName,const DeepCollectionEquality().hash(classes),xp,currentHp,maxHp,temporaryHp,const DeepCollectionEquality().hash(abilityScores),const DeepCollectionEquality().hash(skills),const DeepCollectionEquality().hash(classFeatures),const DeepCollectionEquality().hash(toolProficiencyNames),const DeepCollectionEquality().hash(knownLanguageNames),const DeepCollectionEquality().hash(spells),const DeepCollectionEquality().hash(spellSlots),currencyGp,currencyPp,currencyEp,currencySp,currencyCp,const DeepCollectionEquality().hash(inventory)]);

@override
String toString() {
  return 'CharacterDetail(id: $id, name: $name, portraitUrl: $portraitUrl, raceName: $raceName, subraceName: $subraceName, raceCustomText: $raceCustomText, backgroundName: $backgroundName, alignmentName: $alignmentName, classes: $classes, xp: $xp, currentHp: $currentHp, maxHp: $maxHp, temporaryHp: $temporaryHp, abilityScores: $abilityScores, skills: $skills, classFeatures: $classFeatures, toolProficiencyNames: $toolProficiencyNames, knownLanguageNames: $knownLanguageNames, spells: $spells, spellSlots: $spellSlots, currencyGp: $currencyGp, currencyPp: $currencyPp, currencyEp: $currencyEp, currencySp: $currencySp, currencyCp: $currencyCp, inventory: $inventory)';
}


}

/// @nodoc
abstract mixin class $CharacterDetailCopyWith<$Res>  {
  factory $CharacterDetailCopyWith(CharacterDetail value, $Res Function(CharacterDetail) _then) = _$CharacterDetailCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? portraitUrl, String? raceName, String? subraceName, String? raceCustomText, String? backgroundName, String? alignmentName, List<CharacterDetailClassRow> classes, int xp, int currentHp, int maxHp, int temporaryHp, Map<String, int> abilityScores, List<CharacterSkillRow> skills, List<CharacterClassFeature> classFeatures, List<String> toolProficiencyNames, List<String> knownLanguageNames, List<CharacterSpellEntry> spells, List<CharacterSpellSlot> spellSlots, int currencyGp, int currencyPp, int currencyEp, int currencySp, int currencyCp, List<CharacterInventoryItem> inventory
});




}
/// @nodoc
class _$CharacterDetailCopyWithImpl<$Res>
    implements $CharacterDetailCopyWith<$Res> {
  _$CharacterDetailCopyWithImpl(this._self, this._then);

  final CharacterDetail _self;
  final $Res Function(CharacterDetail) _then;

/// Create a copy of CharacterDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? portraitUrl = freezed,Object? raceName = freezed,Object? subraceName = freezed,Object? raceCustomText = freezed,Object? backgroundName = freezed,Object? alignmentName = freezed,Object? classes = null,Object? xp = null,Object? currentHp = null,Object? maxHp = null,Object? temporaryHp = null,Object? abilityScores = null,Object? skills = null,Object? classFeatures = null,Object? toolProficiencyNames = null,Object? knownLanguageNames = null,Object? spells = null,Object? spellSlots = null,Object? currencyGp = null,Object? currencyPp = null,Object? currencyEp = null,Object? currencySp = null,Object? currencyCp = null,Object? inventory = null,}) {
  return _then(CharacterDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,portraitUrl: freezed == portraitUrl ? _self.portraitUrl : portraitUrl // ignore: cast_nullable_to_non_nullable
as String?,raceName: freezed == raceName ? _self.raceName : raceName // ignore: cast_nullable_to_non_nullable
as String?,subraceName: freezed == subraceName ? _self.subraceName : subraceName // ignore: cast_nullable_to_non_nullable
as String?,raceCustomText: freezed == raceCustomText ? _self.raceCustomText : raceCustomText // ignore: cast_nullable_to_non_nullable
as String?,backgroundName: freezed == backgroundName ? _self.backgroundName : backgroundName // ignore: cast_nullable_to_non_nullable
as String?,alignmentName: freezed == alignmentName ? _self.alignmentName : alignmentName // ignore: cast_nullable_to_non_nullable
as String?,classes: null == classes ? _self.classes : classes // ignore: cast_nullable_to_non_nullable
as List<CharacterDetailClassRow>,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,currentHp: null == currentHp ? _self.currentHp : currentHp // ignore: cast_nullable_to_non_nullable
as int,maxHp: null == maxHp ? _self.maxHp : maxHp // ignore: cast_nullable_to_non_nullable
as int,temporaryHp: null == temporaryHp ? _self.temporaryHp : temporaryHp // ignore: cast_nullable_to_non_nullable
as int,abilityScores: null == abilityScores ? _self.abilityScores : abilityScores // ignore: cast_nullable_to_non_nullable
as Map<String, int>,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<CharacterSkillRow>,classFeatures: null == classFeatures ? _self.classFeatures : classFeatures // ignore: cast_nullable_to_non_nullable
as List<CharacterClassFeature>,toolProficiencyNames: null == toolProficiencyNames ? _self.toolProficiencyNames : toolProficiencyNames // ignore: cast_nullable_to_non_nullable
as List<String>,knownLanguageNames: null == knownLanguageNames ? _self.knownLanguageNames : knownLanguageNames // ignore: cast_nullable_to_non_nullable
as List<String>,spells: null == spells ? _self.spells : spells // ignore: cast_nullable_to_non_nullable
as List<CharacterSpellEntry>,spellSlots: null == spellSlots ? _self.spellSlots : spellSlots // ignore: cast_nullable_to_non_nullable
as List<CharacterSpellSlot>,currencyGp: null == currencyGp ? _self.currencyGp : currencyGp // ignore: cast_nullable_to_non_nullable
as int,currencyPp: null == currencyPp ? _self.currencyPp : currencyPp // ignore: cast_nullable_to_non_nullable
as int,currencyEp: null == currencyEp ? _self.currencyEp : currencyEp // ignore: cast_nullable_to_non_nullable
as int,currencySp: null == currencySp ? _self.currencySp : currencySp // ignore: cast_nullable_to_non_nullable
as int,currencyCp: null == currencyCp ? _self.currencyCp : currencyCp // ignore: cast_nullable_to_non_nullable
as int,inventory: null == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as List<CharacterInventoryItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterDetail].
extension CharacterDetailPatterns on CharacterDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterDetail value)  $default,){
final _that = this;
switch (_that) {
case _CharacterDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? portraitUrl,  String? raceName,  String? subraceName,  String? raceCustomText,  String? backgroundName,  String? alignmentName,  List<CharacterDetailClassRow> classes,  int xp,  int currentHp,  int maxHp,  int temporaryHp,  Map<String, int> abilityScores,  List<CharacterSkillRow> skills,  List<CharacterClassFeature> classFeatures,  List<String> toolProficiencyNames,  List<String> knownLanguageNames,  List<CharacterSpellEntry> spells,  List<CharacterSpellSlot> spellSlots,  int currencyGp,  int currencyPp,  int currencyEp,  int currencySp,  int currencyCp,  List<CharacterInventoryItem> inventory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterDetail() when $default != null:
return $default(_that.id,_that.name,_that.portraitUrl,_that.raceName,_that.subraceName,_that.raceCustomText,_that.backgroundName,_that.alignmentName,_that.classes,_that.xp,_that.currentHp,_that.maxHp,_that.temporaryHp,_that.abilityScores,_that.skills,_that.classFeatures,_that.toolProficiencyNames,_that.knownLanguageNames,_that.spells,_that.spellSlots,_that.currencyGp,_that.currencyPp,_that.currencyEp,_that.currencySp,_that.currencyCp,_that.inventory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? portraitUrl,  String? raceName,  String? subraceName,  String? raceCustomText,  String? backgroundName,  String? alignmentName,  List<CharacterDetailClassRow> classes,  int xp,  int currentHp,  int maxHp,  int temporaryHp,  Map<String, int> abilityScores,  List<CharacterSkillRow> skills,  List<CharacterClassFeature> classFeatures,  List<String> toolProficiencyNames,  List<String> knownLanguageNames,  List<CharacterSpellEntry> spells,  List<CharacterSpellSlot> spellSlots,  int currencyGp,  int currencyPp,  int currencyEp,  int currencySp,  int currencyCp,  List<CharacterInventoryItem> inventory)  $default,) {final _that = this;
switch (_that) {
case _CharacterDetail():
return $default(_that.id,_that.name,_that.portraitUrl,_that.raceName,_that.subraceName,_that.raceCustomText,_that.backgroundName,_that.alignmentName,_that.classes,_that.xp,_that.currentHp,_that.maxHp,_that.temporaryHp,_that.abilityScores,_that.skills,_that.classFeatures,_that.toolProficiencyNames,_that.knownLanguageNames,_that.spells,_that.spellSlots,_that.currencyGp,_that.currencyPp,_that.currencyEp,_that.currencySp,_that.currencyCp,_that.inventory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? portraitUrl,  String? raceName,  String? subraceName,  String? raceCustomText,  String? backgroundName,  String? alignmentName,  List<CharacterDetailClassRow> classes,  int xp,  int currentHp,  int maxHp,  int temporaryHp,  Map<String, int> abilityScores,  List<CharacterSkillRow> skills,  List<CharacterClassFeature> classFeatures,  List<String> toolProficiencyNames,  List<String> knownLanguageNames,  List<CharacterSpellEntry> spells,  List<CharacterSpellSlot> spellSlots,  int currencyGp,  int currencyPp,  int currencyEp,  int currencySp,  int currencyCp,  List<CharacterInventoryItem> inventory)?  $default,) {final _that = this;
switch (_that) {
case _CharacterDetail() when $default != null:
return $default(_that.id,_that.name,_that.portraitUrl,_that.raceName,_that.subraceName,_that.raceCustomText,_that.backgroundName,_that.alignmentName,_that.classes,_that.xp,_that.currentHp,_that.maxHp,_that.temporaryHp,_that.abilityScores,_that.skills,_that.classFeatures,_that.toolProficiencyNames,_that.knownLanguageNames,_that.spells,_that.spellSlots,_that.currencyGp,_that.currencyPp,_that.currencyEp,_that.currencySp,_that.currencyCp,_that.inventory);case _:
  return null;

}
}

}

/// @nodoc


class _CharacterDetail extends CharacterDetail {
  const _CharacterDetail({required this.id, required this.name, this.portraitUrl, this.raceName, this.subraceName, this.raceCustomText, this.backgroundName, this.alignmentName, required  List<CharacterDetailClassRow> classes, required this.xp, required this.currentHp, required this.maxHp, required this.temporaryHp, required  Map<String, int> abilityScores,  List<CharacterSkillRow> skills = const <CharacterSkillRow>[],  List<CharacterClassFeature> classFeatures = const <CharacterClassFeature>[],  List<String> toolProficiencyNames = const <String>[],  List<String> knownLanguageNames = const <String>[],  List<CharacterSpellEntry> spells = const <CharacterSpellEntry>[],  List<CharacterSpellSlot> spellSlots = const <CharacterSpellSlot>[], this.currencyGp = 0, this.currencyPp = 0, this.currencyEp = 0, this.currencySp = 0, this.currencyCp = 0,  List<CharacterInventoryItem> inventory = const <CharacterInventoryItem>[]}): _classes = classes,_abilityScores = abilityScores,_skills = skills,_classFeatures = classFeatures,_toolProficiencyNames = toolProficiencyNames,_knownLanguageNames = knownLanguageNames,_spells = spells,_spellSlots = spellSlots,_inventory = inventory,super._();
  

@override final  String id;
@override final  String name;
/// URL publique du portrait (`characters.portrait_url`), `null` si le
/// joueur n'en a pas encore défini un.
@override final  String? portraitUrl;
/// Nom de race traduit, `null` si non résolu (race personnalisée ou
/// `race_id` nul).
@override final  String? raceName;
/// Nom de sous-race traduit, `null` si le personnage n'a pas de
/// sous-race.
@override final  String? subraceName;
/// Texte libre de race personnalisée (`characters.race_custom_text`),
/// `null` si le personnage a une race du catalogue.
@override final  String? raceCustomText;
/// Nom d'historique traduit, `null` si `background_id` est nul.
@override final  String? backgroundName;
/// Nom d'alignement traduit, `null` si `alignment_id` est nul.
@override final  String? alignmentName;
/// Toutes les lignes `character_classes` du personnage (multiclassage
/// inclus), dans l'ordre renvoyé par PostgREST.
 final  List<CharacterDetailClassRow> _classes;
/// Toutes les lignes `character_classes` du personnage (multiclassage
/// inclus), dans l'ordre renvoyé par PostgREST.
@override List<CharacterDetailClassRow> get classes {
  if (_classes is EqualUnmodifiableListView) return _classes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classes);
}

@override final  int xp;
@override final  int currentHp;
@override final  int maxHp;
@override final  int temporaryHp;
/// Scores finaux par caractéristique (`character_ability_scores`), clé
/// 'str'/'dex'/'con'/'int'/'wis'/'cha' — déjà le score final en base,
/// aucun bonus racial à recalculer ici (voir
/// `character_creation/domain/final_ability_scores_resolver.dart` pour
/// l'endroit où ce calcul a déjà eu lieu, à la création).
 final  Map<String, int> _abilityScores;
/// Scores finaux par caractéristique (`character_ability_scores`), clé
/// 'str'/'dex'/'con'/'int'/'wis'/'cha' — déjà le score final en base,
/// aucun bonus racial à recalculer ici (voir
/// `character_creation/domain/final_ability_scores_resolver.dart` pour
/// l'endroit où ce calcul a déjà eu lieu, à la création).
@override Map<String, int> get abilityScores {
  if (_abilityScores is EqualUnmodifiableMapView) return _abilityScores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_abilityScores);
}

/// Les 18 compétences résolues (nom, caractéristique, maîtrise) —
/// onglet "Compétences", carte "LES 18 COMPÉTENCES". Liste vide tant
/// qu'aucune compétence de référence n'a pu être résolue (ne devrait
/// arriver que pour un stack de contenu vide).
 final  List<CharacterSkillRow> _skills;
/// Les 18 compétences résolues (nom, caractéristique, maîtrise) —
/// onglet "Compétences", carte "LES 18 COMPÉTENCES". Liste vide tant
/// qu'aucune compétence de référence n'a pu être résolue (ne devrait
/// arriver que pour un stack de contenu vide).
@override@JsonKey() List<CharacterSkillRow> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

/// Aptitudes de classe déjà atteintes par le niveau actuel du
/// personnage — onglet "Compétences", carte "APTITUDES DE CLASSE". Voir
/// la documentation de classe de [CharacterClassFeature] pour la portée
/// (aptitudes de sous-classe jamais incluses à cette itération).
 final  List<CharacterClassFeature> _classFeatures;
/// Aptitudes de classe déjà atteintes par le niveau actuel du
/// personnage — onglet "Compétences", carte "APTITUDES DE CLASSE". Voir
/// la documentation de classe de [CharacterClassFeature] pour la portée
/// (aptitudes de sous-classe jamais incluses à cette itération).
@override@JsonKey() List<CharacterClassFeature> get classFeatures {
  if (_classFeatures is EqualUnmodifiableListView) return _classFeatures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classFeatures);
}

/// Noms des outils dont le personnage est compétent (texte libre inclus)
/// — onglet "Compétences", carte "MAÎTRISES D'OUTILS".
 final  List<String> _toolProficiencyNames;
/// Noms des outils dont le personnage est compétent (texte libre inclus)
/// — onglet "Compétences", carte "MAÎTRISES D'OUTILS".
@override@JsonKey() List<String> get toolProficiencyNames {
  if (_toolProficiencyNames is EqualUnmodifiableListView) return _toolProficiencyNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolProficiencyNames);
}

/// Noms des langues connues — onglet "Compétences", carte "LANGUES
/// CONNUES".
 final  List<String> _knownLanguageNames;
/// Noms des langues connues — onglet "Compétences", carte "LANGUES
/// CONNUES".
@override@JsonKey() List<String> get knownLanguageNames {
  if (_knownLanguageNames is EqualUnmodifiableListView) return _knownLanguageNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownLanguageNames);
}

/// Sorts connus/préparés du personnage — onglet "Compétences", section
/// "SORTS". Liste vide pour un personnage qui ne lance pas de sorts (pas
/// de distinction stockée entre "classe non lanceuse" et "lanceuse sans
/// sort encore choisi" : les deux cas affichent simplement une section
/// absente, voir `presentation/widgets/character_skills_tab_body.dart`).
 final  List<CharacterSpellEntry> _spells;
/// Sorts connus/préparés du personnage — onglet "Compétences", section
/// "SORTS". Liste vide pour un personnage qui ne lance pas de sorts (pas
/// de distinction stockée entre "classe non lanceuse" et "lanceuse sans
/// sort encore choisi" : les deux cas affichent simplement une section
/// absente, voir `presentation/widgets/character_skills_tab_body.dart`).
@override@JsonKey() List<CharacterSpellEntry> get spells {
  if (_spells is EqualUnmodifiableListView) return _spells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_spells);
}

/// Emplacements de sorts par niveau (1 à 9) — onglet "Compétences",
/// section "SORTS".
 final  List<CharacterSpellSlot> _spellSlots;
/// Emplacements de sorts par niveau (1 à 9) — onglet "Compétences",
/// section "SORTS".
@override@JsonKey() List<CharacterSpellSlot> get spellSlots {
  if (_spellSlots is EqualUnmodifiableListView) return _spellSlots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_spellSlots);
}

/// Monnaie du personnage (`characters.currency_gp/pp/ep/sp/cp`) — onglet
/// "Inventaire", rangée de stat boxes (voir
/// `domain/inventory_stat_boxes_resolver.dart`). `@Default(0)` comme les
/// autres champs ajoutés après la première version de ce modèle
/// (`skills`/`classFeatures`/...) : évite de devoir toucher tous les
/// sites de construction directe de [CharacterDetail] déjà existants
/// dans les tests (voir la même remarque sur ces champs ci-dessus).
@override@JsonKey() final  int currencyGp;
@override@JsonKey() final  int currencyPp;
@override@JsonKey() final  int currencyEp;
@override@JsonKey() final  int currencySp;
@override@JsonKey() final  int currencyCp;
/// Inventaire résolu du personnage — onglet "Inventaire", liste de
/// cartes. Comme [skills]/[classFeatures]/..., a besoin d'une requête
/// PostgREST séparée (résolution des noms d'objets du catalogue via
/// `translations`), voir `SupabaseCharacterRepository._fetchInventory`.
 final  List<CharacterInventoryItem> _inventory;
/// Inventaire résolu du personnage — onglet "Inventaire", liste de
/// cartes. Comme [skills]/[classFeatures]/..., a besoin d'une requête
/// PostgREST séparée (résolution des noms d'objets du catalogue via
/// `translations`), voir `SupabaseCharacterRepository._fetchInventory`.
@override@JsonKey() List<CharacterInventoryItem> get inventory {
  if (_inventory is EqualUnmodifiableListView) return _inventory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inventory);
}


/// Create a copy of CharacterDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterDetailCopyWith<_CharacterDetail> get copyWith => __$CharacterDetailCopyWithImpl<_CharacterDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.portraitUrl, portraitUrl) || other.portraitUrl == portraitUrl)&&(identical(other.raceName, raceName) || other.raceName == raceName)&&(identical(other.subraceName, subraceName) || other.subraceName == subraceName)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.backgroundName, backgroundName) || other.backgroundName == backgroundName)&&(identical(other.alignmentName, alignmentName) || other.alignmentName == alignmentName)&&const DeepCollectionEquality().equals(other._classes, _classes)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.currentHp, currentHp) || other.currentHp == currentHp)&&(identical(other.maxHp, maxHp) || other.maxHp == maxHp)&&(identical(other.temporaryHp, temporaryHp) || other.temporaryHp == temporaryHp)&&const DeepCollectionEquality().equals(other._abilityScores, _abilityScores)&&const DeepCollectionEquality().equals(other._skills, _skills)&&const DeepCollectionEquality().equals(other._classFeatures, _classFeatures)&&const DeepCollectionEquality().equals(other._toolProficiencyNames, _toolProficiencyNames)&&const DeepCollectionEquality().equals(other._knownLanguageNames, _knownLanguageNames)&&const DeepCollectionEquality().equals(other._spells, _spells)&&const DeepCollectionEquality().equals(other._spellSlots, _spellSlots)&&(identical(other.currencyGp, currencyGp) || other.currencyGp == currencyGp)&&(identical(other.currencyPp, currencyPp) || other.currencyPp == currencyPp)&&(identical(other.currencyEp, currencyEp) || other.currencyEp == currencyEp)&&(identical(other.currencySp, currencySp) || other.currencySp == currencySp)&&(identical(other.currencyCp, currencyCp) || other.currencyCp == currencyCp)&&const DeepCollectionEquality().equals(other._inventory, _inventory));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,portraitUrl,raceName,subraceName,raceCustomText,backgroundName,alignmentName,const DeepCollectionEquality().hash(_classes),xp,currentHp,maxHp,temporaryHp,const DeepCollectionEquality().hash(_abilityScores),const DeepCollectionEquality().hash(_skills),const DeepCollectionEquality().hash(_classFeatures),const DeepCollectionEquality().hash(_toolProficiencyNames),const DeepCollectionEquality().hash(_knownLanguageNames),const DeepCollectionEquality().hash(_spells),const DeepCollectionEquality().hash(_spellSlots),currencyGp,currencyPp,currencyEp,currencySp,currencyCp,const DeepCollectionEquality().hash(_inventory)]);

@override
String toString() {
  return 'CharacterDetail(id: $id, name: $name, portraitUrl: $portraitUrl, raceName: $raceName, subraceName: $subraceName, raceCustomText: $raceCustomText, backgroundName: $backgroundName, alignmentName: $alignmentName, classes: $classes, xp: $xp, currentHp: $currentHp, maxHp: $maxHp, temporaryHp: $temporaryHp, abilityScores: $abilityScores, skills: $skills, classFeatures: $classFeatures, toolProficiencyNames: $toolProficiencyNames, knownLanguageNames: $knownLanguageNames, spells: $spells, spellSlots: $spellSlots, currencyGp: $currencyGp, currencyPp: $currencyPp, currencyEp: $currencyEp, currencySp: $currencySp, currencyCp: $currencyCp, inventory: $inventory)';
}


}

/// @nodoc
abstract mixin class _$CharacterDetailCopyWith<$Res> implements $CharacterDetailCopyWith<$Res> {
  factory _$CharacterDetailCopyWith(_CharacterDetail value, $Res Function(_CharacterDetail) _then) = __$CharacterDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? portraitUrl, String? raceName, String? subraceName, String? raceCustomText, String? backgroundName, String? alignmentName, List<CharacterDetailClassRow> classes, int xp, int currentHp, int maxHp, int temporaryHp, Map<String, int> abilityScores, List<CharacterSkillRow> skills, List<CharacterClassFeature> classFeatures, List<String> toolProficiencyNames, List<String> knownLanguageNames, List<CharacterSpellEntry> spells, List<CharacterSpellSlot> spellSlots, int currencyGp, int currencyPp, int currencyEp, int currencySp, int currencyCp, List<CharacterInventoryItem> inventory
});




}
/// @nodoc
class __$CharacterDetailCopyWithImpl<$Res>
    implements _$CharacterDetailCopyWith<$Res> {
  __$CharacterDetailCopyWithImpl(this._self, this._then);

  final _CharacterDetail _self;
  final $Res Function(_CharacterDetail) _then;

/// Create a copy of CharacterDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? portraitUrl = freezed,Object? raceName = freezed,Object? subraceName = freezed,Object? raceCustomText = freezed,Object? backgroundName = freezed,Object? alignmentName = freezed,Object? classes = null,Object? xp = null,Object? currentHp = null,Object? maxHp = null,Object? temporaryHp = null,Object? abilityScores = null,Object? skills = null,Object? classFeatures = null,Object? toolProficiencyNames = null,Object? knownLanguageNames = null,Object? spells = null,Object? spellSlots = null,Object? currencyGp = null,Object? currencyPp = null,Object? currencyEp = null,Object? currencySp = null,Object? currencyCp = null,Object? inventory = null,}) {
  return _then(_CharacterDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,portraitUrl: freezed == portraitUrl ? _self.portraitUrl : portraitUrl // ignore: cast_nullable_to_non_nullable
as String?,raceName: freezed == raceName ? _self.raceName : raceName // ignore: cast_nullable_to_non_nullable
as String?,subraceName: freezed == subraceName ? _self.subraceName : subraceName // ignore: cast_nullable_to_non_nullable
as String?,raceCustomText: freezed == raceCustomText ? _self.raceCustomText : raceCustomText // ignore: cast_nullable_to_non_nullable
as String?,backgroundName: freezed == backgroundName ? _self.backgroundName : backgroundName // ignore: cast_nullable_to_non_nullable
as String?,alignmentName: freezed == alignmentName ? _self.alignmentName : alignmentName // ignore: cast_nullable_to_non_nullable
as String?,classes: null == classes ? _self._classes : classes // ignore: cast_nullable_to_non_nullable
as List<CharacterDetailClassRow>,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,currentHp: null == currentHp ? _self.currentHp : currentHp // ignore: cast_nullable_to_non_nullable
as int,maxHp: null == maxHp ? _self.maxHp : maxHp // ignore: cast_nullable_to_non_nullable
as int,temporaryHp: null == temporaryHp ? _self.temporaryHp : temporaryHp // ignore: cast_nullable_to_non_nullable
as int,abilityScores: null == abilityScores ? _self._abilityScores : abilityScores // ignore: cast_nullable_to_non_nullable
as Map<String, int>,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<CharacterSkillRow>,classFeatures: null == classFeatures ? _self._classFeatures : classFeatures // ignore: cast_nullable_to_non_nullable
as List<CharacterClassFeature>,toolProficiencyNames: null == toolProficiencyNames ? _self._toolProficiencyNames : toolProficiencyNames // ignore: cast_nullable_to_non_nullable
as List<String>,knownLanguageNames: null == knownLanguageNames ? _self._knownLanguageNames : knownLanguageNames // ignore: cast_nullable_to_non_nullable
as List<String>,spells: null == spells ? _self._spells : spells // ignore: cast_nullable_to_non_nullable
as List<CharacterSpellEntry>,spellSlots: null == spellSlots ? _self._spellSlots : spellSlots // ignore: cast_nullable_to_non_nullable
as List<CharacterSpellSlot>,currencyGp: null == currencyGp ? _self.currencyGp : currencyGp // ignore: cast_nullable_to_non_nullable
as int,currencyPp: null == currencyPp ? _self.currencyPp : currencyPp // ignore: cast_nullable_to_non_nullable
as int,currencyEp: null == currencyEp ? _self.currencyEp : currencyEp // ignore: cast_nullable_to_non_nullable
as int,currencySp: null == currencySp ? _self.currencySp : currencySp // ignore: cast_nullable_to_non_nullable
as int,currencyCp: null == currencyCp ? _self.currencyCp : currencyCp // ignore: cast_nullable_to_non_nullable
as int,inventory: null == inventory ? _self._inventory : inventory // ignore: cast_nullable_to_non_nullable
as List<CharacterInventoryItem>,
  ));
}


}

// dart format on
