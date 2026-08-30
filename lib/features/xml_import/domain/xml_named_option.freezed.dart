// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'xml_named_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$XmlNamedOption {

 Object get id; String get name;
/// Create a copy of XmlNamedOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlNamedOptionCopyWith<XmlNamedOption> get copyWith => _$XmlNamedOptionCopyWithImpl<XmlNamedOption>(this as XmlNamedOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlNamedOption&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(id),name);

@override
String toString() {
  return 'XmlNamedOption(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $XmlNamedOptionCopyWith<$Res>  {
  factory $XmlNamedOptionCopyWith(XmlNamedOption value, $Res Function(XmlNamedOption) _then) = _$XmlNamedOptionCopyWithImpl;
@useResult
$Res call({
 Object id, String name
});




}
/// @nodoc
class _$XmlNamedOptionCopyWithImpl<$Res>
    implements $XmlNamedOptionCopyWith<$Res> {
  _$XmlNamedOptionCopyWithImpl(this._self, this._then);

  final XmlNamedOption _self;
  final $Res Function(XmlNamedOption) _then;

/// Create a copy of XmlNamedOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(XmlNamedOption(
id: null == id ? _self.id : id ,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [XmlNamedOption].
extension XmlNamedOptionPatterns on XmlNamedOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XmlNamedOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XmlNamedOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XmlNamedOption value)  $default,){
final _that = this;
switch (_that) {
case _XmlNamedOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XmlNamedOption value)?  $default,){
final _that = this;
switch (_that) {
case _XmlNamedOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XmlNamedOption() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object id,  String name)  $default,) {final _that = this;
switch (_that) {
case _XmlNamedOption():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _XmlNamedOption() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _XmlNamedOption implements XmlNamedOption {
  const _XmlNamedOption({required this.id, required this.name});
  

@override final  Object id;
@override final  String name;

/// Create a copy of XmlNamedOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XmlNamedOptionCopyWith<_XmlNamedOption> get copyWith => __$XmlNamedOptionCopyWithImpl<_XmlNamedOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _XmlNamedOption&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(id),name);

@override
String toString() {
  return 'XmlNamedOption(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$XmlNamedOptionCopyWith<$Res> implements $XmlNamedOptionCopyWith<$Res> {
  factory _$XmlNamedOptionCopyWith(_XmlNamedOption value, $Res Function(_XmlNamedOption) _then) = __$XmlNamedOptionCopyWithImpl;
@override @useResult
$Res call({
 Object id, String name
});




}
/// @nodoc
class __$XmlNamedOptionCopyWithImpl<$Res>
    implements _$XmlNamedOptionCopyWith<$Res> {
  __$XmlNamedOptionCopyWithImpl(this._self, this._then);

  final _XmlNamedOption _self;
  final $Res Function(_XmlNamedOption) _then;

/// Create a copy of XmlNamedOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_XmlNamedOption(
id: null == id ? _self.id : id ,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
