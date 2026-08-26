// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_creation_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CharacterCreationDraft {

/// Race choisie à l'étape 1, `null` si race personnalisée ou pas encore
/// choisie.
 int? get raceId;/// Sous-race choisie à l'étape 1, `null` si la race n'a pas de sous-race
/// ou pas encore choisie.
 int? get subraceId;/// Texte libre de race personnalisée (étape 1), `null` si une race du
/// catalogue a été choisie à la place.
 String? get raceCustomText;/// Classe choisie à l'étape 2, `null` si pas encore choisie. Pas de
/// sous-classe ni de "classe personnalisée" à cette étape (décision du
/// chef de projet, voir `domain/class_catalog.dart`).
 int? get classId;/// Historique choisi à l'étape 3, `null` si pas encore choisi. Pas
/// d'historique personnalisé à cette étape (décision du chef de projet,
/// voir `domain/background_catalog.dart`).
 int? get backgroundId;/// Méthode de génération des scores de caractéristiques choisie à
/// l'étape 4, `null` si pas encore choisie (l'écran retombe alors sur
/// `AbilityScoreMethod.standardArray` par défaut — voir
/// `presentation/ability_score_step_screen.dart`).
 AbilityScoreMethod? get abilityScoreMethod;/// Scores de base choisis à l'étape 4, clés
/// 'str'/'dex'/'con'/'int'/'wis'/'cha' — **avant** application du bonus
/// racial (voir `domain/ability_score_modifier_calculator.dart` pour le
/// calcul du modificateur final affiché, qui l'ajoute). `null` si pas
/// encore choisis.
 Map<String, int>? get abilityScores;/// Compétences de classe choisies à l'étape 5 (noms affichés, ex.
/// "Arcanes", pas des ids `skills.id`). Liste vide tant qu'aucune n'est
/// choisie.
///
/// Décision assumée (voir `presentation/skills_and_tools_step_screen.dart`)
/// : le brouillon garde des **noms** plutôt que des ids `skills`/`tools`/
/// `languages` réels pour les trois champs de cette étape — la
/// résolution fine vers ces ids est repoussée à l'étape 9
/// "Récapitulatif" (pas encore implémentée), seule étape qui écrira
/// réellement des lignes en base. Ce choix évite de faire porter à cette
/// étape une jointure supplémentaire (nom -> id) dont le résultat
/// n'est utile qu'au moment d'écrire en base, à l'étape 9.
 List<String> get classSkillChoices;/// Outils/instruments de classe choisis à l'étape 5 (noms affichés),
/// vide si la classe n'a pas de choix interactif d'outils
/// (`ClassOption.toolChoice` `null`) ou si aucun n'est encore choisi.
/// Même décision noms-plutôt-qu'ids que [classSkillChoices].
 List<String> get classToolChoices;/// Langues d'historique choisies à l'étape 5 (noms affichés), vide si
/// l'historique n'offre pas de choix de langue
/// (`BackgroundOption.languageChoiceCount` `null`) ou si aucune n'est
/// encore choisie. Même décision noms-plutôt-qu'ids que
/// [classSkillChoices].
 List<String> get backgroundLanguageChoices;/// Sorts mineurs ("cantrips") choisis à l'étape 6 (noms affichés). Vide
/// tant qu'aucun n'est choisi, et reste vide en permanence pour une
/// classe non lanceuse de sorts ou une classe lanceuse sans quota de
/// cantrips (Paladin/Rôdeur, voir `domain/spellcasting_rules.dart`) —
/// cette étape est alors sautée entièrement (voir
/// `presentation/skills_and_tools_step_screen.dart`). Même décision
/// noms-plutôt-qu'ids que [classSkillChoices].
 List<String> get classCantripChoices;/// Sorts de niveau 1 choisis à l'étape 6 (noms affichés), même rationale
/// que [classCantripChoices].
 List<String> get classLevelOneSpellChoices;/// Onglet actif de l'étape 7 "Équipement de départ" au moment de
/// "Suivant", `null` tant que l'étape n'a pas encore été validée une
/// première fois. Détermine lequel de [purchasedEquipment] ou de
/// l'équipement de l'historique choisi (recalculé à l'étape 9
/// "Récapitulatif" à partir de `backgroundId`, jamais dupliqué ici) est
/// retenu — voir `domain/equipment_choice_tab.dart` pour le rationale du
/// choix mutuellement exclusif.
 EquipmentChoiceTab? get equipmentChoiceTab;/// Panier de l'onglet "Acheter" de l'étape 7 (`{nom d'objet: quantité}`),
/// même décision noms-plutôt-qu'ids que [classSkillChoices]. Conservé
/// même si [equipmentChoiceTab] vaut `EquipmentChoiceTab.background` au
/// moment de "Suivant" (panier préservé au changement d'onglet, voir
/// `presentation/equipment_step_screen.dart`) : c'est
/// [equipmentChoiceTab], pas la présence de ce champ, qui détermine ce
/// qui est effectivement retenu à l'étape 9.
 Map<String, int> get purchasedEquipment;/// Les 9 champs texte libres de l'étape 8 "Apparence, histoire et
