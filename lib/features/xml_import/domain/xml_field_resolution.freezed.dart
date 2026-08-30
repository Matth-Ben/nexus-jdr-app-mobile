// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'xml_field_resolution.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$XmlFieldResolution<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlFieldResolution<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'XmlFieldResolution<$T>()';
}


}

/// @nodoc
class $XmlFieldResolutionCopyWith<T,$Res>  {
$XmlFieldResolutionCopyWith(XmlFieldResolution<T> _, $Res Function(XmlFieldResolution<T>) __);
}


/// Adds pattern-matching-related methods to [XmlFieldResolution].
extension XmlFieldResolutionPatterns<T> on XmlFieldResolution<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( XmlFieldResolutionRecognized<T> value)?  recognized,TResult Function( XmlFieldResolutionUnrecognized<T> value)?  unrecognized,TResult Function( XmlFieldResolutionCustom<T> value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case XmlFieldResolutionRecognized() when recognized != null:
return recognized(_that);case XmlFieldResolutionUnrecognized() when unrecognized != null:
return unrecognized(_that);case XmlFieldResolutionCustom() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( XmlFieldResolutionRecognized<T> value)  recognized,required TResult Function( XmlFieldResolutionUnrecognized<T> value)  unrecognized,required TResult Function( XmlFieldResolutionCustom<T> value)  custom,}){
final _that = this;
switch (_that) {
case XmlFieldResolutionRecognized():
return recognized(_that);case XmlFieldResolutionUnrecognized():
return unrecognized(_that);case XmlFieldResolutionCustom():
return custom(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( XmlFieldResolutionRecognized<T> value)?  recognized,TResult? Function( XmlFieldResolutionUnrecognized<T> value)?  unrecognized,TResult? Function( XmlFieldResolutionCustom<T> value)?  custom,}){
final _that = this;
switch (_that) {
case XmlFieldResolutionRecognized() when recognized != null:
return recognized(_that);case XmlFieldResolutionUnrecognized() when unrecognized != null:
return unrecognized(_that);case XmlFieldResolutionCustom() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T value)?  recognized,TResult Function( String rawValue)?  unrecognized,TResult Function( String text)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case XmlFieldResolutionRecognized() when recognized != null:
return recognized(_that.value);case XmlFieldResolutionUnrecognized() when unrecognized != null:
return unrecognized(_that.rawValue);case XmlFieldResolutionCustom() when custom != null:
return custom(_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T value)  recognized,required TResult Function( String rawValue)  unrecognized,required TResult Function( String text)  custom,}) {final _that = this;
switch (_that) {
case XmlFieldResolutionRecognized():
return recognized(_that.value);case XmlFieldResolutionUnrecognized():
return unrecognized(_that.rawValue);case XmlFieldResolutionCustom():
return custom(_that.text);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T value)?  recognized,TResult? Function( String rawValue)?  unrecognized,TResult? Function( String text)?  custom,}) {final _that = this;
switch (_that) {
case XmlFieldResolutionRecognized() when recognized != null:
return recognized(_that.value);case XmlFieldResolutionUnrecognized() when unrecognized != null:
return unrecognized(_that.rawValue);case XmlFieldResolutionCustom() when custom != null:
return custom(_that.text);case _:
  return null;

}
}

}

/// @nodoc


class XmlFieldResolutionRecognized<T> extends XmlFieldResolution<T> {
  const XmlFieldResolutionRecognized(this.value): super._();
  

 final  T value;

/// Create a copy of XmlFieldResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlFieldResolutionRecognizedCopyWith<T, XmlFieldResolutionRecognized<T>> get copyWith => _$XmlFieldResolutionRecognizedCopyWithImpl<T, XmlFieldResolutionRecognized<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlFieldResolutionRecognized<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'XmlFieldResolution<$T>.recognized(value: $value)';
}


}

