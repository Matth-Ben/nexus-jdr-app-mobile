// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_story_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JoinStoryResult {

 String get characterCampaignId; String get joinedAt; String get characterId; String get storyId; String get storyTitle; String? get storyCoverUrl;
/// Create a copy of JoinStoryResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinStoryResultCopyWith<JoinStoryResult> get copyWith => _$JoinStoryResultCopyWithImpl<JoinStoryResult>(this as JoinStoryResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinStoryResult&&(identical(other.characterCampaignId, characterCampaignId) || other.characterCampaignId == characterCampaignId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.storyId, storyId) || other.storyId == storyId)&&(identical(other.storyTitle, storyTitle) || other.storyTitle == storyTitle)&&(identical(other.storyCoverUrl, storyCoverUrl) || other.storyCoverUrl == storyCoverUrl));
}


@override
int get hashCode => Object.hash(runtimeType,characterCampaignId,joinedAt,characterId,storyId,storyTitle,storyCoverUrl);

@override
String toString() {
  return 'JoinStoryResult(characterCampaignId: $characterCampaignId, joinedAt: $joinedAt, characterId: $characterId, storyId: $storyId, storyTitle: $storyTitle, storyCoverUrl: $storyCoverUrl)';
}


}

/// @nodoc
abstract mixin class $JoinStoryResultCopyWith<$Res>  {
  factory $JoinStoryResultCopyWith(JoinStoryResult value, $Res Function(JoinStoryResult) _then) = _$JoinStoryResultCopyWithImpl;
@useResult
$Res call({
 String characterCampaignId, String joinedAt, String characterId, String storyId, String storyTitle, String? storyCoverUrl
});




}
/// @nodoc
class _$JoinStoryResultCopyWithImpl<$Res>
    implements $JoinStoryResultCopyWith<$Res> {
  _$JoinStoryResultCopyWithImpl(this._self, this._then);

  final JoinStoryResult _self;
  final $Res Function(JoinStoryResult) _then;

/// Create a copy of JoinStoryResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? characterCampaignId = null,Object? joinedAt = null,Object? characterId = null,Object? storyId = null,Object? storyTitle = null,Object? storyCoverUrl = freezed,}) {
  return _then(JoinStoryResult(
characterCampaignId: null == characterCampaignId ? _self.characterCampaignId : characterCampaignId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String,characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,storyId: null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,storyTitle: null == storyTitle ? _self.storyTitle : storyTitle // ignore: cast_nullable_to_non_nullable
as String,storyCoverUrl: freezed == storyCoverUrl ? _self.storyCoverUrl : storyCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinStoryResult].
extension JoinStoryResultPatterns on JoinStoryResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinStoryResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinStoryResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinStoryResult value)  $default,){
final _that = this;
switch (_that) {
case _JoinStoryResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinStoryResult value)?  $default,){
final _that = this;
switch (_that) {
case _JoinStoryResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String characterCampaignId,  String joinedAt,  String characterId,  String storyId,  String storyTitle,  String? storyCoverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinStoryResult() when $default != null:
return $default(_that.characterCampaignId,_that.joinedAt,_that.characterId,_that.storyId,_that.storyTitle,_that.storyCoverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String characterCampaignId,  String joinedAt,  String characterId,  String storyId,  String storyTitle,  String? storyCoverUrl)  $default,) {final _that = this;
switch (_that) {
case _JoinStoryResult():
return $default(_that.characterCampaignId,_that.joinedAt,_that.characterId,_that.storyId,_that.storyTitle,_that.storyCoverUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String characterCampaignId,  String joinedAt,  String characterId,  String storyId,  String storyTitle,  String? storyCoverUrl)?  $default,) {final _that = this;
switch (_that) {
case _JoinStoryResult() when $default != null:
return $default(_that.characterCampaignId,_that.joinedAt,_that.characterId,_that.storyId,_that.storyTitle,_that.storyCoverUrl);case _:
  return null;

}
}

}

/// @nodoc


class _JoinStoryResult implements JoinStoryResult {
  const _JoinStoryResult({required this.characterCampaignId, required this.joinedAt, required this.characterId, required this.storyId, required this.storyTitle, this.storyCoverUrl});
  

@override final  String characterCampaignId;
@override final  String joinedAt;
@override final  String characterId;
@override final  String storyId;
@override final  String storyTitle;
@override final  String? storyCoverUrl;

/// Create a copy of JoinStoryResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinStoryResultCopyWith<_JoinStoryResult> get copyWith => __$JoinStoryResultCopyWithImpl<_JoinStoryResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinStoryResult&&(identical(other.characterCampaignId, characterCampaignId) || other.characterCampaignId == characterCampaignId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.storyId, storyId) || other.storyId == storyId)&&(identical(other.storyTitle, storyTitle) || other.storyTitle == storyTitle)&&(identical(other.storyCoverUrl, storyCoverUrl) || other.storyCoverUrl == storyCoverUrl));
}


@override
int get hashCode => Object.hash(runtimeType,characterCampaignId,joinedAt,characterId,storyId,storyTitle,storyCoverUrl);

@override
String toString() {
  return 'JoinStoryResult(characterCampaignId: $characterCampaignId, joinedAt: $joinedAt, characterId: $characterId, storyId: $storyId, storyTitle: $storyTitle, storyCoverUrl: $storyCoverUrl)';
}


}

/// @nodoc
abstract mixin class _$JoinStoryResultCopyWith<$Res> implements $JoinStoryResultCopyWith<$Res> {
  factory _$JoinStoryResultCopyWith(_JoinStoryResult value, $Res Function(_JoinStoryResult) _then) = __$JoinStoryResultCopyWithImpl;
@override @useResult
$Res call({
 String characterCampaignId, String joinedAt, String characterId, String storyId, String storyTitle, String? storyCoverUrl
});




}
/// @nodoc
class __$JoinStoryResultCopyWithImpl<$Res>
    implements _$JoinStoryResultCopyWith<$Res> {
  __$JoinStoryResultCopyWithImpl(this._self, this._then);

  final _JoinStoryResult _self;
  final $Res Function(_JoinStoryResult) _then;

/// Create a copy of JoinStoryResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? characterCampaignId = null,Object? joinedAt = null,Object? characterId = null,Object? storyId = null,Object? storyTitle = null,Object? storyCoverUrl = freezed,}) {
  return _then(_JoinStoryResult(
characterCampaignId: null == characterCampaignId ? _self.characterCampaignId : characterCampaignId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String,characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,storyId: null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,storyTitle: null == storyTitle ? _self.storyTitle : storyTitle // ignore: cast_nullable_to_non_nullable
as String,storyCoverUrl: freezed == storyCoverUrl ? _self.storyCoverUrl : storyCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