/// portrait" (`presentation/appearance_and_backstory_step_screen.dart`),
/// tous optionnels — `null` tant que le champ n'a jamais été renseigné.
/// Ordre canonique du XML aidedd.org / des colonnes `characters.*` (voir
/// le commentaire de classe de `AppearanceAndBackstoryStepScreen`), pas
/// l'ordre partiel visible sur la maquette (extrait tronqué). Aucune
/// résolution supplémentaire nécessaire à l'étape 9 contrairement aux
/// autres champs du brouillon : ce sont déjà les valeurs texte finales
/// destinées aux colonnes `characters.appearance_text`/`traits_text`/...
 String? get appearanceText;/// Voir [appearanceText] — `characters.traits_text`.
 String? get traitsText;/// Voir [appearanceText] — `characters.ideals_text`.
 String? get idealsText;/// Voir [appearanceText] — `characters.bonds_text`.
 String? get bondsText;/// Voir [appearanceText] — `characters.flaws_text`.
 String? get flawsText;/// Voir [appearanceText] — `characters.backstory_text`.
 String? get backstoryText;/// Voir [appearanceText] — `characters.allies_text`.
 String? get alliesText;/// Voir [appearanceText] — `characters.features_text`.
 String? get featuresText;/// Voir [appearanceText] — `characters.treasure_text`.
 String? get treasureText;
/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterCreationDraftCopyWith<CharacterCreationDraft> get copyWith => _$CharacterCreationDraftCopyWithImpl<CharacterCreationDraft>(this as CharacterCreationDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterCreationDraft&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.subraceId, subraceId) || other.subraceId == subraceId)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.backgroundId, backgroundId) || other.backgroundId == backgroundId)&&(identical(other.abilityScoreMethod, abilityScoreMethod) || other.abilityScoreMethod == abilityScoreMethod)&&const DeepCollectionEquality().equals(other.abilityScores, abilityScores)&&const DeepCollectionEquality().equals(other.classSkillChoices, classSkillChoices)&&const DeepCollectionEquality().equals(other.classToolChoices, classToolChoices)&&const DeepCollectionEquality().equals(other.backgroundLanguageChoices, backgroundLanguageChoices)&&const DeepCollectionEquality().equals(other.classCantripChoices, classCantripChoices)&&const DeepCollectionEquality().equals(other.classLevelOneSpellChoices, classLevelOneSpellChoices)&&(identical(other.equipmentChoiceTab, equipmentChoiceTab) || other.equipmentChoiceTab == equipmentChoiceTab)&&const DeepCollectionEquality().equals(other.purchasedEquipment, purchasedEquipment)&&(identical(other.appearanceText, appearanceText) || other.appearanceText == appearanceText)&&(identical(other.traitsText, traitsText) || other.traitsText == traitsText)&&(identical(other.idealsText, idealsText) || other.idealsText == idealsText)&&(identical(other.bondsText, bondsText) || other.bondsText == bondsText)&&(identical(other.flawsText, flawsText) || other.flawsText == flawsText)&&(identical(other.backstoryText, backstoryText) || other.backstoryText == backstoryText)&&(identical(other.alliesText, alliesText) || other.alliesText == alliesText)&&(identical(other.featuresText, featuresText) || other.featuresText == featuresText)&&(identical(other.treasureText, treasureText) || other.treasureText == treasureText));
}


@override
int get hashCode => Object.hashAll([runtimeType,raceId,subraceId,raceCustomText,classId,backgroundId,abilityScoreMethod,const DeepCollectionEquality().hash(abilityScores),const DeepCollectionEquality().hash(classSkillChoices),const DeepCollectionEquality().hash(classToolChoices),const DeepCollectionEquality().hash(backgroundLanguageChoices),const DeepCollectionEquality().hash(classCantripChoices),const DeepCollectionEquality().hash(classLevelOneSpellChoices),equipmentChoiceTab,const DeepCollectionEquality().hash(purchasedEquipment),appearanceText,traitsText,idealsText,bondsText,flawsText,backstoryText,alliesText,featuresText,treasureText]);

@override
String toString() {
  return 'CharacterCreationDraft(raceId: $raceId, subraceId: $subraceId, raceCustomText: $raceCustomText, classId: $classId, backgroundId: $backgroundId, abilityScoreMethod: $abilityScoreMethod, abilityScores: $abilityScores, classSkillChoices: $classSkillChoices, classToolChoices: $classToolChoices, backgroundLanguageChoices: $backgroundLanguageChoices, classCantripChoices: $classCantripChoices, classLevelOneSpellChoices: $classLevelOneSpellChoices, equipmentChoiceTab: $equipmentChoiceTab, purchasedEquipment: $purchasedEquipment, appearanceText: $appearanceText, traitsText: $traitsText, idealsText: $idealsText, bondsText: $bondsText, flawsText: $flawsText, backstoryText: $backstoryText, alliesText: $alliesText, featuresText: $featuresText, treasureText: $treasureText)';
}


}

