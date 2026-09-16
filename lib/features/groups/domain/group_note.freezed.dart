// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupNote {

 String get groupId; String get characterId; String get body;
/// Create a copy of GroupNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupNoteCopyWith<GroupNote> get copyWith => _$GroupNoteCopyWithImpl<GroupNote>(this as GroupNote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupNote&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,groupId,characterId,body);

@override
String toString() {
  return 'GroupNote(groupId: $groupId, characterId: $characterId, body: $body)';
}


}

/// @nodoc
abstract mixin class $GroupNoteCopyWith<$Res>  {
  factory $GroupNoteCopyWith(GroupNote value, $Res Function(GroupNote) _then) = _$GroupNoteCopyWithImpl;
@useResult
$Res call({
 String groupId, String characterId, String body
});




}
/// @nodoc
class _$GroupNoteCopyWithImpl<$Res>
    implements $GroupNoteCopyWith<$Res> {
  _$GroupNoteCopyWithImpl(this._self, this._then);

  final GroupNote _self;
  final $Res Function(GroupNote) _then;

/// Create a copy of GroupNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? characterId = null,Object? body = null,}) {
  return _then(GroupNote(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupNote].
extension GroupNotePatterns on GroupNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupNote value)  $default,){
final _that = this;
switch (_that) {
case _GroupNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupNote value)?  $default,){
final _that = this;
switch (_that) {
case _GroupNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  String characterId,  String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupNote() when $default != null:
return $default(_that.groupId,_that.characterId,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  String characterId,  String body)  $default,) {final _that = this;
switch (_that) {
case _GroupNote():
return $default(_that.groupId,_that.characterId,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  String characterId,  String body)?  $default,) {final _that = this;
switch (_that) {
case _GroupNote() when $default != null:
return $default(_that.groupId,_that.characterId,_that.body);case _:
  return null;

}
}

}

/// @nodoc


class _GroupNote implements GroupNote {
  const _GroupNote({required this.groupId, required this.characterId, this.body = ''});
  

@override final  String groupId;
@override final  String characterId;
@override@JsonKey() final  String body;

/// Create a copy of GroupNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupNoteCopyWith<_GroupNote> get copyWith => __$GroupNoteCopyWithImpl<_GroupNote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupNote&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,groupId,characterId,body);

@override
String toString() {
  return 'GroupNote(groupId: $groupId, characterId: $characterId, body: $body)';
}


}

/// @nodoc
abstract mixin class _$GroupNoteCopyWith<$Res> implements $GroupNoteCopyWith<$Res> {
  factory _$GroupNoteCopyWith(_GroupNote value, $Res Function(_GroupNote) _then) = __$GroupNoteCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String characterId, String body
});




}
/// @nodoc
class __$GroupNoteCopyWithImpl<$Res>
    implements _$GroupNoteCopyWith<$Res> {
  __$GroupNoteCopyWithImpl(this._self, this._then);

  final _GroupNote _self;
  final $Res Function(_GroupNote) _then;

/// Create a copy of GroupNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? characterId = null,Object? body = null,}) {
  return _then(_GroupNote(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
