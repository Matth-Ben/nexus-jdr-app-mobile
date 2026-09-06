// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'created_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreatedGroup {

 String get id; String get name; String get inviteCode;
/// Create a copy of CreatedGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatedGroupCopyWith<CreatedGroup> get copyWith => _$CreatedGroupCopyWithImpl<CreatedGroup>(this as CreatedGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatedGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,inviteCode);

@override
String toString() {
  return 'CreatedGroup(id: $id, name: $name, inviteCode: $inviteCode)';
}


}

/// @nodoc
abstract mixin class $CreatedGroupCopyWith<$Res>  {
  factory $CreatedGroupCopyWith(CreatedGroup value, $Res Function(CreatedGroup) _then) = _$CreatedGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, String inviteCode
});




}
/// @nodoc
class _$CreatedGroupCopyWithImpl<$Res>
    implements $CreatedGroupCopyWith<$Res> {
  _$CreatedGroupCopyWithImpl(this._self, this._then);

  final CreatedGroup _self;
  final $Res Function(CreatedGroup) _then;

/// Create a copy of CreatedGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? inviteCode = null,}) {
  return _then(CreatedGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatedGroup].
extension CreatedGroupPatterns on CreatedGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatedGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatedGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatedGroup value)  $default,){
final _that = this;
switch (_that) {
case _CreatedGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatedGroup value)?  $default,){
final _that = this;
switch (_that) {
case _CreatedGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String inviteCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatedGroup() when $default != null:
return $default(_that.id,_that.name,_that.inviteCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String inviteCode)  $default,) {final _that = this;
switch (_that) {
case _CreatedGroup():
return $default(_that.id,_that.name,_that.inviteCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String inviteCode)?  $default,) {final _that = this;
switch (_that) {
case _CreatedGroup() when $default != null:
return $default(_that.id,_that.name,_that.inviteCode);case _:
  return null;

}
}

}

/// @nodoc


class _CreatedGroup implements CreatedGroup {
  const _CreatedGroup({required this.id, required this.name, required this.inviteCode});
  

@override final  String id;
@override final  String name;
@override final  String inviteCode;

/// Create a copy of CreatedGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatedGroupCopyWith<_CreatedGroup> get copyWith => __$CreatedGroupCopyWithImpl<_CreatedGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatedGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,inviteCode);

@override
String toString() {
  return 'CreatedGroup(id: $id, name: $name, inviteCode: $inviteCode)';
}


}

/// @nodoc
abstract mixin class _$CreatedGroupCopyWith<$Res> implements $CreatedGroupCopyWith<$Res> {
  factory _$CreatedGroupCopyWith(_CreatedGroup value, $Res Function(_CreatedGroup) _then) = __$CreatedGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String inviteCode
});




}
/// @nodoc
class __$CreatedGroupCopyWithImpl<$Res>
    implements _$CreatedGroupCopyWith<$Res> {
  __$CreatedGroupCopyWithImpl(this._self, this._then);

  final _CreatedGroup _self;
  final $Res Function(_CreatedGroup) _then;

/// Create a copy of CreatedGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? inviteCode = null,}) {
  return _then(_CreatedGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
