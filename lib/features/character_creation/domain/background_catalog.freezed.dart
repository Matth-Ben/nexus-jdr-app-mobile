// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'background_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackgroundCatalog {

 List<BackgroundOption> get backgrounds;
/// Create a copy of BackgroundCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundCatalogCopyWith<BackgroundCatalog> get copyWith => _$BackgroundCatalogCopyWithImpl<BackgroundCatalog>(this as BackgroundCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundCatalog&&const DeepCollectionEquality().equals(other.backgrounds, backgrounds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(backgrounds));

@override
String toString() {
  return 'BackgroundCatalog(backgrounds: $backgrounds)';
}


}

/// @nodoc
abstract mixin class $BackgroundCatalogCopyWith<$Res>  {
  factory $BackgroundCatalogCopyWith(BackgroundCatalog value, $Res Function(BackgroundCatalog) _then) = _$BackgroundCatalogCopyWithImpl;
@useResult
$Res call({
 List<BackgroundOption> backgrounds
});




}
/// @nodoc
class _$BackgroundCatalogCopyWithImpl<$Res>
    implements $BackgroundCatalogCopyWith<$Res> {
  _$BackgroundCatalogCopyWithImpl(this._self, this._then);

  final BackgroundCatalog _self;
  final $Res Function(BackgroundCatalog) _then;

/// Create a copy of BackgroundCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backgrounds = null,}) {
  return _then(BackgroundCatalog(
backgrounds: null == backgrounds ? _self.backgrounds : backgrounds // ignore: cast_nullable_to_non_nullable
as List<BackgroundOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [BackgroundCatalog].
extension BackgroundCatalogPatterns on BackgroundCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackgroundCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackgroundCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackgroundCatalog value)  $default,){
final _that = this;
switch (_that) {
case _BackgroundCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackgroundCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _BackgroundCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BackgroundOption> backgrounds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackgroundCatalog() when $default != null:
return $default(_that.backgrounds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BackgroundOption> backgrounds)  $default,) {final _that = this;
switch (_that) {
case _BackgroundCatalog():
return $default(_that.backgrounds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BackgroundOption> backgrounds)?  $default,) {final _that = this;
switch (_that) {
case _BackgroundCatalog() when $default != null:
return $default(_that.backgrounds);case _:
  return null;

}
}

}

/// @nodoc


class _BackgroundCatalog implements BackgroundCatalog {
  const _BackgroundCatalog({required  List<BackgroundOption> backgrounds}): _backgrounds = backgrounds;
  

 final  List<BackgroundOption> _backgrounds;
@override List<BackgroundOption> get backgrounds {
  if (_backgrounds is EqualUnmodifiableListView) return _backgrounds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backgrounds);
}


/// Create a copy of BackgroundCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackgroundCatalogCopyWith<_BackgroundCatalog> get copyWith => __$BackgroundCatalogCopyWithImpl<_BackgroundCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackgroundCatalog&&const DeepCollectionEquality().equals(other._backgrounds, _backgrounds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_backgrounds));

@override
String toString() {
  return 'BackgroundCatalog(backgrounds: $backgrounds)';
}


}

/// @nodoc
abstract mixin class _$BackgroundCatalogCopyWith<$Res> implements $BackgroundCatalogCopyWith<$Res> {
  factory _$BackgroundCatalogCopyWith(_BackgroundCatalog value, $Res Function(_BackgroundCatalog) _then) = __$BackgroundCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<BackgroundOption> backgrounds
});




}
/// @nodoc
class __$BackgroundCatalogCopyWithImpl<$Res>
    implements _$BackgroundCatalogCopyWith<$Res> {
  __$BackgroundCatalogCopyWithImpl(this._self, this._then);

  final _BackgroundCatalog _self;
  final $Res Function(_BackgroundCatalog) _then;

/// Create a copy of BackgroundCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? backgrounds = null,}) {
  return _then(_BackgroundCatalog(
backgrounds: null == backgrounds ? _self._backgrounds : backgrounds // ignore: cast_nullable_to_non_nullable
as List<BackgroundOption>,
  ));
}


}

// dart format on
