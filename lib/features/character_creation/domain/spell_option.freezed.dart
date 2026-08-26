// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spell_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpellOption {

 int get id; String get name;/// 0 = sort mineur ("cantrip"), 1 = sort de niveau 1 (seuls niveaux
/// utilisés par cette étape, `spells.level` va jusqu'à 9 mais le contenu
/// peuplé ne couvre que le socle MVP niveau 1-3/4 — voir le commentaire
/// de classe de `data/character_creation_repository.dart`).
 int get level;/// École de magie (`spells.school`, ex. "Évocation") — première moitié de
/// la ligne de méta affichée sous le nom du sort.
 String get school;/// Temps d'incantation (`spells.casting_time`, valeur brute telle que
/// stockée en base, ex. "1 action" — pas de reformatage "action" comme
/// une première lecture de la maquette aurait pu le suggérer, la colonne
/// réelle inclut toujours la quantité) — seconde moitié de la ligne de
/// méta.
 String get castingTime;
/// Create a copy of SpellOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpellOptionCopyWith<SpellOption> get copyWith => _$SpellOptionCopyWithImpl<SpellOption>(this as SpellOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpellOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.level, level) || other.level == level)&&(identical(other.school, school) || other.school == school)&&(identical(other.castingTime, castingTime) || other.castingTime == castingTime));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,level,school,castingTime);

@override
String toString() {
  return 'SpellOption(id: $id, name: $name, level: $level, school: $school, castingTime: $castingTime)';
}


}

/// @nodoc
abstract mixin class $SpellOptionCopyWith<$Res>  {
  factory $SpellOptionCopyWith(SpellOption value, $Res Function(SpellOption) _then) = _$SpellOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, int level, String school, String castingTime
});




}
/// @nodoc
class _$SpellOptionCopyWithImpl<$Res>
    implements $SpellOptionCopyWith<$Res> {
  _$SpellOptionCopyWithImpl(this._self, this._then);

  final SpellOption _self;
  final $Res Function(SpellOption) _then;

/// Create a copy of SpellOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? level = null,Object? school = null,Object? castingTime = null,}) {
  return _then(SpellOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,school: null == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String,castingTime: null == castingTime ? _self.castingTime : castingTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SpellOption].
extension SpellOptionPatterns on SpellOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpellOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpellOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpellOption value)  $default,){
final _that = this;
switch (_that) {
case _SpellOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpellOption value)?  $default,){
final _that = this;
switch (_that) {
case _SpellOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int level,  String school,  String castingTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpellOption() when $default != null:
return $default(_that.id,_that.name,_that.level,_that.school,_that.castingTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int level,  String school,  String castingTime)  $default,) {final _that = this;
switch (_that) {
case _SpellOption():
return $default(_that.id,_that.name,_that.level,_that.school,_that.castingTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int level,  String school,  String castingTime)?  $default,) {final _that = this;
switch (_that) {
case _SpellOption() when $default != null:
return $default(_that.id,_that.name,_that.level,_that.school,_that.castingTime);case _:
  return null;

}
}

}

/// @nodoc


class _SpellOption extends SpellOption {
  const _SpellOption({required this.id, required this.name, required this.level, required this.school, required this.castingTime}): super._();
  

@override final  int id;
@override final  String name;
/// 0 = sort mineur ("cantrip"), 1 = sort de niveau 1 (seuls niveaux
/// utilisés par cette étape, `spells.level` va jusqu'à 9 mais le contenu
/// peuplé ne couvre que le socle MVP niveau 1-3/4 — voir le commentaire
/// de classe de `data/character_creation_repository.dart`).
@override final  int level;
/// École de magie (`spells.school`, ex. "Évocation") — première moitié de
/// la ligne de méta affichée sous le nom du sort.
@override final  String school;
/// Temps d'incantation (`spells.casting_time`, valeur brute telle que
/// stockée en base, ex. "1 action" — pas de reformatage "action" comme
/// une première lecture de la maquette aurait pu le suggérer, la colonne
/// réelle inclut toujours la quantité) — seconde moitié de la ligne de
/// méta.
@override final  String castingTime;

/// Create a copy of SpellOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpellOptionCopyWith<_SpellOption> get copyWith => __$SpellOptionCopyWithImpl<_SpellOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpellOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.level, level) || other.level == level)&&(identical(other.school, school) || other.school == school)&&(identical(other.castingTime, castingTime) || other.castingTime == castingTime));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,level,school,castingTime);

@override
String toString() {
  return 'SpellOption(id: $id, name: $name, level: $level, school: $school, castingTime: $castingTime)';
}


}

/// @nodoc
abstract mixin class _$SpellOptionCopyWith<$Res> implements $SpellOptionCopyWith<$Res> {
  factory _$SpellOptionCopyWith(_SpellOption value, $Res Function(_SpellOption) _then) = __$SpellOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int level, String school, String castingTime
});




}
/// @nodoc
class __$SpellOptionCopyWithImpl<$Res>
    implements _$SpellOptionCopyWith<$Res> {
  __$SpellOptionCopyWithImpl(this._self, this._then);

  final _SpellOption _self;
  final $Res Function(_SpellOption) _then;

/// Create a copy of SpellOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? level = null,Object? school = null,Object? castingTime = null,}) {
  return _then(_SpellOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,school: null == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String,castingTime: null == castingTime ? _self.castingTime : castingTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