/// @nodoc
abstract mixin class $CharacterCreationDraftCopyWith<$Res>  {
  factory $CharacterCreationDraftCopyWith(CharacterCreationDraft value, $Res Function(CharacterCreationDraft) _then) = _$CharacterCreationDraftCopyWithImpl;
@useResult
$Res call({
 int? raceId, int? subraceId, String? raceCustomText, int? classId, int? backgroundId, AbilityScoreMethod? abilityScoreMethod, Map<String, int>? abilityScores, List<String> classSkillChoices, List<String> classToolChoices, List<String> backgroundLanguageChoices, List<String> classCantripChoices, List<String> classLevelOneSpellChoices, EquipmentChoiceTab? equipmentChoiceTab, Map<String, int> purchasedEquipment, String? appearanceText, String? traitsText, String? idealsText, String? bondsText, String? flawsText, String? backstoryText, String? alliesText, String? featuresText, String? treasureText
});




}
/// @nodoc
class _$CharacterCreationDraftCopyWithImpl<$Res>
    implements $CharacterCreationDraftCopyWith<$Res> {
  _$CharacterCreationDraftCopyWithImpl(this._self, this._then);

  final CharacterCreationDraft _self;
  final $Res Function(CharacterCreationDraft) _then;

/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? raceId = freezed,Object? subraceId = freezed,Object? raceCustomText = freezed,Object? classId = freezed,Object? backgroundId = freezed,Object? abilityScoreMethod = freezed,Object? abilityScores = freezed,Object? classSkillChoices = null,Object? classToolChoices = null,Object? backgroundLanguageChoices = null,Object? classCantripChoices = null,Object? classLevelOneSpellChoices = null,Object? equipmentChoiceTab = freezed,Object? purchasedEquipment = null,Object? appearanceText = freezed,Object? traitsText = freezed,Object? idealsText = freezed,Object? bondsText = freezed,Object? flawsText = freezed,Object? backstoryText = freezed,Object? alliesText = freezed,Object? featuresText = freezed,Object? treasureText = freezed,}) {
  return _then(CharacterCreationDraft(
raceId: freezed == raceId ? _self.raceId : raceId // ignore: cast_nullable_to_non_nullable
as int?,subraceId: freezed == subraceId ? _self.subraceId : subraceId // ignore: cast_nullable_to_non_nullable
as int?,raceCustomText: freezed == raceCustomText ? _self.raceCustomText : raceCustomText // ignore: cast_nullable_to_non_nullable
as String?,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as int?,backgroundId: freezed == backgroundId ? _self.backgroundId : backgroundId // ignore: cast_nullable_to_non_nullable
as int?,abilityScoreMethod: freezed == abilityScoreMethod ? _self.abilityScoreMethod : abilityScoreMethod // ignore: cast_nullable_to_non_nullable
as AbilityScoreMethod?,abilityScores: freezed == abilityScores ? _self.abilityScores : abilityScores // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,classSkillChoices: null == classSkillChoices ? _self.classSkillChoices : classSkillChoices // ignore: cast_nullable_to_non_nullable
as List<String>,classToolChoices: null == classToolChoices ? _self.classToolChoices : classToolChoices // ignore: cast_nullable_to_non_nullable
as List<String>,backgroundLanguageChoices: null == backgroundLanguageChoices ? _self.backgroundLanguageChoices : backgroundLanguageChoices // ignore: cast_nullable_to_non_nullable
as List<String>,classCantripChoices: null == classCantripChoices ? _self.classCantripChoices : classCantripChoices // ignore: cast_nullable_to_non_nullable
as List<String>,classLevelOneSpellChoices: null == classLevelOneSpellChoices ? _self.classLevelOneSpellChoices : classLevelOneSpellChoices // ignore: cast_nullable_to_non_nullable
as List<String>,equipmentChoiceTab: freezed == equipmentChoiceTab ? _self.equipmentChoiceTab : equipmentChoiceTab // ignore: cast_nullable_to_non_nullable
as EquipmentChoiceTab?,purchasedEquipment: null == purchasedEquipment ? _self.purchasedEquipment : purchasedEquipment // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appearanceText: freezed == appearanceText ? _self.appearanceText : appearanceText // ignore: cast_nullable_to_non_nullable
as String?,traitsText: freezed == traitsText ? _self.traitsText : traitsText // ignore: cast_nullable_to_non_nullable
as String?,idealsText: freezed == idealsText ? _self.idealsText : idealsText // ignore: cast_nullable_to_non_nullable
as String?,bondsText: freezed == bondsText ? _self.bondsText : bondsText // ignore: cast_nullable_to_non_nullable
as String?,flawsText: freezed == flawsText ? _self.flawsText : flawsText // ignore: cast_nullable_to_non_nullable
as String?,backstoryText: freezed == backstoryText ? _self.backstoryText : backstoryText // ignore: cast_nullable_to_non_nullable
as String?,alliesText: freezed == alliesText ? _self.alliesText : alliesText // ignore: cast_nullable_to_non_nullable
as String?,featuresText: freezed == featuresText ? _self.featuresText : featuresText // ignore: cast_nullable_to_non_nullable
as String?,treasureText: freezed == treasureText ? _self.treasureText : treasureText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterCreationDraft].
extension CharacterCreationDraftPatterns on CharacterCreationDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterCreationDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterCreationDraft value)  $default,){
final _that = this;
switch (_that) {
case _CharacterCreationDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterCreationDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId,  int? backgroundId,  AbilityScoreMethod? abilityScoreMethod,  Map<String, int>? abilityScores,  List<String> classSkillChoices,  List<String> classToolChoices,  List<String> backgroundLanguageChoices,  List<String> classCantripChoices,  List<String> classLevelOneSpellChoices,  EquipmentChoiceTab? equipmentChoiceTab,  Map<String, int> purchasedEquipment,  String? appearanceText,  String? traitsText,  String? idealsText,  String? bondsText,  String? flawsText,  String? backstoryText,  String? alliesText,  String? featuresText,  String? treasureText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId,_that.backgroundId,_that.abilityScoreMethod,_that.abilityScores,_that.classSkillChoices,_that.classToolChoices,_that.backgroundLanguageChoices,_that.classCantripChoices,_that.classLevelOneSpellChoices,_that.equipmentChoiceTab,_that.purchasedEquipment,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId,  int? backgroundId,  AbilityScoreMethod? abilityScoreMethod,  Map<String, int>? abilityScores,  List<String> classSkillChoices,  List<String> classToolChoices,  List<String> backgroundLanguageChoices,  List<String> classCantripChoices,  List<String> classLevelOneSpellChoices,  EquipmentChoiceTab? equipmentChoiceTab,  Map<String, int> purchasedEquipment,  String? appearanceText,  String? traitsText,  String? idealsText,  String? bondsText,  String? flawsText,  String? backstoryText,  String? alliesText,  String? featuresText,  String? treasureText)  $default,) {final _that = this;
switch (_that) {
case _CharacterCreationDraft():
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId,_that.backgroundId,_that.abilityScoreMethod,_that.abilityScores,_that.classSkillChoices,_that.classToolChoices,_that.backgroundLanguageChoices,_that.classCantripChoices,_that.classLevelOneSpellChoices,_that.equipmentChoiceTab,_that.purchasedEquipment,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId,  int? backgroundId,  AbilityScoreMethod? abilityScoreMethod,  Map<String, int>? abilityScores,  List<String> classSkillChoices,  List<String> classToolChoices,  List<String> backgroundLanguageChoices,  List<String> classCantripChoices,  List<String> classLevelOneSpellChoices,  EquipmentChoiceTab? equipmentChoiceTab,  Map<String, int> purchasedEquipment,  String? appearanceText,  String? traitsText,  String? idealsText,  String? bondsText,  String? flawsText,  String? backstoryText,  String? alliesText,  String? featuresText,  String? treasureText)?  $default,) {final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId,_that.backgroundId,_that.abilityScoreMethod,_that.abilityScores,_that.classSkillChoices,_that.classToolChoices,_that.backgroundLanguageChoices,_that.classCantripChoices,_that.classLevelOneSpellChoices,_that.equipmentChoiceTab,_that.purchasedEquipment,_that.appearanceText,_that.traitsText,_that.idealsText,_that.bondsText,_that.flawsText,_that.backstoryText,_that.alliesText,_that.featuresText,_that.treasureText);case _:
  return null;

}
}

}

