// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'joined_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JoinedGroup {

 String get groupId; String get name;
/// Create a copy of JoinedGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinedGroupCopyWith<JoinedGroup> get copyWith => _$JoinedGroupCopyWithImpl<JoinedGroup>(this as JoinedGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinedGroup&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,groupId,name);

@override
String toString() {
  return 'JoinedGroup(groupId: $groupId, name: $name)';
}


}

/// @nodoc
abstract mixin class $JoinedGroupCopyWith<$Res>  {
  factory $JoinedGroupCopyWith(JoinedGroup value, $Res Function(JoinedGroup) _then) = _$JoinedGroupCopyWithImpl;
@useResult
$Res call({
 String groupId, String name
});




}
/// @nodoc
class _$JoinedGroupCopyWithImpl<$Res>
    implements $JoinedGroupCopyWith<$Res> {
  _$JoinedGroupCopyWithImpl(this._self, this._then);

  final JoinedGroup _self;
  final $Res Function(JoinedGroup) _then;

/// Create a copy of JoinedGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? name = null,}) {
  return _then(JoinedGroup(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinedGroup].
extension JoinedGroupPatterns on JoinedGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinedGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinedGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinedGroup value)  $default,){
final _that = this;
switch (_that) {
case _JoinedGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinedGroup value)?  $default,){
final _that = this;
switch (_that) {
case _JoinedGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinedGroup() when $default != null:
return $default(_that.groupId,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  String name)  $default,) {final _that = this;
switch (_that) {
case _JoinedGroup():
return $default(_that.groupId,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  String name)?  $default,) {final _that = this;
switch (_that) {
case _JoinedGroup() when $default != null:
return $default(_that.groupId,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _JoinedGroup implements JoinedGroup {
  const _JoinedGroup({required this.groupId, required this.name});
  

@override final  String groupId;
@override final  String name;

/// Create a copy of JoinedGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinedGroupCopyWith<_JoinedGroup> get copyWith => __$JoinedGroupCopyWithImpl<_JoinedGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinedGroup&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,groupId,name);

@override
String toString() {
  return 'JoinedGroup(groupId: $groupId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$JoinedGroupCopyWith<$Res> implements $JoinedGroupCopyWith<$Res> {
  factory _$JoinedGroupCopyWith(_JoinedGroup value, $Res Function(_JoinedGroup) _then) = __$JoinedGroupCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String name
});




}
/// @nodoc
class __$JoinedGroupCopyWithImpl<$Res>
    implements _$JoinedGroupCopyWith<$Res> {
  __$JoinedGroupCopyWithImpl(this._self, this._then);

  final _JoinedGroup _self;
  final $Res Function(_JoinedGroup) _then;

/// Create a copy of JoinedGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? name = null,}) {
  return _then(_JoinedGroup(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
