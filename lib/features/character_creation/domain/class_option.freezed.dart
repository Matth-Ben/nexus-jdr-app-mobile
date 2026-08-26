// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClassOption {

 int get id; String get name; String get description; int get hitDie;/// Compétences de classe (`classes.skill_choices`), voir
/// [ClassSkillChoices] pour le détail des deux formes jsonb résolues.
 ClassSkillChoices get skillChoices;/// Choix interactif d'outils/instruments (`classes.tool_proficiencies`,
/// forme `{"count", "type"}`), `null` si cette classe n'a pas de choix
/// interactif (forme `[]` ou liste de noms précis, voir
/// [grantedToolNames]).
 ClassToolChoice? get toolChoice;/// Noms d'outils précis octroyés automatiquement par
/// `classes.tool_proficiencies` quand cette colonne est une liste de
/// chaînes plutôt qu'un objet `{"count", "type"}` — voir le commentaire
/// de classe pour le détail. Vide dans tous les autres cas.
 List<String> get grantedToolNames;
/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassOptionCopyWith<ClassOption> get copyWith => _$ClassOptionCopyWithImpl<ClassOption>(this as ClassOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.hitDie, hitDie) || other.hitDie == hitDie)&&(identical(other.skillChoices, skillChoices) || other.skillChoices == skillChoices)&&(identical(other.toolChoice, toolChoice) || other.toolChoice == toolChoice)&&const DeepCollectionEquality().equals(other.grantedToolNames, grantedToolNames));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,hitDie,skillChoices,toolChoice,const DeepCollectionEquality().hash(grantedToolNames));

@override
String toString() {
  return 'ClassOption(id: $id, name: $name, description: $description, hitDie: $hitDie, skillChoices: $skillChoices, toolChoice: $toolChoice, grantedToolNames: $grantedToolNames)';
}


}

/// @nodoc
abstract mixin class $ClassOptionCopyWith<$Res>  {
  factory $ClassOptionCopyWith(ClassOption value, $Res Function(ClassOption) _then) = _$ClassOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String description, int hitDie, ClassSkillChoices skillChoices, ClassToolChoice? toolChoice, List<String> grantedToolNames
});


$ClassSkillChoicesCopyWith<$Res> get skillChoices;$ClassToolChoiceCopyWith<$Res>? get toolChoice;

}
/// @nodoc
class _$ClassOptionCopyWithImpl<$Res>
    implements $ClassOptionCopyWith<$Res> {
  _$ClassOptionCopyWithImpl(this._self, this._then);

  final ClassOption _self;
  final $Res Function(ClassOption) _then;

/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? hitDie = null,Object? skillChoices = null,Object? toolChoice = freezed,Object? grantedToolNames = null,}) {
  return _then(ClassOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,hitDie: null == hitDie ? _self.hitDie : hitDie // ignore: cast_nullable_to_non_nullable
as int,skillChoices: null == skillChoices ? _self.skillChoices : skillChoices // ignore: cast_nullable_to_non_nullable
as ClassSkillChoices,toolChoice: freezed == toolChoice ? _self.toolChoice : toolChoice // ignore: cast_nullable_to_non_nullable
as ClassToolChoice?,grantedToolNames: null == grantedToolNames ? _self.grantedToolNames : grantedToolNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassSkillChoicesCopyWith<$Res> get skillChoices {
  
  return $ClassSkillChoicesCopyWith<$Res>(_self.skillChoices, (value) {
    return _then(_self.copyWith(skillChoices: value));
  });
}/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassToolChoiceCopyWith<$Res>? get toolChoice {
    if (_self.toolChoice == null) {
    return null;
  }

  return $ClassToolChoiceCopyWith<$Res>(_self.toolChoice!, (value) {
    return _then(_self.copyWith(toolChoice: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClassOption].
extension ClassOptionPatterns on ClassOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassOption value)  $default,){
final _that = this;
switch (_that) {
case _ClassOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassOption value)?  $default,){
final _that = this;
switch (_that) {
case _ClassOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String description,  int hitDie,  ClassSkillChoices skillChoices,  ClassToolChoice? toolChoice,  List<String> grantedToolNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassOption() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.hitDie,_that.skillChoices,_that.toolChoice,_that.grantedToolNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String description,  int hitDie,  ClassSkillChoices skillChoices,  ClassToolChoice? toolChoice,  List<String> grantedToolNames)  $default,) {final _that = this;
switch (_that) {
case _ClassOption():
return $default(_that.id,_that.name,_that.description,_that.hitDie,_that.skillChoices,_that.toolChoice,_that.grantedToolNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String description,  int hitDie,  ClassSkillChoices skillChoices,  ClassToolChoice? toolChoice,  List<String> grantedToolNames)?  $default,) {final _that = this;
switch (_that) {
case _ClassOption() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.hitDie,_that.skillChoices,_that.toolChoice,_that.grantedToolNames);case _:
  return null;

}
}

}

/// @nodoc


class _ClassOption extends ClassOption {
  const _ClassOption({required this.id, required this.name, required this.description, required this.hitDie, this.skillChoices = const ClassSkillChoices(count: 0, choices: []), this.toolChoice,  List<String> grantedToolNames = const <String>[]}): _grantedToolNames = grantedToolNames,super._();
  

@override final  int id;
@override final  String name;
@override final  String description;
@override final  int hitDie;
/// Compétences de classe (`classes.skill_choices`), voir
/// [ClassSkillChoices] pour le détail des deux formes jsonb résolues.
@override@JsonKey() final  ClassSkillChoices skillChoices;
/// Choix interactif d'outils/instruments (`classes.tool_proficiencies`,
/// forme `{"count", "type"}`), `null` si cette classe n'a pas de choix
/// interactif (forme `[]` ou liste de noms précis, voir
/// [grantedToolNames]).
@override final  ClassToolChoice? toolChoice;
/// Noms d'outils précis octroyés automatiquement par
/// `classes.tool_proficiencies` quand cette colonne est une liste de
/// chaînes plutôt qu'un objet `{"count", "type"}` — voir le commentaire
/// de classe pour le détail. Vide dans tous les autres cas.
 final  List<String> _grantedToolNames;
/// Noms d'outils précis octroyés automatiquement par
/// `classes.tool_proficiencies` quand cette colonne est une liste de
/// chaînes plutôt qu'un objet `{"count", "type"}` — voir le commentaire
/// de classe pour le détail. Vide dans tous les autres cas.
@override@JsonKey() List<String> get grantedToolNames {
  if (_grantedToolNames is EqualUnmodifiableListView) return _grantedToolNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_grantedToolNames);
}


/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassOptionCopyWith<_ClassOption> get copyWith => __$ClassOptionCopyWithImpl<_ClassOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.hitDie, hitDie) || other.hitDie == hitDie)&&(identical(other.skillChoices, skillChoices) || other.skillChoices == skillChoices)&&(identical(other.toolChoice, toolChoice) || other.toolChoice == toolChoice)&&const DeepCollectionEquality().equals(other._grantedToolNames, _grantedToolNames));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,hitDie,skillChoices,toolChoice,const DeepCollectionEquality().hash(_grantedToolNames));