/// @nodoc


class _CharacterCreationDraft implements CharacterCreationDraft {
  const _CharacterCreationDraft({this.raceId, this.subraceId, this.raceCustomText, this.classId, this.backgroundId, this.abilityScoreMethod,  Map<String, int>? abilityScores,  List<String> classSkillChoices = const <String>[],  List<String> classToolChoices = const <String>[],  List<String> backgroundLanguageChoices = const <String>[],  List<String> classCantripChoices = const <String>[],  List<String> classLevelOneSpellChoices = const <String>[], this.equipmentChoiceTab,  Map<String, int> purchasedEquipment = const <String, int>{}, this.appearanceText, this.traitsText, this.idealsText, this.bondsText, this.flawsText, this.backstoryText, this.alliesText, this.featuresText, this.treasureText}): _abilityScores = abilityScores,_classSkillChoices = classSkillChoices,_classToolChoices = classToolChoices,_backgroundLanguageChoices = backgroundLanguageChoices,_classCantripChoices = classCantripChoices,_classLevelOneSpellChoices = classLevelOneSpellChoices,_purchasedEquipment = purchasedEquipment;
  

/// Race choisie à l'étape 1, `null` si race personnalisée ou pas encore
/// choisie.
@override final  int? raceId;
/// Sous-race choisie à l'étape 1, `null` si la race n'a pas de sous-race
/// ou pas encore choisie.
@override final  int? subraceId;
/// Texte libre de race personnalisée (étape 1), `null` si une race du
/// catalogue a été choisie à la place.
@override final  String? raceCustomText;
/// Classe choisie à l'étape 2, `null` si pas encore choisie. Pas de
/// sous-classe ni de "classe personnalisée" à cette étape (décision du
/// chef de projet, voir `domain/class_catalog.dart`).
@override final  int? classId;
/// Historique choisi à l'étape 3, `null` si pas encore choisi. Pas
/// d'historique personnalisé à cette étape (décision du chef de projet,
/// voir `domain/background_catalog.dart`).
@override final  int? backgroundId;
/// Méthode de génération des scores de caractéristiques choisie à
/// l'étape 4, `null` si pas encore choisie (l'écran retombe alors sur
/// `AbilityScoreMethod.standardArray` par défaut — voir
/// `presentation/ability_score_step_screen.dart`).
@override final  AbilityScoreMethod? abilityScoreMethod;
/// Scores de base choisis à l'étape 4, clés
/// 'str'/'dex'/'con'/'int'/'wis'/'cha' — **avant** application du bonus
/// racial (voir `domain/ability_score_modifier_calculator.dart` pour le
/// calcul du modificateur final affiché, qui l'ajoute). `null` si pas
/// encore choisis.
 final  Map<String, int>? _abilityScores;
/// Scores de base choisis à l'étape 4, clés
/// 'str'/'dex'/'con'/'int'/'wis'/'cha' — **avant** application du bonus
/// racial (voir `domain/ability_score_modifier_calculator.dart` pour le
/// calcul du modificateur final affiché, qui l'ajoute). `null` si pas
/// encore choisis.
@override Map<String, int>? get abilityScores {
  final value = _abilityScores;
  if (value == null) return null;
  if (_abilityScores is EqualUnmodifiableMapView) return _abilityScores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Compétences de classe choisies à l'étape 5 (noms affichés, ex.
/// "Arcanes", pas des ids `skills.id`). Liste vide tant qu'aucune n'est
/// choisie.
///
/// Décision assumée (voir `presentation/skills_and_tools_step_screen.dart`)
/// : le brouillon garde des **noms** plutôt que des ids `skills`/`tools`/
/// `languages` réels pour les trois champs de cette étape — la
/// résolution fine vers ces ids est repoussée à l'étape 9
/// "Récapitulatif" (pas encore implémentée), seule étape qui écrira
/// réellement des lignes en base. Ce choix évite de faire porter à cette
/// étape une jointure supplémentaire (nom -> id) dont le résultat
/// n'est utile qu'au moment d'écrire en base, à l'étape 9.
 final  List<String> _classSkillChoices;
/// Compétences de classe choisies à l'étape 5 (noms affichés, ex.
/// "Arcanes", pas des ids `skills.id`). Liste vide tant qu'aucune n'est
/// choisie.
///
/// Décision assumée (voir `presentation/skills_and_tools_step_screen.dart`)
/// : le brouillon garde des **noms** plutôt que des ids `skills`/`tools`/
/// `languages` réels pour les trois champs de cette étape — la
/// résolution fine vers ces ids est repoussée à l'étape 9
/// "Récapitulatif" (pas encore implémentée), seule étape qui écrira
/// réellement des lignes en base. Ce choix évite de faire porter à cette
/// étape une jointure supplémentaire (nom -> id) dont le résultat
/// n'est utile qu'au moment d'écrire en base, à l'étape 9.
@override@JsonKey() List<String> get classSkillChoices {
  if (_classSkillChoices is EqualUnmodifiableListView) return _classSkillChoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classSkillChoices);
}

/// Outils/instruments de classe choisis à l'étape 5 (noms affichés),
/// vide si la classe n'a pas de choix interactif d'outils
/// (`ClassOption.toolChoice` `null`) ou si aucun n'est encore choisi.
/// Même décision noms-plutôt-qu'ids que [classSkillChoices].
 final  List<String> _classToolChoices;
/// Outils/instruments de classe choisis à l'étape 5 (noms affichés),
/// vide si la classe n'a pas de choix interactif d'outils
/// (`ClassOption.toolChoice` `null`) ou si aucun n'est encore choisi.
/// Même décision noms-plutôt-qu'ids que [classSkillChoices].
@override@JsonKey() List<String> get classToolChoices {
  if (_classToolChoices is EqualUnmodifiableListView) return _classToolChoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classToolChoices);
}

