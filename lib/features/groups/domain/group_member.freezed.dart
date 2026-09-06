// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupMember {

 String get characterId; String get userId; GroupRole get role; String get name; String? get portraitUrl; String? get raceName; String? get className; int get level; int get currentHp; int get maxHp; int get temporaryHp; bool get isDead;
/// Create a copy of GroupMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupMemberCopyWith<GroupMember> get copyWith => _$GroupMemberCopyWithImpl<GroupMember>(this as GroupMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupMember&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.name, name) || other.name == name)&&(identical(other.portraitUrl, portraitUrl) || other.portraitUrl == portraitUrl)&&(identical(other.raceName, raceName) || other.raceName == raceName)&&(identical(other.className, className) || other.className == className)&&(identical(other.level, level) || other.level == level)&&(identical(other.currentHp, currentHp) || other.currentHp == currentHp)&&(identical(other.maxHp, maxHp) || other.maxHp == maxHp)&&(identical(other.temporaryHp, temporaryHp) || other.temporaryHp == temporaryHp)&&(identical(other.isDead, isDead) || other.isDead == isDead));
}


@override
int get hashCode => Object.hash(runtimeType,characterId,userId,role,name,portraitUrl,raceName,className,level,currentHp,maxHp,temporaryHp,isDead);

@override
String toString() {
  return 'GroupMember(characterId: $characterId, userId: $userId, role: $role, name: $name, portraitUrl: $portraitUrl, raceName: $raceName, className: $className, level: $level, currentHp: $currentHp, maxHp: $maxHp, temporaryHp: $temporaryHp, isDead: $isDead)';
}


}

/// @nodoc
abstract mixin class $GroupMemberCopyWith<$Res>  {
  factory $GroupMemberCopyWith(GroupMember value, $Res Function(GroupMember) _then) = _$GroupMemberCopyWithImpl;
@useResult
$Res call({
 String characterId, String userId, GroupRole role, String name, String? portraitUrl, String? raceName, String? className, int level, int currentHp, int maxHp, int temporaryHp, bool isDead
});




}
/// @nodoc
class _$GroupMemberCopyWithImpl<$Res>
    implements $GroupMemberCopyWith<$Res> {
  _$GroupMemberCopyWithImpl(this._self, this._then);

  final GroupMember _self;
  final $Res Function(GroupMember) _then;

/// Create a copy of GroupMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? characterId = null,Object? userId = null,Object? role = null,Object? name = null,Object? portraitUrl = freezed,Object? raceName = freezed,Object? className = freezed,Object? level = null,Object? currentHp = null,Object? maxHp = null,Object? temporaryHp = null,Object? isDead = null,}) {
  return _then(GroupMember(
characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as GroupRole,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,portraitUrl: freezed == portraitUrl ? _self.portraitUrl : portraitUrl // ignore: cast_nullable_to_non_nullable
as String?,raceName: freezed == raceName ? _self.raceName : raceName // ignore: cast_nullable_to_non_nullable
as String?,className: freezed == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,currentHp: null == currentHp ? _self.currentHp : currentHp // ignore: cast_nullable_to_non_nullable
as int,maxHp: null == maxHp ? _self.maxHp : maxHp // ignore: cast_nullable_to_non_nullable
as int,temporaryHp: null == temporaryHp ? _self.temporaryHp : temporaryHp // ignore: cast_nullable_to_non_nullable
as int,isDead: null == isDead ? _self.isDead : isDead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupMember].
extension GroupMemberPatterns on GroupMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupMember value)  $default,){
final _that = this;
switch (_that) {
case _GroupMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupMember value)?  $default,){
final _that = this;
switch (_that) {
case _GroupMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String characterId,  String userId,  GroupRole role,  String name,  String? portraitUrl,  String? raceName,  String? className,  int level,  int currentHp,  int maxHp,  int temporaryHp,  bool isDead)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupMember() when $default != null:
return $default(_that.characterId,_that.userId,_that.role,_that.name,_that.portraitUrl,_that.raceName,_that.className,_that.level,_that.currentHp,_that.maxHp,_that.temporaryHp,_that.isDead);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String characterId,  String userId,  GroupRole role,  String name,  String? portraitUrl,  String? raceName,  String? className,  int level,  int currentHp,  int maxHp,  int temporaryHp,  bool isDead)  $default,) {final _that = this;
switch (_that) {
case _GroupMember():
return $default(_that.characterId,_that.userId,_that.role,_that.name,_that.portraitUrl,_that.raceName,_that.className,_that.level,_that.currentHp,_that.maxHp,_that.temporaryHp,_that.isDead);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String characterId,  String userId,  GroupRole role,  String name,  String? portraitUrl,  String? raceName,  String? className,  int level,  int currentHp,  int maxHp,  int temporaryHp,  bool isDead)?  $default,) {final _that = this;
switch (_that) {
case _GroupMember() when $default != null:
return $default(_that.characterId,_that.userId,_that.role,_that.name,_that.portraitUrl,_that.raceName,_that.className,_that.level,_that.currentHp,_that.maxHp,_that.temporaryHp,_that.isDead);case _:
  return null;

}
}

}

