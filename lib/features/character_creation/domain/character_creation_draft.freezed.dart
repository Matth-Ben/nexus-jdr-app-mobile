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
 List<String> get backgroundLanguageChoices;
/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterCreationDraftCopyWith<CharacterCreationDraft> get copyWith => _$CharacterCreationDraftCopyWithImpl<CharacterCreationDraft>(this as CharacterCreationDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterCreationDraft&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.subraceId, subraceId) || other.subraceId == subraceId)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.backgroundId, backgroundId) || other.backgroundId == backgroundId)&&(identical(other.abilityScoreMethod, abilityScoreMethod) || other.abilityScoreMethod == abilityScoreMethod)&&const DeepCollectionEquality().equals(other.abilityScores, abilityScores)&&const DeepCollectionEquality().equals(other.classSkillChoices, classSkillChoices)&&const DeepCollectionEquality().equals(other.classToolChoices, classToolChoices)&&const DeepCollectionEquality().equals(other.backgroundLanguageChoices, backgroundLanguageChoices));
}


@override
int get hashCode => Object.hash(runtimeType,raceId,subraceId,raceCustomText,classId,backgroundId,abilityScoreMethod,const DeepCollectionEquality().hash(abilityScores),const DeepCollectionEquality().hash(classSkillChoices),const DeepCollectionEquality().hash(classToolChoices),const DeepCollectionEquality().hash(backgroundLanguageChoices));

@override
String toString() {
  return 'CharacterCreationDraft(raceId: $raceId, subraceId: $subraceId, raceCustomText: $raceCustomText, classId: $classId, backgroundId: $backgroundId, abilityScoreMethod: $abilityScoreMethod, abilityScores: $abilityScores, classSkillChoices: $classSkillChoices, classToolChoices: $classToolChoices, backgroundLanguageChoices: $backgroundLanguageChoices)';
}


}

/// @nodoc
abstract mixin class $CharacterCreationDraftCopyWith<$Res>  {
  factory $CharacterCreationDraftCopyWith(CharacterCreationDraft value, $Res Function(CharacterCreationDraft) _then) = _$CharacterCreationDraftCopyWithImpl;
@useResult
$Res call({
 int? raceId, int? subraceId, String? raceCustomText, int? classId, int? backgroundId, AbilityScoreMethod? abilityScoreMethod, Map<String, int>? abilityScores, List<String> classSkillChoices, List<String> classToolChoices, List<String> backgroundLanguageChoices
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
@pragma('vm:prefer-inline') @override $Res call({Object? raceId = freezed,Object? subraceId = freezed,Object? raceCustomText = freezed,Object? classId = freezed,Object? backgroundId = freezed,Object? abilityScoreMethod = freezed,Object? abilityScores = freezed,Object? classSkillChoices = null,Object? classToolChoices = null,Object? backgroundLanguageChoices = null,}) {
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
as List<String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId,  int? backgroundId,  AbilityScoreMethod? abilityScoreMethod,  Map<String, int>? abilityScores,  List<String> classSkillChoices,  List<String> classToolChoices,  List<String> backgroundLanguageChoices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId,_that.backgroundId,_that.abilityScoreMethod,_that.abilityScores,_that.classSkillChoices,_that.classToolChoices,_that.backgroundLanguageChoices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId,  int? backgroundId,  AbilityScoreMethod? abilityScoreMethod,  Map<String, int>? abilityScores,  List<String> classSkillChoices,  List<String> classToolChoices,  List<String> backgroundLanguageChoices)  $default,) {final _that = this;
switch (_that) {
case _CharacterCreationDraft():
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId,_that.backgroundId,_that.abilityScoreMethod,_that.abilityScores,_that.classSkillChoices,_that.classToolChoices,_that.backgroundLanguageChoices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId,  int? backgroundId,  AbilityScoreMethod? abilityScoreMethod,  Map<String, int>? abilityScores,  List<String> classSkillChoices,  List<String> classToolChoices,  List<String> backgroundLanguageChoices)?  $default,) {final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId,_that.backgroundId,_that.abilityScoreMethod,_that.abilityScores,_that.classSkillChoices,_that.classToolChoices,_that.backgroundLanguageChoices);case _:
  return null;

}
}

}

/// @nodoc


class _CharacterCreationDraft implements CharacterCreationDraft {
  const _CharacterCreationDraft({this.raceId, this.subraceId, this.raceCustomText, this.classId, this.backgroundId, this.abilityScoreMethod,  Map<String, int>? abilityScores,  List<String> classSkillChoices = const <String>[],  List<String> classToolChoices = const <String>[],  List<String> backgroundLanguageChoices = const <String>[]}): _abilityScores = abilityScores,_classSkillChoices = classSkillChoices,_classToolChoices = classToolChoices,_backgroundLanguageChoices = backgroundLanguageChoices;
  

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


/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterCreationDraftCopyWith<_CharacterCreationDraft> get copyWith => __$CharacterCreationDraftCopyWithImpl<_CharacterCreationDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterCreationDraft&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.subraceId, subraceId) || other.subraceId == subraceId)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.backgroundId, backgroundId) || other.backgroundId == backgroundId)&&(identical(other.abilityScoreMethod, abilityScoreMethod) || other.abilityScoreMethod == abilityScoreMethod)&&const DeepCollectionEquality().equals(other._abilityScores, _abilityScores)&&const DeepCollectionEquality().equals(other._classSkillChoices, _classSkillChoices)&&const DeepCollectionEquality().equals(other._classToolChoices, _classToolChoices)&&const DeepCollectionEquality().equals(other._backgroundLanguageChoices, _backgroundLanguageChoices));
}


@override
int get hashCode => Object.hash(runtimeType,raceId,subraceId,raceCustomText,classId,backgroundId,abilityScoreMethod,const DeepCollectionEquality().hash(_abilityScores),const DeepCollectionEquality().hash(_classSkillChoices),const DeepCollectionEquality().hash(_classToolChoices),const DeepCollectionEquality().hash(_backgroundLanguageChoices));

@override
String toString() {
  return 'CharacterCreationDraft(raceId: $raceId, subraceId: $subraceId, raceCustomText: $raceCustomText, classId: $classId, backgroundId: $backgroundId, abilityScoreMethod: $abilityScoreMethod, abilityScores: $abilityScores, classSkillChoices: $classSkillChoices, classToolChoices: $classToolChoices, backgroundLanguageChoices: $backgroundLanguageChoices)';
}


}

/// @nodoc
abstract mixin class _$CharacterCreationDraftCopyWith<$Res> implements $CharacterCreationDraftCopyWith<$Res> {
  factory _$CharacterCreationDraftCopyWith(_CharacterCreationDraft value, $Res Function(_CharacterCreationDraft) _then) = __$CharacterCreationDraftCopyWithImpl;
@override @useResult
$Res call({
 int? raceId, int? subraceId, String? raceCustomText, int? classId, int? backgroundId, AbilityScoreMethod? abilityScoreMethod, Map<String, int>? abilityScores, List<String> classSkillChoices, List<String> classToolChoices, List<String> backgroundLanguageChoices
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
@override @pragma('vm:prefer-inline') $Res call({Object? raceId = freezed,Object? subraceId = freezed,Object? raceCustomText = freezed,Object? classId = freezed,Object? backgroundId = freezed,Object? abilityScoreMethod = freezed,Object? abilityScores = freezed,Object? classSkillChoices = null,Object? classToolChoices = null,Object? backgroundLanguageChoices = null,}) {
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
as List<String>,
  ));
}


}

// dart format on