/// Langues d'historique choisies à l'étape 5 (noms affichés), vide si
/// l'historique n'offre pas de choix de langue
/// (`BackgroundOption.languageChoiceCount` `null`) ou si aucune n'est
/// encore choisie. Même décision noms-plutôt-qu'ids que
/// [classSkillChoices].
 final  List<String> _backgroundLanguageChoices;
/// Langues d'historique choisies à l'étape 5 (noms affichés), vide si
/// l'historique n'offre pas de choix de langue
/// (`BackgroundOption.languageChoiceCount` `null`) ou si aucune n'est
/// encore choisie. Même décision noms-plutôt-qu'ids que
/// [classSkillChoices].
@override@JsonKey() List<String> get backgroundLanguageChoices {
  if (_backgroundLanguageChoices is EqualUnmodifiableListView) return _backgroundLanguageChoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backgroundLanguageChoices);
}

/// Sorts mineurs ("cantrips") choisis à l'étape 6 (noms affichés). Vide
/// tant qu'aucun n'est choisi, et reste vide en permanence pour une
/// classe non lanceuse de sorts ou une classe lanceuse sans quota de
/// cantrips (Paladin/Rôdeur, voir `domain/spellcasting_rules.dart`) —
/// cette étape est alors sautée entièrement (voir
/// `presentation/skills_and_tools_step_screen.dart`). Même décision
/// noms-plutôt-qu'ids que [classSkillChoices].
 final  List<String> _classCantripChoices;
