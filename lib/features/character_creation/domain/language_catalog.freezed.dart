// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'language_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LanguageCatalog {

 List<LanguageOption> get languages;
/// Create a copy of LanguageCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanguageCatalogCopyWith<LanguageCatalog> get copyWith => _$LanguageCatalogCopyWithImpl<LanguageCatalog>(this as LanguageCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanguageCatalog&&const DeepCollectionEquality().equals(other.languages, languages));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(languages));

@override
String toString() {
  return 'LanguageCatalog(languages: $languages)';
}


}

/// @nodoc
abstract mixin class $LanguageCatalogCopyWith<$Res>  {
  factory $LanguageCatalogCopyWith(LanguageCatalog value, $Res Function(LanguageCatalog) _then) = _$LanguageCatalogCopyWithImpl;
@useResult
$Res call({
 List<LanguageOption> languages
});




}
/// @nodoc
class _$LanguageCatalogCopyWithImpl<$Res>
    implements $LanguageCatalogCopyWith<$Res> {
  _$LanguageCatalogCopyWithImpl(this._self, this._then);

  final LanguageCatalog _self;
  final $Res Function(LanguageCatalog) _then;

/// Create a copy of LanguageCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? languages = null,}) {
  return _then(LanguageCatalog(
languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<LanguageOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [LanguageCatalog].
extension LanguageCatalogPatterns on LanguageCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LanguageCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LanguageCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LanguageCatalog value)  $default,){
final _that = this;
switch (_that) {
case _LanguageCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LanguageCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _LanguageCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LanguageOption> languages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LanguageCatalog() when $default != null:
return $default(_that.languages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LanguageOption> languages)  $default,) {final _that = this;
switch (_that) {
case _LanguageCatalog():
return $default(_that.languages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LanguageOption> languages)?  $default,) {final _that = this;
switch (_that) {
case _LanguageCatalog() when $default != null:
return $default(_that.languages);case _:
  return null;

}
}

}

/// @nodoc


class _LanguageCatalog implements LanguageCatalog {
  const _LanguageCatalog({required  List<LanguageOption> languages}): _languages = languages;
  

 final  List<LanguageOption> _languages;
@override List<LanguageOption> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}


/// Create a copy of LanguageCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanguageCatalogCopyWith<_LanguageCatalog> get copyWith => __$LanguageCatalogCopyWithImpl<_LanguageCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LanguageCatalog&&const DeepCollectionEquality().equals(other._languages, _languages));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_languages));

@override
String toString() {
  return 'LanguageCatalog(languages: $languages)';
}


}

/// @nodoc
abstract mixin class _$LanguageCatalogCopyWith<$Res> implements $LanguageCatalogCopyWith<$Res> {
  factory _$LanguageCatalogCopyWith(_LanguageCatalog value, $Res Function(_LanguageCatalog) _then) = __$LanguageCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<LanguageOption> languages
});




}
/// @nodoc
class __$LanguageCatalogCopyWithImpl<$Res>
    implements _$LanguageCatalogCopyWith<$Res> {
  __$LanguageCatalogCopyWithImpl(this._self, this._then);

  final _LanguageCatalog _self;
  final $Res Function(_LanguageCatalog) _then;

/// Create a copy of LanguageCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? languages = null,}) {
  return _then(_LanguageCatalog(
languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<LanguageOption>,
  ));
}


}

// dart format on
