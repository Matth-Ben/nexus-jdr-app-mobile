// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillOption {

 int get id; String get name; String get abilityId;
/// Create a copy of SkillOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillOptionCopyWith<SkillOption> get copyWith => _$SkillOptionCopyWithImpl<SkillOption>(this as SkillOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.abilityId, abilityId) || other.abilityId == abilityId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,abilityId);

@override
String toString() {
  return 'SkillOption(id: $id, name: $name, abilityId: $abilityId)';
}


}

/// @nodoc
abstract mixin class $SkillOptionCopyWith<$Res>  {
  factory $SkillOptionCopyWith(SkillOption value, $Res Function(SkillOption) _then) = _$SkillOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String abilityId
});




}
/// @nodoc
class _$SkillOptionCopyWithImpl<$Res>
    implements $SkillOptionCopyWith<$Res> {
  _$SkillOptionCopyWithImpl(this._self, this._then);

  final SkillOption _self;
  final $Res Function(SkillOption) _then;

/// Create a copy of SkillOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? abilityId = null,}) {
  return _then(SkillOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,abilityId: null == abilityId ? _self.abilityId : abilityId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillOption].
extension SkillOptionPatterns on SkillOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillOption value)  $default,){
final _that = this;
switch (_that) {
case _SkillOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillOption value)?  $default,){
final _that = this;
switch (_that) {
case _SkillOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String abilityId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillOption() when $default != null:
return $default(_that.id,_that.name,_that.abilityId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String abilityId)  $default,) {final _that = this;
switch (_that) {
case _SkillOption():
return $default(_that.id,_that.name,_that.abilityId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String abilityId)?  $default,) {final _that = this;
switch (_that) {
case _SkillOption() when $default != null:
return $default(_that.id,_that.name,_that.abilityId);case _:
  return null;

}
}

}

/// @nodoc


class _SkillOption implements SkillOption {
  const _SkillOption({required this.id, required this.name, required this.abilityId});
  

@override final  int id;
@override final  String name;
@override final  String abilityId;

/// Create a copy of SkillOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillOptionCopyWith<_SkillOption> get copyWith => __$SkillOptionCopyWithImpl<_SkillOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.abilityId, abilityId) || other.abilityId == abilityId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,abilityId);

@override
String toString() {
  return 'SkillOption(id: $id, name: $name, abilityId: $abilityId)';
}


}

/// @nodoc
abstract mixin class _$SkillOptionCopyWith<$Res> implements $SkillOptionCopyWith<$Res> {
  factory _$SkillOptionCopyWith(_SkillOption value, $Res Function(_SkillOption) _then) = __$SkillOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String abilityId
});




}
/// @nodoc
class __$SkillOptionCopyWithImpl<$Res>
    implements _$SkillOptionCopyWith<$Res> {
  __$SkillOptionCopyWithImpl(this._self, this._then);

  final _SkillOption _self;
  final $Res Function(_SkillOption) _then;

/// Create a copy of SkillOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? abilityId = null,}) {
  return _then(_SkillOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,abilityId: null == abilityId ? _self.abilityId : abilityId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