/// Sorts mineurs ("cantrips") choisis à l'étape 6 (noms affichés). Vide
/// tant qu'aucun n'est choisi, et reste vide en permanence pour une
/// classe non lanceuse de sorts ou une classe lanceuse sans quota de
/// cantrips (Paladin/Rôdeur, voir `domain/spellcasting_rules.dart`) —
/// cette étape est alors sautée entièrement (voir
/// `presentation/skills_and_tools_step_screen.dart`). Même décision
/// noms-plutôt-qu'ids que [classSkillChoices].
@override@JsonKey() List<String> get classCantripChoices {
  if (_classCantripChoices is EqualUnmodifiableListView) return _classCantripChoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classCantripChoices);
}

/// Sorts de niveau 1 choisis à l'étape 6 (noms affichés), même rationale
/// que [classCantripChoices].
 final  List<String> _classLevelOneSpellChoices;
/// Sorts de niveau 1 choisis à l'étape 6 (noms affichés), même rationale
/// que [classCantripChoices].
@override@JsonKey() List<String> get classLevelOneSpellChoices {
  if (_classLevelOneSpellChoices is EqualUnmodifiableListView) return _classLevelOneSpellChoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classLevelOneSpellChoices);
}

/// Onglet actif de l'étape 7 "Équipement de départ" au moment de
/// "Suivant", `null` tant que l'étape n'a pas encore été validée une
/// première fois. Détermine lequel de [purchasedEquipment] ou de
/// l'équipement de l'historique choisi (recalculé à l'étape 9
/// "Récapitulatif" à partir de `backgroundId`, jamais dupliqué ici) est
/// retenu — voir `domain/equipment_choice_tab.dart` pour le rationale du
/// choix mutuellement exclusif.
@override final  EquipmentChoiceTab? equipmentChoiceTab;
/// Panier de l'onglet "Acheter" de l'étape 7 (`{nom d'objet: quantité}`),
/// même décision noms-plutôt-qu'ids que [classSkillChoices]. Conservé
/// même si [equipmentChoiceTab] vaut `EquipmentChoiceTab.background` au
/// moment de "Suivant" (panier préservé au changement d'onglet, voir
/// `presentation/equipment_step_screen.dart`) : c'est
/// [equipmentChoiceTab], pas la présence de ce champ, qui détermine ce
/// qui est effectivement retenu à l'étape 9.
 final  Map<String, int> _purchasedEquipment;
/// Panier de l'onglet "Acheter" de l'étape 7 (`{nom d'objet: quantité}`),
/// même décision noms-plutôt-qu'ids que [classSkillChoices]. Conservé
/// même si [equipmentChoiceTab] vaut `EquipmentChoiceTab.background` au
/// moment de "Suivant" (panier préservé au changement d'onglet, voir
/// `presentation/equipment_step_screen.dart`) : c'est
/// [equipmentChoiceTab], pas la présence de ce champ, qui détermine ce
/// qui est effectivement retenu à l'étape 9.
@override@JsonKey() Map<String, int> get purchasedEquipment {
  if (_purchasedEquipment is EqualUnmodifiableMapView) return _purchasedEquipment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_purchasedEquipment);
}