/// @nodoc
abstract mixin class $XmlFieldResolutionRecognizedCopyWith<T,$Res> implements $XmlFieldResolutionCopyWith<T, $Res> {
  factory $XmlFieldResolutionRecognizedCopyWith(XmlFieldResolutionRecognized<T> value, $Res Function(XmlFieldResolutionRecognized<T>) _then) = _$XmlFieldResolutionRecognizedCopyWithImpl;
@useResult
$Res call({
 T value
});




}
/// @nodoc
class _$XmlFieldResolutionRecognizedCopyWithImpl<T,$Res>
    implements $XmlFieldResolutionRecognizedCopyWith<T, $Res> {
  _$XmlFieldResolutionRecognizedCopyWithImpl(this._self, this._then);

  final XmlFieldResolutionRecognized<T> _self;
  final $Res Function(XmlFieldResolutionRecognized<T>) _then;

/// Create a copy of XmlFieldResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(XmlFieldResolutionRecognized<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class XmlFieldResolutionUnrecognized<T> extends XmlFieldResolution<T> {
  const XmlFieldResolutionUnrecognized(this.rawValue): super._();
  

 final  String rawValue;

/// Create a copy of XmlFieldResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlFieldResolutionUnrecognizedCopyWith<T, XmlFieldResolutionUnrecognized<T>> get copyWith => _$XmlFieldResolutionUnrecognizedCopyWithImpl<T, XmlFieldResolutionUnrecognized<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlFieldResolutionUnrecognized<T>&&(identical(other.rawValue, rawValue) || other.rawValue == rawValue));
}


@override
int get hashCode => Object.hash(runtimeType,rawValue);

@override
String toString() {
  return 'XmlFieldResolution<$T>.unrecognized(rawValue: $rawValue)';
}


}

/// @nodoc
abstract mixin class $XmlFieldResolutionUnrecognizedCopyWith<T,$Res> implements $XmlFieldResolutionCopyWith<T, $Res> {
  factory $XmlFieldResolutionUnrecognizedCopyWith(XmlFieldResolutionUnrecognized<T> value, $Res Function(XmlFieldResolutionUnrecognized<T>) _then) = _$XmlFieldResolutionUnrecognizedCopyWithImpl;
@useResult
$Res call({
 String rawValue
});




}
/// @nodoc
class _$XmlFieldResolutionUnrecognizedCopyWithImpl<T,$Res>
    implements $XmlFieldResolutionUnrecognizedCopyWith<T, $Res> {
  _$XmlFieldResolutionUnrecognizedCopyWithImpl(this._self, this._then);

  final XmlFieldResolutionUnrecognized<T> _self;
  final $Res Function(XmlFieldResolutionUnrecognized<T>) _then;

/// Create a copy of XmlFieldResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rawValue = null,}) {
  return _then(XmlFieldResolutionUnrecognized<T>(
null == rawValue ? _self.rawValue : rawValue // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class XmlFieldResolutionCustom<T> extends XmlFieldResolution<T> {
  const XmlFieldResolutionCustom(this.text): super._();
  

 final  String text;

/// Create a copy of XmlFieldResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlFieldResolutionCustomCopyWith<T, XmlFieldResolutionCustom<T>> get copyWith => _$XmlFieldResolutionCustomCopyWithImpl<T, XmlFieldResolutionCustom<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlFieldResolutionCustom<T>&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'XmlFieldResolution<$T>.custom(text: $text)';
}


}

/// @nodoc
abstract mixin class $XmlFieldResolutionCustomCopyWith<T,$Res> implements $XmlFieldResolutionCopyWith<T, $Res> {
  factory $XmlFieldResolutionCustomCopyWith(XmlFieldResolutionCustom<T> value, $Res Function(XmlFieldResolutionCustom<T>) _then) = _$XmlFieldResolutionCustomCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$XmlFieldResolutionCustomCopyWithImpl<T,$Res>
    implements $XmlFieldResolutionCustomCopyWith<T, $Res> {
  _$XmlFieldResolutionCustomCopyWithImpl(this._self, this._then);

  final XmlFieldResolutionCustom<T> _self;
  final $Res Function(XmlFieldResolutionCustom<T>) _then;

/// Create a copy of XmlFieldResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(XmlFieldResolutionCustom<T>(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