@override
String toString() {
  return 'ClassOption(id: $id, name: $name, description: $description, hitDie: $hitDie, skillChoices: $skillChoices, toolChoice: $toolChoice, grantedToolNames: $grantedToolNames)';
}


}

/// @nodoc
abstract mixin class _$ClassOptionCopyWith<$Res> implements $ClassOptionCopyWith<$Res> {
  factory _$ClassOptionCopyWith(_ClassOption value, $Res Function(_ClassOption) _then) = __$ClassOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String description, int hitDie, ClassSkillChoices skillChoices, ClassToolChoice? toolChoice, List<String> grantedToolNames
});


@override $ClassSkillChoicesCopyWith<$Res> get skillChoices;@override $ClassToolChoiceCopyWith<$Res>? get toolChoice;

}
/// @nodoc
class __$ClassOptionCopyWithImpl<$Res>
    implements _$ClassOptionCopyWith<$Res> {
  __$ClassOptionCopyWithImpl(this._self, this._then);

  final _ClassOption _self;
  final $Res Function(_ClassOption) _then;

/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? hitDie = null,Object? skillChoices = null,Object? toolChoice = freezed,Object? grantedToolNames = null,}) {
  return _then(_ClassOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,hitDie: null == hitDie ? _self.hitDie : hitDie // ignore: cast_nullable_to_non_nullable
as int,skillChoices: null == skillChoices ? _self.skillChoices : skillChoices // ignore: cast_nullable_to_non_nullable
as ClassSkillChoices,toolChoice: freezed == toolChoice ? _self.toolChoice : toolChoice // ignore: cast_nullable_to_non_nullable
as ClassToolChoice?,grantedToolNames: null == grantedToolNames ? _self._grantedToolNames : grantedToolNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassSkillChoicesCopyWith<$Res> get skillChoices {
  
  return $ClassSkillChoicesCopyWith<$Res>(_self.skillChoices, (value) {
    return _then(_self.copyWith(skillChoices: value));
  });
}/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassToolChoiceCopyWith<$Res>? get toolChoice {
    if (_self.toolChoice == null) {
    return null;
  }

  return $ClassToolChoiceCopyWith<$Res>(_self.toolChoice!, (value) {
    return _then(_self.copyWith(toolChoice: value));
  });
}
}

// dart format on
