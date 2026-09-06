// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupDetail {

 String get id; String get name; String get ownerId; String get inviteCode; String get currentUserId; List<GroupMember> get members;
/// Create a copy of GroupDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupDetailCopyWith<GroupDetail> get copyWith => _$GroupDetailCopyWithImpl<GroupDetail>(this as GroupDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.currentUserId, currentUserId) || other.currentUserId == currentUserId)&&const DeepCollectionEquality().equals(other.members, members));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,ownerId,inviteCode,currentUserId,const DeepCollectionEquality().hash(members));

@override
String toString() {
  return 'GroupDetail(id: $id, name: $name, ownerId: $ownerId, inviteCode: $inviteCode, currentUserId: $currentUserId, members: $members)';
}


}

/// @nodoc
abstract mixin class $GroupDetailCopyWith<$Res>  {
  factory $GroupDetailCopyWith(GroupDetail value, $Res Function(GroupDetail) _then) = _$GroupDetailCopyWithImpl;
@useResult
$Res call({
 String id, String name, String ownerId, String inviteCode, String currentUserId, List<GroupMember> members
});




}
/// @nodoc
class _$GroupDetailCopyWithImpl<$Res>
    implements $GroupDetailCopyWith<$Res> {
  _$GroupDetailCopyWithImpl(this._self, this._then);

  final GroupDetail _self;
  final $Res Function(GroupDetail) _then;

/// Create a copy of GroupDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? ownerId = null,Object? inviteCode = null,Object? currentUserId = null,Object? members = null,}) {
  return _then(GroupDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,currentUserId: null == currentUserId ? _self.currentUserId : currentUserId // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<GroupMember>,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupDetail].
extension GroupDetailPatterns on GroupDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupDetail value)  $default,){
final _that = this;
switch (_that) {
case _GroupDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupDetail value)?  $default,){
final _that = this;
switch (_that) {
case _GroupDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String ownerId,  String inviteCode,  String currentUserId,  List<GroupMember> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupDetail() when $default != null:
return $default(_that.id,_that.name,_that.ownerId,_that.inviteCode,_that.currentUserId,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String ownerId,  String inviteCode,  String currentUserId,  List<GroupMember> members)  $default,) {final _that = this;
switch (_that) {
case _GroupDetail():
return $default(_that.id,_that.name,_that.ownerId,_that.inviteCode,_that.currentUserId,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String ownerId,  String inviteCode,  String currentUserId,  List<GroupMember> members)?  $default,) {final _that = this;
switch (_that) {
case _GroupDetail() when $default != null:
return $default(_that.id,_that.name,_that.ownerId,_that.inviteCode,_that.currentUserId,_that.members);case _:
  return null;

}
}

}

/// @nodoc


class _GroupDetail extends GroupDetail {
  const _GroupDetail({required this.id, required this.name, required this.ownerId, required this.inviteCode, required this.currentUserId, required  List<GroupMember> members}): _members = members,super._();
  

@override final  String id;
@override final  String name;
@override final  String ownerId;
@override final  String inviteCode;
@override final  String currentUserId;
 final  List<GroupMember> _members;
@override List<GroupMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of GroupDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupDetailCopyWith<_GroupDetail> get copyWith => __$GroupDetailCopyWithImpl<_GroupDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.currentUserId, currentUserId) || other.currentUserId == currentUserId)&&const DeepCollectionEquality().equals(other._members, _members));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,ownerId,inviteCode,currentUserId,const DeepCollectionEquality().hash(_members));

@override
String toString() {
  return 'GroupDetail(id: $id, name: $name, ownerId: $ownerId, inviteCode: $inviteCode, currentUserId: $currentUserId, members: $members)';
}


}

/// @nodoc
abstract mixin class _$GroupDetailCopyWith<$Res> implements $GroupDetailCopyWith<$Res> {
  factory _$GroupDetailCopyWith(_GroupDetail value, $Res Function(_GroupDetail) _then) = __$GroupDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String ownerId, String inviteCode, String currentUserId, List<GroupMember> members
});




}
/// @nodoc
class __$GroupDetailCopyWithImpl<$Res>
    implements _$GroupDetailCopyWith<$Res> {
  __$GroupDetailCopyWithImpl(this._self, this._then);

  final _GroupDetail _self;
  final $Res Function(_GroupDetail) _then;

/// Create a copy of GroupDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? ownerId = null,Object? inviteCode = null,Object? currentUserId = null,Object? members = null,}) {
  return _then(_GroupDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,currentUserId: null == currentUserId ? _self.currentUserId : currentUserId // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<GroupMember>,
  ));
}


}

// dart format on
