// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'race_tool_choice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RaceToolChoice {

 int get count; List<String> get choices;
/// Create a copy of RaceToolChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaceToolChoiceCopyWith<RaceToolChoice> get copyWith => _$RaceToolChoiceCopyWithImpl<RaceToolChoice>(this as RaceToolChoice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaceToolChoice&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.choices, choices));
}


@override
int get hashCode => Object.hash(runtimeType,count,const DeepCollectionEquality().hash(choices));

@override
String toString() {
  return 'RaceToolChoice(count: $count, choices: $choices)';
}


}

/// @nodoc
abstract mixin class $RaceToolChoiceCopyWith<$Res>  {
  factory $RaceToolChoiceCopyWith(RaceToolChoice value, $Res Function(RaceToolChoice) _then) = _$RaceToolChoiceCopyWithImpl;
@useResult
$Res call({
 int count, List<String> choices
});




}
/// @nodoc
class _$RaceToolChoiceCopyWithImpl<$Res>
    implements $RaceToolChoiceCopyWith<$Res> {
  _$RaceToolChoiceCopyWithImpl(this._self, this._then);

  final RaceToolChoice _self;
  final $Res Function(RaceToolChoice) _then;

/// Create a copy of RaceToolChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? choices = null,}) {
  return _then(RaceToolChoice(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RaceToolChoice].
extension RaceToolChoicePatterns on RaceToolChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaceToolChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaceToolChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaceToolChoice value)  $default,){
final _that = this;
switch (_that) {
case _RaceToolChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaceToolChoice value)?  $default,){
final _that = this;
switch (_that) {
case _RaceToolChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  List<String> choices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaceToolChoice() when $default != null:
return $default(_that.count,_that.choices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  List<String> choices)  $default,) {final _that = this;
switch (_that) {
case _RaceToolChoice():
return $default(_that.count,_that.choices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  List<String> choices)?  $default,) {final _that = this;
switch (_that) {
case _RaceToolChoice() when $default != null:
return $default(_that.count,_that.choices);case _:
  return null;

}
}

}

/// @nodoc


class _RaceToolChoice implements RaceToolChoice {
  const _RaceToolChoice({required this.count, required  List<String> choices}): _choices = choices;
  

@override final  int count;
 final  List<String> _choices;
@override List<String> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}


/// Create a copy of RaceToolChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaceToolChoiceCopyWith<_RaceToolChoice> get copyWith => __$RaceToolChoiceCopyWithImpl<_RaceToolChoice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaceToolChoice&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._choices, _choices));
}


@override
int get hashCode => Object.hash(runtimeType,count,const DeepCollectionEquality().hash(_choices));

@override
String toString() {
  return 'RaceToolChoice(count: $count, choices: $choices)';
}


}

/// @nodoc
abstract mixin class _$RaceToolChoiceCopyWith<$Res> implements $RaceToolChoiceCopyWith<$Res> {
  factory _$RaceToolChoiceCopyWith(_RaceToolChoice value, $Res Function(_RaceToolChoice) _then) = __$RaceToolChoiceCopyWithImpl;
@override @useResult
$Res call({
 int count, List<String> choices
});




}
/// @nodoc
class __$RaceToolChoiceCopyWithImpl<$Res>
    implements _$RaceToolChoiceCopyWith<$Res> {
  __$RaceToolChoiceCopyWithImpl(this._self, this._then);

  final _RaceToolChoice _self;
  final $Res Function(_RaceToolChoice) _then;

/// Create a copy of RaceToolChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? choices = null,}) {
  return _then(_RaceToolChoice(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
