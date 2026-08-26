// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'background_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackgroundOption {

 int get id; String get name;/// Noms de compétences en français directement (`backgrounds
/// .skill_proficiencies`, jsonb) — pas de FK vers `skills`, donc aucune
/// jointure nécessaire pour les afficher.
 List<String> get skillProficiencies; String get featureName; String get featureDescription;/// Contenu de la clé `"tools"` de `tool_or_language_choices`, tel quel
/// (voir le commentaire de classe) — vide si cette clé est absente.
 List<String> get toolOrLanguageGrantedTools;/// Contenu de la clé `"languages"` de `tool_or_language_choices`, `null`
/// si cette clé est absente (pas de choix de langue octroyé par cet
/// historique).
 int? get languageChoiceCount;
/// Create a copy of BackgroundOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundOptionCopyWith<BackgroundOption> get copyWith => _$BackgroundOptionCopyWithImpl<BackgroundOption>(this as BackgroundOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.skillProficiencies, skillProficiencies)&&(identical(other.featureName, featureName) || other.featureName == featureName)&&(identical(other.featureDescription, featureDescription) || other.featureDescription == featureDescription)&&const DeepCollectionEquality().equals(other.toolOrLanguageGrantedTools, toolOrLanguageGrantedTools)&&(identical(other.languageChoiceCount, languageChoiceCount) || other.languageChoiceCount == languageChoiceCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(skillProficiencies),featureName,featureDescription,const DeepCollectionEquality().hash(toolOrLanguageGrantedTools),languageChoiceCount);

@override
String toString() {
  return 'BackgroundOption(id: $id, name: $name, skillProficiencies: $skillProficiencies, featureName: $featureName, featureDescription: $featureDescription, toolOrLanguageGrantedTools: $toolOrLanguageGrantedTools, languageChoiceCount: $languageChoiceCount)';
}


}

/// @nodoc
abstract mixin class $BackgroundOptionCopyWith<$Res>  {
  factory $BackgroundOptionCopyWith(BackgroundOption value, $Res Function(BackgroundOption) _then) = _$BackgroundOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, List<String> skillProficiencies, String featureName, String featureDescription, List<String> toolOrLanguageGrantedTools, int? languageChoiceCount
});




}
/// @nodoc
class _$BackgroundOptionCopyWithImpl<$Res>
    implements $BackgroundOptionCopyWith<$Res> {
  _$BackgroundOptionCopyWithImpl(this._self, this._then);

  final BackgroundOption _self;
  final $Res Function(BackgroundOption) _then;

/// Create a copy of BackgroundOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? skillProficiencies = null,Object? featureName = null,Object? featureDescription = null,Object? toolOrLanguageGrantedTools = null,Object? languageChoiceCount = freezed,}) {
  return _then(BackgroundOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,skillProficiencies: null == skillProficiencies ? _self.skillProficiencies : skillProficiencies // ignore: cast_nullable_to_non_nullable
as List<String>,featureName: null == featureName ? _self.featureName : featureName // ignore: cast_nullable_to_non_nullable
as String,featureDescription: null == featureDescription ? _self.featureDescription : featureDescription // ignore: cast_nullable_to_non_nullable
as String,toolOrLanguageGrantedTools: null == toolOrLanguageGrantedTools ? _self.toolOrLanguageGrantedTools : toolOrLanguageGrantedTools // ignore: cast_nullable_to_non_nullable
as List<String>,languageChoiceCount: freezed == languageChoiceCount ? _self.languageChoiceCount : languageChoiceCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BackgroundOption].
extension BackgroundOptionPatterns on BackgroundOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackgroundOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackgroundOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackgroundOption value)  $default,){
final _that = this;
switch (_that) {
case _BackgroundOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackgroundOption value)?  $default,){
final _that = this;
switch (_that) {
case _BackgroundOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  List<String> skillProficiencies,  String featureName,  String featureDescription,  List<String> toolOrLanguageGrantedTools,  int? languageChoiceCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackgroundOption() when $default != null:
return $default(_that.id,_that.name,_that.skillProficiencies,_that.featureName,_that.featureDescription,_that.toolOrLanguageGrantedTools,_that.languageChoiceCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  List<String> skillProficiencies,  String featureName,  String featureDescription,  List<String> toolOrLanguageGrantedTools,  int? languageChoiceCount)  $default,) {final _that = this;
switch (_that) {
case _BackgroundOption():
return $default(_that.id,_that.name,_that.skillProficiencies,_that.featureName,_that.featureDescription,_that.toolOrLanguageGrantedTools,_that.languageChoiceCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  List<String> skillProficiencies,  String featureName,  String featureDescription,  List<String> toolOrLanguageGrantedTools,  int? languageChoiceCount)?  $default,) {final _that = this;
switch (_that) {
case _BackgroundOption() when $default != null:
return $default(_that.id,_that.name,_that.skillProficiencies,_that.featureName,_that.featureDescription,_that.toolOrLanguageGrantedTools,_that.languageChoiceCount);case _:
  return null;

}
}

}

/// @nodoc


class _BackgroundOption extends BackgroundOption {
  const _BackgroundOption({required this.id, required this.name, required  List<String> skillProficiencies, required this.featureName, required this.featureDescription,  List<String> toolOrLanguageGrantedTools = const <String>[], this.languageChoiceCount}): _skillProficiencies = skillProficiencies,_toolOrLanguageGrantedTools = toolOrLanguageGrantedTools,super._();
  

@override final  int id;
@override final  String name;
/// Noms de compétences en français directement (`backgrounds
/// .skill_proficiencies`, jsonb) — pas de FK vers `skills`, donc aucune
/// jointure nécessaire pour les afficher.
 final  List<String> _skillProficiencies;
/// Noms de compétences en français directement (`backgrounds
/// .skill_proficiencies`, jsonb) — pas de FK vers `skills`, donc aucune
/// jointure nécessaire pour les afficher.
@override List<String> get skillProficiencies {
  if (_skillProficiencies is EqualUnmodifiableListView) return _skillProficiencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skillProficiencies);
}

@override final  String featureName;
@override final  String featureDescription;
/// Contenu de la clé `"tools"` de `tool_or_language_choices`, tel quel
/// (voir le commentaire de classe) — vide si cette clé est absente.
 final  List<String> _toolOrLanguageGrantedTools;
/// Contenu de la clé `"tools"` de `tool_or_language_choices`, tel quel
/// (voir le commentaire de classe) — vide si cette clé est absente.
@override@JsonKey() List<String> get toolOrLanguageGrantedTools {
  if (_toolOrLanguageGrantedTools is EqualUnmodifiableListView) return _toolOrLanguageGrantedTools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolOrLanguageGrantedTools);
}

