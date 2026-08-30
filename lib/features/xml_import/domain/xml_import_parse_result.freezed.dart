// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'xml_import_parse_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$XmlImportParseResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlImportParseResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'XmlImportParseResult()';
}


}

/// @nodoc
class $XmlImportParseResultCopyWith<$Res>  {
$XmlImportParseResultCopyWith(XmlImportParseResult _, $Res Function(XmlImportParseResult) __);
}


/// Adds pattern-matching-related methods to [XmlImportParseResult].
extension XmlImportParseResultPatterns on XmlImportParseResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( XmlImportParseSuccess value)?  success,TResult Function( XmlImportParseFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case XmlImportParseSuccess() when success != null:
return success(_that);case XmlImportParseFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( XmlImportParseSuccess value)  success,required TResult Function( XmlImportParseFailure value)  failure,}){
final _that = this;
switch (_that) {
case XmlImportParseSuccess():
return success(_that);case XmlImportParseFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( XmlImportParseSuccess value)?  success,TResult? Function( XmlImportParseFailure value)?  failure,}){
final _that = this;
switch (_that) {
case XmlImportParseSuccess() when success != null:
return success(_that);case XmlImportParseFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( XmlCharacterImportRaw character)?  success,TResult Function( String message)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case XmlImportParseSuccess() when success != null:
return success(_that.character);case XmlImportParseFailure() when failure != null:
return failure(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( XmlCharacterImportRaw character)  success,required TResult Function( String message)  failure,}) {final _that = this;
switch (_that) {
case XmlImportParseSuccess():
return success(_that.character);case XmlImportParseFailure():
return failure(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( XmlCharacterImportRaw character)?  success,TResult? Function( String message)?  failure,}) {final _that = this;
switch (_that) {
case XmlImportParseSuccess() when success != null:
return success(_that.character);case XmlImportParseFailure() when failure != null:
return failure(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class XmlImportParseSuccess implements XmlImportParseResult {
  const XmlImportParseSuccess(this.character);
  

 final  XmlCharacterImportRaw character;

/// Create a copy of XmlImportParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlImportParseSuccessCopyWith<XmlImportParseSuccess> get copyWith => _$XmlImportParseSuccessCopyWithImpl<XmlImportParseSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlImportParseSuccess&&(identical(other.character, character) || other.character == character));
}


@override
int get hashCode => Object.hash(runtimeType,character);

@override
String toString() {
  return 'XmlImportParseResult.success(character: $character)';
}


}

/// @nodoc
abstract mixin class $XmlImportParseSuccessCopyWith<$Res> implements $XmlImportParseResultCopyWith<$Res> {
  factory $XmlImportParseSuccessCopyWith(XmlImportParseSuccess value, $Res Function(XmlImportParseSuccess) _then) = _$XmlImportParseSuccessCopyWithImpl;
@useResult
$Res call({
 XmlCharacterImportRaw character
});


$XmlCharacterImportRawCopyWith<$Res> get character;

}
/// @nodoc
class _$XmlImportParseSuccessCopyWithImpl<$Res>
    implements $XmlImportParseSuccessCopyWith<$Res> {
  _$XmlImportParseSuccessCopyWithImpl(this._self, this._then);

  final XmlImportParseSuccess _self;
  final $Res Function(XmlImportParseSuccess) _then;

/// Create a copy of XmlImportParseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? character = null,}) {
  return _then(XmlImportParseSuccess(
null == character ? _self.character : character // ignore: cast_nullable_to_non_nullable
as XmlCharacterImportRaw,
  ));
}

/// Create a copy of XmlImportParseResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XmlCharacterImportRawCopyWith<$Res> get character {
  
  return $XmlCharacterImportRawCopyWith<$Res>(_self.character, (value) {
    return _then(_self.copyWith(character: value));
  });
}
}

/// @nodoc


class XmlImportParseFailure implements XmlImportParseResult {
  const XmlImportParseFailure(this.message);
  

 final  String message;

/// Create a copy of XmlImportParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XmlImportParseFailureCopyWith<XmlImportParseFailure> get copyWith => _$XmlImportParseFailureCopyWithImpl<XmlImportParseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XmlImportParseFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'XmlImportParseResult.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $XmlImportParseFailureCopyWith<$Res> implements $XmlImportParseResultCopyWith<$Res> {
  factory $XmlImportParseFailureCopyWith(XmlImportParseFailure value, $Res Function(XmlImportParseFailure) _then) = _$XmlImportParseFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$XmlImportParseFailureCopyWithImpl<$Res>
    implements $XmlImportParseFailureCopyWith<$Res> {
  _$XmlImportParseFailureCopyWithImpl(this._self, this._then);

  final XmlImportParseFailure _self;
  final $Res Function(XmlImportParseFailure) _then;

/// Create a copy of XmlImportParseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(XmlImportParseFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