/// Les 9 champs texte libres de l'étape 8 "Apparence, histoire et
/// portrait" (`presentation/appearance_and_backstory_step_screen.dart`),
/// tous optionnels — `null` tant que le champ n'a jamais été renseigné.
/// Ordre canonique du XML aidedd.org / des colonnes `characters.*` (voir
/// le commentaire de classe de `AppearanceAndBackstoryStepScreen`), pas
/// l'ordre partiel visible sur la maquette (extrait tronqué). Aucune
/// résolution supplémentaire nécessaire à l'étape 9 contrairement aux
/// autres champs du brouillon : ce sont déjà les valeurs texte finales
/// destinées aux colonnes `characters.appearance_text`/`traits_text`/...
@override final  String? appearanceText;
/// Voir [appearanceText] — `characters.traits_text`.
@override final  String? traitsText;
/// Voir [appearanceText] — `characters.ideals_text`.
@override final  String? idealsText;
/// Voir [appearanceText] — `characters.bonds_text`.
@override final  String? bondsText;
/// Voir [appearanceText] — `characters.flaws_text`.
@override final  String? flawsText;
/// Voir [appearanceText] — `characters.backstory_text`.
@override final  String? backstoryText;
/// Voir [appearanceText] — `characters.allies_text`.
@override final  String? alliesText;
/// Voir [appearanceText] — `characters.features_text`.
@override final  String? featuresText;
/// Voir [appearanceText] — `characters.treasure_text`.
@override final  String? treasureText;

/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterCreationDraftCopyWith<_CharacterCreationDraft> get copyWith => __$CharacterCreationDraftCopyWithImpl<_CharacterCreationDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterCreationDraft&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.subraceId, subraceId) || other.subraceId == subraceId)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.backgroundId, backgroundId) || other.backgroundId == backgroundId)&&(identical(other.abilityScoreMethod, abilityScoreMethod) || other.abilityScoreMethod == abilityScoreMethod)&&const DeepCollectionEquality().equals(other._abilityScores, _abilityScores)&&const DeepCollectionEquality().equals(other._classSkillChoices, _classSkillChoices)&&const DeepCollectionEquality().equals(other._classToolChoices, _classToolChoices)&&const DeepCollectionEquality().equals(other._backgroundLanguageChoices, _backgroundLanguageChoices)&&const DeepCollectionEquality().equals(other._classCantripChoices, _classCantripChoices)&&const DeepCollectionEquality().equals(other._classLevelOneSpellChoices, _classLevelOneSpellChoices)&&(identical(other.equipmentChoiceTab, equipmentChoiceTab) || other.equipmentChoiceTab == equipmentChoiceTab)&&const DeepCollectionEquality().equals(other._purchasedEquipment, _purchasedEquipment)&&(identical(other.appearanceText, appearanceText) || other.appearanceText == appearanceText)&&(identical(other.traitsText, traitsText) || other.traitsText == traitsText)&&(identical(other.idealsText, idealsText) || other.idealsText == idealsText)&&(identical(other.bondsText, bondsText) || other.bondsText == bondsText)&&(identical(other.flawsText, flawsText) || other.flawsText == flawsText)&&(identical(other.backstoryText, backstoryText) || other.backstoryText == backstoryText)&&(identical(other.alliesText, alliesText) || other.alliesText == alliesText)&&(identical(other.featuresText, featuresText) || other.featuresText == featuresText)&&(identical(other.treasureText, treasureText) || other.treasureText == treasureText));
}


@override
int get hashCode => Object.hashAll([runtimeType,raceId,subraceId,raceCustomText,classId,backgroundId,abilityScoreMethod,const DeepCollectionEquality().hash(_abilityScores),const DeepCollectionEquality().hash(_classSkillChoices),const DeepCollectionEquality().hash(_classToolChoices),const DeepCollectionEquality().hash(_backgroundLanguageChoices),const DeepCollectionEquality().hash(_classCantripChoices),const DeepCollectionEquality().hash(_classLevelOneSpellChoices),equipmentChoiceTab,const DeepCollectionEquality().hash(_purchasedEquipment),appearanceText,traitsText,idealsText,bondsText,flawsText,backstoryText,alliesText,featuresText,treasureText]);

@override
String toString() {
  return 'CharacterCreationDraft(raceId: $raceId, subraceId: $subraceId, raceCustomText: $raceCustomText, classId: $classId, backgroundId: $backgroundId, abilityScoreMethod: $abilityScoreMethod, abilityScores: $abilityScores, classSkillChoices: $classSkillChoices, classToolChoices: $classToolChoices, backgroundLanguageChoices: $backgroundLanguageChoices, classCantripChoices: $classCantripChoices, classLevelOneSpellChoices: $classLevelOneSpellChoices, equipmentChoiceTab: $equipmentChoiceTab, purchasedEquipment: $purchasedEquipment, appearanceText: $appearanceText, traitsText: $traitsText, idealsText: $idealsText, bondsText: $bondsText, flawsText: $flawsText, backstoryText: $backstoryText, alliesText: $alliesText, featuresText: $featuresText, treasureText: $treasureText)';
}


}

