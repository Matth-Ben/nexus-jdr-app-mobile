// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'xml_raw_spell_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$XmlRawSpellEntry {

 int get level; String get name;
/// Create a copy of XmlRawSpellEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlRawSpellEntryCopyWith<XmlRawSpellEntry> get copyWith => _$XmlRawSpellEntryCopyWithImpl<XmlRawSpellEntry>(this as XmlRawSpellEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlRawSpellEntry&&(identical(other.level, level) || other.level == level)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,level,name);

@override
String toString() {
  return 'XmlRawSpellEntry(level: $level, name: $name)';
}


}

/// @nodoc
abstract mixin class $XmlRawSpellEntryCopyWith<$Res>  {
  factory $XmlRawSpellEntryCopyWith(XmlRawSpellEntry value, $Res Function(XmlRawSpellEntry) _then) = _$XmlRawSpellEntryCopyWithImpl;
@useResult
$Res call({
 int level, String name
});




}
/// @nodoc
class _$XmlRawSpellEntryCopyWithImpl<$Res>
    implements $XmlRawSpellEntryCopyWith<$Res> {
  _$XmlRawSpellEntryCopyWithImpl(this._self, this._then);

  final XmlRawSpellEntry _self;
  final $Res Function(XmlRawSpellEntry) _then;

/// Create a copy of XmlRawSpellEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? level = null,Object? name = null,}) {
  return _then(XmlRawSpellEntry(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [XmlRawSpellEntry].
extension XmlRawSpellEntryPatterns on XmlRawSpellEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XmlRawSpellEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XmlRawSpellEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XmlRawSpellEntry value)  $default,){
final _that = this;
switch (_that) {
case _XmlRawSpellEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XmlRawSpellEntry value)?  $default,){
final _that = this;
switch (_that) {
case _XmlRawSpellEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int level,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XmlRawSpellEntry() when $default != null:
return $default(_that.level,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int level,  String name)  $default,) {final _that = this;
switch (_that) {
case _XmlRawSpellEntry():
return $default(_that.level,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int level,  String name)?  $default,) {final _that = this;
switch (_that) {
case _XmlRawSpellEntry() when $default != null:
return $default(_that.level,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _XmlRawSpellEntry implements XmlRawSpellEntry {
  const _XmlRawSpellEntry({required this.level, required this.name});
  

@override final  int level;
@override final  String name;

/// Create a copy of XmlRawSpellEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XmlRawSpellEntryCopyWith<_XmlRawSpellEntry> get copyWith => __$XmlRawSpellEntryCopyWithImpl<_XmlRawSpellEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _XmlRawSpellEntry&&(identical(other.level, level) || other.level == level)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,level,name);

@override
String toString() {
  return 'XmlRawSpellEntry(level: $level, name: $name)';
}


}

/// @nodoc
abstract mixin class _$XmlRawSpellEntryCopyWith<$Res> implements $XmlRawSpellEntryCopyWith<$Res> {
  factory _$XmlRawSpellEntryCopyWith(_XmlRawSpellEntry value, $Res Function(_XmlRawSpellEntry) _then) = __$XmlRawSpellEntryCopyWithImpl;
@override @useResult
$Res call({
 int level, String name
});




}
/// @nodoc
class __$XmlRawSpellEntryCopyWithImpl<$Res>
    implements _$XmlRawSpellEntryCopyWith<$Res> {
  __$XmlRawSpellEntryCopyWithImpl(this._self, this._then);

  final _XmlRawSpellEntry _self;
  final $Res Function(_XmlRawSpellEntry) _then;

/// Create a copy of XmlRawSpellEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? level = null,Object? name = null,}) {
  return _then(_XmlRawSpellEntry(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
