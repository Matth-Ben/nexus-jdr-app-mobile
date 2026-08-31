// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoryPreview {

 String get title;/// URL publique déjà résolue (bucket Storage `story-covers`, lecture
/// publique) — jamais le chemin de stockage brut renvoyé par l'edge
/// function (`cover_image_path`), résolu côté dépôt
/// (`data/story_invite_repository.dart`), même principe que
/// `characters.portrait_url`.
 String? get coverUrl;
/// Create a copy of StoryPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryPreviewCopyWith<StoryPreview> get copyWith => _$StoryPreviewCopyWithImpl<StoryPreview>(this as StoryPreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryPreview&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}


@override
int get hashCode => Object.hash(runtimeType,title,coverUrl);

@override
String toString() {
  return 'StoryPreview(title: $title, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class $StoryPreviewCopyWith<$Res>  {
  factory $StoryPreviewCopyWith(StoryPreview value, $Res Function(StoryPreview) _then) = _$StoryPreviewCopyWithImpl;
@useResult
$Res call({
 String title, String? coverUrl
});




}
/// @nodoc
class _$StoryPreviewCopyWithImpl<$Res>
    implements $StoryPreviewCopyWith<$Res> {
  _$StoryPreviewCopyWithImpl(this._self, this._then);

  final StoryPreview _self;
  final $Res Function(StoryPreview) _then;

/// Create a copy of StoryPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? coverUrl = freezed,}) {
  return _then(StoryPreview(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryPreview].
extension StoryPreviewPatterns on StoryPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryPreview value)  $default,){
final _that = this;
switch (_that) {
case _StoryPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryPreview value)?  $default,){
final _that = this;
switch (_that) {
case _StoryPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? coverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryPreview() when $default != null:
return $default(_that.title,_that.coverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? coverUrl)  $default,) {final _that = this;
switch (_that) {
case _StoryPreview():
return $default(_that.title,_that.coverUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? coverUrl)?  $default,) {final _that = this;
switch (_that) {
case _StoryPreview() when $default != null:
return $default(_that.title,_that.coverUrl);case _:
  return null;

}
}

}

/// @nodoc


class _StoryPreview implements StoryPreview {
  const _StoryPreview({required this.title, this.coverUrl});
  

@override final  String title;
/// URL publique déjà résolue (bucket Storage `story-covers`, lecture
/// publique) — jamais le chemin de stockage brut renvoyé par l'edge
/// function (`cover_image_path`), résolu côté dépôt
/// (`data/story_invite_repository.dart`), même principe que
/// `characters.portrait_url`.
@override final  String? coverUrl;

/// Create a copy of StoryPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryPreviewCopyWith<_StoryPreview> get copyWith => __$StoryPreviewCopyWithImpl<_StoryPreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryPreview&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}


@override
int get hashCode => Object.hash(runtimeType,title,coverUrl);

@override
String toString() {
  return 'StoryPreview(title: $title, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class _$StoryPreviewCopyWith<$Res> implements $StoryPreviewCopyWith<$Res> {
  factory _$StoryPreviewCopyWith(_StoryPreview value, $Res Function(_StoryPreview) _then) = __$StoryPreviewCopyWithImpl;
@override @useResult
$Res call({
 String title, String? coverUrl
});




}
/// @nodoc
class __$StoryPreviewCopyWithImpl<$Res>
    implements _$StoryPreviewCopyWith<$Res> {
  __$StoryPreviewCopyWithImpl(this._self, this._then);

  final _StoryPreview _self;
  final $Res Function(_StoryPreview) _then;

/// Create a copy of StoryPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? coverUrl = freezed,}) {
  return _then(_StoryPreview(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
