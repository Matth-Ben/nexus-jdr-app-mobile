// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lineage_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LineageOption {

/// `race_lineages.id` — devient `characters.lineage_id` à la création
/// (voir `data/character_creation_repository.dart::createCharacter`).
 int get id; String get name;/// `null` si aucune donnée mécanique stockée en base ne justifie
/// d'afficher un sous-titre (ex. Goliath : `damage_type` et
/// `racial_innate_spells` tous deux absents — ne JAMAIS inventer un
/// effet non stocké).
 String? get subtitle;
/// Create a copy of LineageOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineageOptionCopyWith<LineageOption> get copyWith => _$LineageOptionCopyWithImpl<LineageOption>(this as LineageOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineageOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,subtitle);

@override
String toString() {
  return 'LineageOption(id: $id, name: $name, subtitle: $subtitle)';
}


}

/// @nodoc
abstract mixin class $LineageOptionCopyWith<$Res>  {
  factory $LineageOptionCopyWith(LineageOption value, $Res Function(LineageOption) _then) = _$LineageOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? subtitle
});




}
/// @nodoc
class _$LineageOptionCopyWithImpl<$Res>
    implements $LineageOptionCopyWith<$Res> {
  _$LineageOptionCopyWithImpl(this._self, this._then);

  final LineageOption _self;
  final $Res Function(LineageOption) _then;

/// Create a copy of LineageOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? subtitle = freezed,}) {
  return _then(LineageOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LineageOption].
extension LineageOptionPatterns on LineageOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LineageOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LineageOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LineageOption value)  $default,){
final _that = this;
switch (_that) {
case _LineageOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LineageOption value)?  $default,){
final _that = this;
switch (_that) {
case _LineageOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? subtitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LineageOption() when $default != null:
return $default(_that.id,_that.name,_that.subtitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? subtitle)  $default,) {final _that = this;
switch (_that) {
case _LineageOption():
return $default(_that.id,_that.name,_that.subtitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? subtitle)?  $default,) {final _that = this;
switch (_that) {
case _LineageOption() when $default != null:
return $default(_that.id,_that.name,_that.subtitle);case _:
  return null;

}
}

}

/// @nodoc


class _LineageOption implements LineageOption {
  const _LineageOption({required this.id, required this.name, this.subtitle});
  

/// `race_lineages.id` — devient `characters.lineage_id` à la création
/// (voir `data/character_creation_repository.dart::createCharacter`).
@override final  int id;
@override final  String name;
/// `null` si aucune donnée mécanique stockée en base ne justifie
/// d'afficher un sous-titre (ex. Goliath : `damage_type` et
/// `racial_innate_spells` tous deux absents — ne JAMAIS inventer un
/// effet non stocké).
@override final  String? subtitle;

/// Create a copy of LineageOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LineageOptionCopyWith<_LineageOption> get copyWith => __$LineageOptionCopyWithImpl<_LineageOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LineageOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,subtitle);

@override
String toString() {
  return 'LineageOption(id: $id, name: $name, subtitle: $subtitle)';
}


}

/// @nodoc
abstract mixin class _$LineageOptionCopyWith<$Res> implements $LineageOptionCopyWith<$Res> {
  factory _$LineageOptionCopyWith(_LineageOption value, $Res Function(_LineageOption) _then) = __$LineageOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? subtitle
});




}
/// @nodoc
class __$LineageOptionCopyWithImpl<$Res>
    implements _$LineageOptionCopyWith<$Res> {
  __$LineageOptionCopyWithImpl(this._self, this._then);

  final _LineageOption _self;
  final $Res Function(_LineageOption) _then;

/// Create a copy of LineageOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? subtitle = freezed,}) {
  return _then(_LineageOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
