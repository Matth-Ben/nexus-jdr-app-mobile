// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_adventure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CharacterAdventure {

 String get characterCampaignId; String get storyId; String get storyTitle; String? get storyCoverUrl;
/// Create a copy of CharacterAdventure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterAdventureCopyWith<CharacterAdventure> get copyWith => _$CharacterAdventureCopyWithImpl<CharacterAdventure>(this as CharacterAdventure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterAdventure&&(identical(other.characterCampaignId, characterCampaignId) || other.characterCampaignId == characterCampaignId)&&(identical(other.storyId, storyId) || other.storyId == storyId)&&(identical(other.storyTitle, storyTitle) || other.storyTitle == storyTitle)&&(identical(other.storyCoverUrl, storyCoverUrl) || other.storyCoverUrl == storyCoverUrl));
}


@override
int get hashCode => Object.hash(runtimeType,characterCampaignId,storyId,storyTitle,storyCoverUrl);

@override
String toString() {
  return 'CharacterAdventure(characterCampaignId: $characterCampaignId, storyId: $storyId, storyTitle: $storyTitle, storyCoverUrl: $storyCoverUrl)';
}


}

/// @nodoc
abstract mixin class $CharacterAdventureCopyWith<$Res>  {
  factory $CharacterAdventureCopyWith(CharacterAdventure value, $Res Function(CharacterAdventure) _then) = _$CharacterAdventureCopyWithImpl;
@useResult
$Res call({
 String characterCampaignId, String storyId, String storyTitle, String? storyCoverUrl
});




}
/// @nodoc
class _$CharacterAdventureCopyWithImpl<$Res>
    implements $CharacterAdventureCopyWith<$Res> {
  _$CharacterAdventureCopyWithImpl(this._self, this._then);

  final CharacterAdventure _self;
  final $Res Function(CharacterAdventure) _then;

/// Create a copy of CharacterAdventure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? characterCampaignId = null,Object? storyId = null,Object? storyTitle = null,Object? storyCoverUrl = freezed,}) {
  return _then(CharacterAdventure(
characterCampaignId: null == characterCampaignId ? _self.characterCampaignId : characterCampaignId // ignore: cast_nullable_to_non_nullable
as String,storyId: null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,storyTitle: null == storyTitle ? _self.storyTitle : storyTitle // ignore: cast_nullable_to_non_nullable
as String,storyCoverUrl: freezed == storyCoverUrl ? _self.storyCoverUrl : storyCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterAdventure].
extension CharacterAdventurePatterns on CharacterAdventure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterAdventure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterAdventure() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterAdventure value)  $default,){
final _that = this;
switch (_that) {
case _CharacterAdventure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterAdventure value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterAdventure() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String characterCampaignId,  String storyId,  String storyTitle,  String? storyCoverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterAdventure() when $default != null:
return $default(_that.characterCampaignId,_that.storyId,_that.storyTitle,_that.storyCoverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String characterCampaignId,  String storyId,  String storyTitle,  String? storyCoverUrl)  $default,) {final _that = this;
switch (_that) {
case _CharacterAdventure():
return $default(_that.characterCampaignId,_that.storyId,_that.storyTitle,_that.storyCoverUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String characterCampaignId,  String storyId,  String storyTitle,  String? storyCoverUrl)?  $default,) {final _that = this;
switch (_that) {
case _CharacterAdventure() when $default != null:
return $default(_that.characterCampaignId,_that.storyId,_that.storyTitle,_that.storyCoverUrl);case _:
  return null;

}
}

}

/// @nodoc


class _CharacterAdventure implements CharacterAdventure {
  const _CharacterAdventure({required this.characterCampaignId, required this.storyId, required this.storyTitle, this.storyCoverUrl});
  

@override final  String characterCampaignId;
@override final  String storyId;
@override final  String storyTitle;
@override final  String? storyCoverUrl;

/// Create a copy of CharacterAdventure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterAdventureCopyWith<_CharacterAdventure> get copyWith => __$CharacterAdventureCopyWithImpl<_CharacterAdventure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterAdventure&&(identical(other.characterCampaignId, characterCampaignId) || other.characterCampaignId == characterCampaignId)&&(identical(other.storyId, storyId) || other.storyId == storyId)&&(identical(other.storyTitle, storyTitle) || other.storyTitle == storyTitle)&&(identical(other.storyCoverUrl, storyCoverUrl) || other.storyCoverUrl == storyCoverUrl));
}


@override
int get hashCode => Object.hash(runtimeType,characterCampaignId,storyId,storyTitle,storyCoverUrl);

@override
String toString() {
  return 'CharacterAdventure(characterCampaignId: $characterCampaignId, storyId: $storyId, storyTitle: $storyTitle, storyCoverUrl: $storyCoverUrl)';
}


}

/// @nodoc
abstract mixin class _$CharacterAdventureCopyWith<$Res> implements $CharacterAdventureCopyWith<$Res> {
  factory _$CharacterAdventureCopyWith(_CharacterAdventure value, $Res Function(_CharacterAdventure) _then) = __$CharacterAdventureCopyWithImpl;
@override @useResult
$Res call({
 String characterCampaignId, String storyId, String storyTitle, String? storyCoverUrl
});




}
/// @nodoc
class __$CharacterAdventureCopyWithImpl<$Res>
    implements _$CharacterAdventureCopyWith<$Res> {
  __$CharacterAdventureCopyWithImpl(this._self, this._then);

  final _CharacterAdventure _self;
  final $Res Function(_CharacterAdventure) _then;

/// Create a copy of CharacterAdventure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? characterCampaignId = null,Object? storyId = null,Object? storyTitle = null,Object? storyCoverUrl = freezed,}) {
  return _then(_CharacterAdventure(
characterCampaignId: null == characterCampaignId ? _self.characterCampaignId : characterCampaignId // ignore: cast_nullable_to_non_nullable
as String,storyId: null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,storyTitle: null == storyTitle ? _self.storyTitle : storyTitle // ignore: cast_nullable_to_non_nullable
as String,storyCoverUrl: freezed == storyCoverUrl ? _self.storyCoverUrl : storyCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