/// @nodoc
abstract mixin class _$CharacterCreationDraftCopyWith<$Res> implements $CharacterCreationDraftCopyWith<$Res> {
  factory _$CharacterCreationDraftCopyWith(_CharacterCreationDraft value, $Res Function(_CharacterCreationDraft) _then) = __$CharacterCreationDraftCopyWithImpl;
@override @useResult
$Res call({
 int? raceId, int? subraceId, String? raceCustomText, int? classId, int? backgroundId, AbilityScoreMethod? abilityScoreMethod, Map<String, int>? abilityScores, List<String> classSkillChoices, List<String> classToolChoices, List<String> backgroundLanguageChoices, List<String> classCantripChoices, List<String> classLevelOneSpellChoices, EquipmentChoiceTab? equipmentChoiceTab, Map<String, int> purchasedEquipment, String? appearanceText, String? traitsText, String? idealsText, String? bondsText, String? flawsText, String? backstoryText, String? alliesText, String? featuresText, String? treasureText
});




}
/// @nodoc
class __$CharacterCreationDraftCopyWithImpl<$Res>
    implements _$CharacterCreationDraftCopyWith<$Res> {
  __$CharacterCreationDraftCopyWithImpl(this._self, this._then);

  final _CharacterCreationDraft _self;
  final $Res Function(_CharacterCreationDraft) _then;

/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? raceId = freezed,Object? subraceId = freezed,Object? raceCustomText = freezed,Object? classId = freezed,Object? backgroundId = freezed,Object? abilityScoreMethod = freezed,Object? abilityScores = freezed,Object? classSkillChoices = null,Object? classToolChoices = null,Object? backgroundLanguageChoices = null,Object? classCantripChoices = null,Object? classLevelOneSpellChoices = null,Object? equipmentChoiceTab = freezed,Object? purchasedEquipment = null,Object? appearanceText = freezed,Object? traitsText = freezed,Object? idealsText = freezed,Object? bondsText = freezed,Object? flawsText = freezed,Object? backstoryText = freezed,Object? alliesText = freezed,Object? featuresText = freezed,Object? treasureText = freezed,}) {
  return _then(_CharacterCreationDraft(
raceId: freezed == raceId ? _self.raceId : raceId // ignore: cast_nullable_to_non_nullable
as int?,subraceId: freezed == subraceId ? _self.subraceId : subraceId // ignore: cast_nullable_to_non_nullable
as int?,raceCustomText: freezed == raceCustomText ? _self.raceCustomText : raceCustomText // ignore: cast_nullable_to_non_nullable
as String?,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as int?,backgroundId: freezed == backgroundId ? _self.backgroundId : backgroundId // ignore: cast_nullable_to_non_nullable
as int?,abilityScoreMethod: freezed == abilityScoreMethod ? _self.abilityScoreMethod : abilityScoreMethod // ignore: cast_nullable_to_non_nullable
as AbilityScoreMethod?,abilityScores: freezed == abilityScores ? _self._abilityScores : abilityScores // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,classSkillChoices: null == classSkillChoices ? _self._classSkillChoices : classSkillChoices // ignore: cast_nullable_to_non_nullable
as List<String>,classToolChoices: null == classToolChoices ? _self._classToolChoices : classToolChoices // ignore: cast_nullable_to_non_nullable
as List<String>,backgroundLanguageChoices: null == backgroundLanguageChoices ? _self._backgroundLanguageChoices : backgroundLanguageChoices // ignore: cast_nullable_to_non_nullable
as List<String>,classCantripChoices: null == classCantripChoices ? _self._classCantripChoices : classCantripChoices // ignore: cast_nullable_to_non_nullable
as List<String>,classLevelOneSpellChoices: null == classLevelOneSpellChoices ? _self._classLevelOneSpellChoices : classLevelOneSpellChoices // ignore: cast_nullable_to_non_nullable
as List<String>,equipmentChoiceTab: freezed == equipmentChoiceTab ? _self.equipmentChoiceTab : equipmentChoiceTab // ignore: cast_nullable_to_non_nullable
as EquipmentChoiceTab?,purchasedEquipment: null == purchasedEquipment ? _self._purchasedEquipment : purchasedEquipment // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appearanceText: freezed == appearanceText ? _self.appearanceText : appearanceText // ignore: cast_nullable_to_non_nullable
as String?,traitsText: freezed == traitsText ? _self.traitsText : traitsText // ignore: cast_nullable_to_non_nullable
as String?,idealsText: freezed == idealsText ? _self.idealsText : idealsText // ignore: cast_nullable_to_non_nullable
as String?,bondsText: freezed == bondsText ? _self.bondsText : bondsText // ignore: cast_nullable_to_non_nullable
as String?,flawsText: freezed == flawsText ? _self.flawsText : flawsText // ignore: cast_nullable_to_non_nullable
as String?,backstoryText: freezed == backstoryText ? _self.backstoryText : backstoryText // ignore: cast_nullable_to_non_nullable
as String?,alliesText: freezed == alliesText ? _self.alliesText : alliesText // ignore: cast_nullable_to_non_nullable
as String?,featuresText: freezed == featuresText ? _self.featuresText : featuresText // ignore: cast_nullable_to_non_nullable
as String?,treasureText: freezed == treasureText ? _self.treasureText : treasureText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
