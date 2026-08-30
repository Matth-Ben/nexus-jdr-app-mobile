// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'xml_raw_level_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$XmlRawLevelEntry {

 int get level;/// `<hp_brut>` — `0` pour un niveau non encore atteint.
 int get hpBrut;/// `<aug_carac0>`, `<aug_carac1>`, `<aug_carac2>` dans cet ordre —
/// `-1` signifie "aucune augmentation à ce niveau" (hypothèse du
/// document de rétro-ingénierie, non confirmée sur un export avec ASI
/// réelle faute d'échantillon niveau 4+ disponible ; gardée telle
/// quelle, non retraduite ici, pour ne pas figer une interprétation non
/// vérifiée dans le modèle — voir `xml-import-reference-mapping.md`,
/// section "Points non vérifiables en session anonyme").
 List<int> get abilityIncreases;
/// Create a copy of XmlRawLevelEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlRawLevelEntryCopyWith<XmlRawLevelEntry> get copyWith => _$XmlRawLevelEntryCopyWithImpl<XmlRawLevelEntry>(this as XmlRawLevelEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlRawLevelEntry&&(identical(other.level, level) || other.level == level)&&(identical(other.hpBrut, hpBrut) || other.hpBrut == hpBrut)&&const DeepCollectionEquality().equals(other.abilityIncreases, abilityIncreases));
}


@override
int get hashCode => Object.hash(runtimeType,level,hpBrut,const DeepCollectionEquality().hash(abilityIncreases));

@override
String toString() {
  return 'XmlRawLevelEntry(level: $level, hpBrut: $hpBrut, abilityIncreases: $abilityIncreases)';
}


}

/// @nodoc
abstract mixin class $XmlRawLevelEntryCopyWith<$Res>  {
  factory $XmlRawLevelEntryCopyWith(XmlRawLevelEntry value, $Res Function(XmlRawLevelEntry) _then) = _$XmlRawLevelEntryCopyWithImpl;
@useResult
$Res call({
 int level, int hpBrut, List<int> abilityIncreases
});




}
/// @nodoc
class _$XmlRawLevelEntryCopyWithImpl<$Res>
    implements $XmlRawLevelEntryCopyWith<$Res> {
  _$XmlRawLevelEntryCopyWithImpl(this._self, this._then);

  final XmlRawLevelEntry _self;
  final $Res Function(XmlRawLevelEntry) _then;

/// Create a copy of XmlRawLevelEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? level = null,Object? hpBrut = null,Object? abilityIncreases = null,}) {
  return _then(XmlRawLevelEntry(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,hpBrut: null == hpBrut ? _self.hpBrut : hpBrut // ignore: cast_nullable_to_non_nullable
as int,abilityIncreases: null == abilityIncreases ? _self.abilityIncreases : abilityIncreases // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [XmlRawLevelEntry].
extension XmlRawLevelEntryPatterns on XmlRawLevelEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XmlRawLevelEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XmlRawLevelEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XmlRawLevelEntry value)  $default,){
final _that = this;
switch (_that) {
case _XmlRawLevelEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XmlRawLevelEntry value)?  $default,){
final _that = this;
switch (_that) {
case _XmlRawLevelEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int level,  int hpBrut,  List<int> abilityIncreases)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XmlRawLevelEntry() when $default != null:
return $default(_that.level,_that.hpBrut,_that.abilityIncreases);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int level,  int hpBrut,  List<int> abilityIncreases)  $default,) {final _that = this;
switch (_that) {
case _XmlRawLevelEntry():
return $default(_that.level,_that.hpBrut,_that.abilityIncreases);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int level,  int hpBrut,  List<int> abilityIncreases)?  $default,) {final _that = this;
switch (_that) {
case _XmlRawLevelEntry() when $default != null:
return $default(_that.level,_that.hpBrut,_that.abilityIncreases);case _:
  return null;

}
}

}

/// @nodoc


class _XmlRawLevelEntry implements XmlRawLevelEntry {
  const _XmlRawLevelEntry({required this.level, required this.hpBrut, required  List<int> abilityIncreases}): _abilityIncreases = abilityIncreases;
  

@override final  int level;
/// `<hp_brut>` — `0` pour un niveau non encore atteint.
@override final  int hpBrut;
/// `<aug_carac0>`, `<aug_carac1>`, `<aug_carac2>` dans cet ordre —
/// `-1` signifie "aucune augmentation à ce niveau" (hypothèse du
/// document de rétro-ingénierie, non confirmée sur un export avec ASI
/// réelle faute d'échantillon niveau 4+ disponible ; gardée telle
/// quelle, non retraduite ici, pour ne pas figer une interprétation non
/// vérifiée dans le modèle — voir `xml-import-reference-mapping.md`,
/// section "Points non vérifiables en session anonyme").
 final  List<int> _abilityIncreases;
/// `<aug_carac0>`, `<aug_carac1>`, `<aug_carac2>` dans cet ordre —
/// `-1` signifie "aucune augmentation à ce niveau" (hypothèse du
/// document de rétro-ingénierie, non confirmée sur un export avec ASI
/// réelle faute d'échantillon niveau 4+ disponible ; gardée telle
/// quelle, non retraduite ici, pour ne pas figer une interprétation non
/// vérifiée dans le modèle — voir `xml-import-reference-mapping.md`,
/// section "Points non vérifiables en session anonyme").
@override List<int> get abilityIncreases {
  if (_abilityIncreases is EqualUnmodifiableListView) return _abilityIncreases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_abilityIncreases);
}


/// Create a copy of XmlRawLevelEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XmlRawLevelEntryCopyWith<_XmlRawLevelEntry> get copyWith => __$XmlRawLevelEntryCopyWithImpl<_XmlRawLevelEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _XmlRawLevelEntry&&(identical(other.level, level) || other.level == level)&&(identical(other.hpBrut, hpBrut) || other.hpBrut == hpBrut)&&const DeepCollectionEquality().equals(other._abilityIncreases, _abilityIncreases));
}


@override
int get hashCode => Object.hash(runtimeType,level,hpBrut,const DeepCollectionEquality().hash(_abilityIncreases));

@override
String toString() {
  return 'XmlRawLevelEntry(level: $level, hpBrut: $hpBrut, abilityIncreases: $abilityIncreases)';
}


}

/// @nodoc
abstract mixin class _$XmlRawLevelEntryCopyWith<$Res> implements $XmlRawLevelEntryCopyWith<$Res> {
  factory _$XmlRawLevelEntryCopyWith(_XmlRawLevelEntry value, $Res Function(_XmlRawLevelEntry) _then) = __$XmlRawLevelEntryCopyWithImpl;
@override @useResult
$Res call({
 int level, int hpBrut, List<int> abilityIncreases
});




}
/// @nodoc
class __$XmlRawLevelEntryCopyWithImpl<$Res>
    implements _$XmlRawLevelEntryCopyWith<$Res> {
  __$XmlRawLevelEntryCopyWithImpl(this._self, this._then);

  final _XmlRawLevelEntry _self;
  final $Res Function(_XmlRawLevelEntry) _then;

/// Create a copy of XmlRawLevelEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? level = null,Object? hpBrut = null,Object? abilityIncreases = null,}) {
  return _then(_XmlRawLevelEntry(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,hpBrut: null == hpBrut ? _self.hpBrut : hpBrut // ignore: cast_nullable_to_non_nullable
as int,abilityIncreases: null == abilityIncreases ? _self._abilityIncreases : abilityIncreases // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