/// Contenu de la clé `"languages"` de `tool_or_language_choices`, `null`
/// si cette clé est absente (pas de choix de langue octroyé par cet
/// historique).
@override final  int? languageChoiceCount;

/// Create a copy of BackgroundOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackgroundOptionCopyWith<_BackgroundOption> get copyWith => __$BackgroundOptionCopyWithImpl<_BackgroundOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackgroundOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._skillProficiencies, _skillProficiencies)&&(identical(other.featureName, featureName) || other.featureName == featureName)&&(identical(other.featureDescription, featureDescription) || other.featureDescription == featureDescription)&&const DeepCollectionEquality().equals(other._toolOrLanguageGrantedTools, _toolOrLanguageGrantedTools)&&(identical(other.languageChoiceCount, languageChoiceCount) || other.languageChoiceCount == languageChoiceCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_skillProficiencies),featureName,featureDescription,const DeepCollectionEquality().hash(_toolOrLanguageGrantedTools),languageChoiceCount);

@override
String toString() {
  return 'BackgroundOption(id: $id, name: $name, skillProficiencies: $skillProficiencies, featureName: $featureName, featureDescription: $featureDescription, toolOrLanguageGrantedTools: $toolOrLanguageGrantedTools, languageChoiceCount: $languageChoiceCount)';
}


}

/// @nodoc
abstract mixin class _$BackgroundOptionCopyWith<$Res> implements $BackgroundOptionCopyWith<$Res> {
  factory _$BackgroundOptionCopyWith(_BackgroundOption value, $Res Function(_BackgroundOption) _then) = __$BackgroundOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, List<String> skillProficiencies, String featureName, String featureDescription, List<String> toolOrLanguageGrantedTools, int? languageChoiceCount
});




}
/// @nodoc
class __$BackgroundOptionCopyWithImpl<$Res>
    implements _$BackgroundOptionCopyWith<$Res> {
  __$BackgroundOptionCopyWithImpl(this._self, this._then);

  final _BackgroundOption _self;
  final $Res Function(_BackgroundOption) _then;

/// Create a copy of BackgroundOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? skillProficiencies = null,Object? featureName = null,Object? featureDescription = null,Object? toolOrLanguageGrantedTools = null,Object? languageChoiceCount = freezed,}) {
  return _then(_BackgroundOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,skillProficiencies: null == skillProficiencies ? _self._skillProficiencies : skillProficiencies // ignore: cast_nullable_to_non_nullable
as List<String>,featureName: null == featureName ? _self.featureName : featureName // ignore: cast_nullable_to_non_nullable
as String,featureDescription: null == featureDescription ? _self.featureDescription : featureDescription // ignore: cast_nullable_to_non_nullable
as String,toolOrLanguageGrantedTools: null == toolOrLanguageGrantedTools ? _self._toolOrLanguageGrantedTools : toolOrLanguageGrantedTools // ignore: cast_nullable_to_non_nullable
as List<String>,languageChoiceCount: freezed == languageChoiceCount ? _self.languageChoiceCount : languageChoiceCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