/// @nodoc


class _GroupMember extends GroupMember {
  const _GroupMember({required this.characterId, required this.userId, required this.role, required this.name, this.portraitUrl, this.raceName, this.className, required this.level, required this.currentHp, required this.maxHp, required this.temporaryHp, required this.isDead}): super._();
  

@override final  String characterId;
@override final  String userId;
@override final  GroupRole role;
@override final  String name;
@override final  String? portraitUrl;
@override final  String? raceName;
@override final  String? className;
@override final  int level;
@override final  int currentHp;
@override final  int maxHp;
@override final  int temporaryHp;
@override final  bool isDead;

/// Create a copy of GroupMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupMemberCopyWith<_GroupMember> get copyWith => __$GroupMemberCopyWithImpl<_GroupMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupMember&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.name, name) || other.name == name)&&(identical(other.portraitUrl, portraitUrl) || other.portraitUrl == portraitUrl)&&(identical(other.raceName, raceName) || other.raceName == raceName)&&(identical(other.className, className) || other.className == className)&&(identical(other.level, level) || other.level == level)&&(identical(other.currentHp, currentHp) || other.currentHp == currentHp)&&(identical(other.maxHp, maxHp) || other.maxHp == maxHp)&&(identical(other.temporaryHp, temporaryHp) || other.temporaryHp == temporaryHp)&&(identical(other.isDead, isDead) || other.isDead == isDead));
}


@override
int get hashCode => Object.hash(runtimeType,characterId,userId,role,name,portraitUrl,raceName,className,level,currentHp,maxHp,temporaryHp,isDead);

@override
String toString() {
  return 'GroupMember(characterId: $characterId, userId: $userId, role: $role, name: $name, portraitUrl: $portraitUrl, raceName: $raceName, className: $className, level: $level, currentHp: $currentHp, maxHp: $maxHp, temporaryHp: $temporaryHp, isDead: $isDead)';
}


}

/// @nodoc
abstract mixin class _$GroupMemberCopyWith<$Res> implements $GroupMemberCopyWith<$Res> {
  factory _$GroupMemberCopyWith(_GroupMember value, $Res Function(_GroupMember) _then) = __$GroupMemberCopyWithImpl;
@override @useResult
$Res call({
 String characterId, String userId, GroupRole role, String name, String? portraitUrl, String? raceName, String? className, int level, int currentHp, int maxHp, int temporaryHp, bool isDead
});




}
/// @nodoc
class __$GroupMemberCopyWithImpl<$Res>
    implements _$GroupMemberCopyWith<$Res> {
  __$GroupMemberCopyWithImpl(this._self, this._then);

  final _GroupMember _self;
  final $Res Function(_GroupMember) _then;

/// Create a copy of GroupMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? characterId = null,Object? userId = null,Object? role = null,Object? name = null,Object? portraitUrl = freezed,Object? raceName = freezed,Object? className = freezed,Object? level = null,Object? currentHp = null,Object? maxHp = null,Object? temporaryHp = null,Object? isDead = null,}) {
  return _then(_GroupMember(
characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as GroupRole,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,portraitUrl: freezed == portraitUrl ? _self.portraitUrl : portraitUrl // ignore: cast_nullable_to_non_nullable
as String?,raceName: freezed == raceName ? _self.raceName : raceName // ignore: cast_nullable_to_non_nullable
as String?,className: freezed == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,currentHp: null == currentHp ? _self.currentHp : currentHp // ignore: cast_nullable_to_non_nullable
as int,maxHp: null == maxHp ? _self.maxHp : maxHp // ignore: cast_nullable_to_non_nullable
as int,temporaryHp: null == temporaryHp ? _self.temporaryHp : temporaryHp // ignore: cast_nullable_to_non_nullable
as int,isDead: null == isDead ? _self.isDead : isDead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
