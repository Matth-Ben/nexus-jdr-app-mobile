// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_racial_trait.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CharacterRacialTrait {

 String get name; String get description;
/// Create a copy of CharacterRacialTrait
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterRacialTraitCopyWith<CharacterRacialTrait> get copyWith => _$CharacterRacialTraitCopyWithImpl<CharacterRacialTrait>(this as CharacterRacialTrait, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterRacialTrait&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'CharacterRacialTrait(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $CharacterRacialTraitCopyWith<$Res>  {
  factory $CharacterRacialTraitCopyWith(CharacterRacialTrait value, $Res Function(CharacterRacialTrait) _then) = _$CharacterRacialTraitCopyWithImpl;
@useResult
$Res call({
 String name, String description
});




}
/// @nodoc
class _$CharacterRacialTraitCopyWithImpl<$Res>
    implements $CharacterRacialTraitCopyWith<$Res> {
  _$CharacterRacialTraitCopyWithImpl(this._self, this._then);

  final CharacterRacialTrait _self;
  final $Res Function(CharacterRacialTrait) _then;

/// Create a copy of CharacterRacialTrait
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,}) {
  return _then(CharacterRacialTrait(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterRacialTrait].
extension CharacterRacialTraitPatterns on CharacterRacialTrait {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterRacialTrait value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterRacialTrait() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterRacialTrait value)  $default,){
final _that = this;
switch (_that) {
case _CharacterRacialTrait():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterRacialTrait value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterRacialTrait() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterRacialTrait() when $default != null:
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description)  $default,) {final _that = this;
switch (_that) {
case _CharacterRacialTrait():
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description)?  $default,) {final _that = this;
switch (_that) {
case _CharacterRacialTrait() when $default != null:
return $default(_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _CharacterRacialTrait implements CharacterRacialTrait {
  const _CharacterRacialTrait({required this.name, required this.description});
  

@override final  String name;
@override final  String description;

/// Create a copy of CharacterRacialTrait
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterRacialTraitCopyWith<_CharacterRacialTrait> get copyWith => __$CharacterRacialTraitCopyWithImpl<_CharacterRacialTrait>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterRacialTrait&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'CharacterRacialTrait(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$CharacterRacialTraitCopyWith<$Res> implements $CharacterRacialTraitCopyWith<$Res> {
  factory _$CharacterRacialTraitCopyWith(_CharacterRacialTrait value, $Res Function(_CharacterRacialTrait) _then) = __$CharacterRacialTraitCopyWithImpl;
@override @useResult
$Res call({
 String name, String description
});




}
/// @nodoc
class __$CharacterRacialTraitCopyWithImpl<$Res>
    implements _$CharacterRacialTraitCopyWith<$Res> {
  __$CharacterRacialTraitCopyWithImpl(this._self, this._then);

  final _CharacterRacialTrait _self;
  final $Res Function(_CharacterRacialTrait) _then;

/// Create a copy of CharacterRacialTrait
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,}) {
  return _then(_CharacterRacialTrait(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
