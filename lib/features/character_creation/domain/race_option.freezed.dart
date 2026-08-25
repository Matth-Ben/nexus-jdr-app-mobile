// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'race_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RaceOption {

 int get id; String get name; Map<String, dynamic> get abilityBonuses; List<RaceTrait> get traits;
/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaceOptionCopyWith<RaceOption> get copyWith => _$RaceOptionCopyWithImpl<RaceOption>(this as RaceOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaceOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.abilityBonuses, abilityBonuses)&&const DeepCollectionEquality().equals(other.traits, traits));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(abilityBonuses),const DeepCollectionEquality().hash(traits));

@override
String toString() {
  return 'RaceOption(id: $id, name: $name, abilityBonuses: $abilityBonuses, traits: $traits)';
}


}

/// @nodoc
abstract mixin class $RaceOptionCopyWith<$Res>  {
  factory $RaceOptionCopyWith(RaceOption value, $Res Function(RaceOption) _then) = _$RaceOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, Map<String, dynamic> abilityBonuses, List<RaceTrait> traits
});




}
/// @nodoc
class _$RaceOptionCopyWithImpl<$Res>
    implements $RaceOptionCopyWith<$Res> {
  _$RaceOptionCopyWithImpl(this._self, this._then);

  final RaceOption _self;
  final $Res Function(RaceOption) _then;

/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? abilityBonuses = null,Object? traits = null,}) {
  return _then(RaceOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,abilityBonuses: null == abilityBonuses ? _self.abilityBonuses : abilityBonuses // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,traits: null == traits ? _self.traits : traits // ignore: cast_nullable_to_non_nullable
as List<RaceTrait>,
  ));
}

}


/// Adds pattern-matching-related methods to [RaceOption].
extension RaceOptionPatterns on RaceOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaceOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaceOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaceOption value)  $default,){
final _that = this;
switch (_that) {
case _RaceOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaceOption value)?  $default,){
final _that = this;
switch (_that) {
case _RaceOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaceOption() when $default != null:
return $default(_that.id,_that.name,_that.abilityBonuses,_that.traits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits)  $default,) {final _that = this;
switch (_that) {
case _RaceOption():
return $default(_that.id,_that.name,_that.abilityBonuses,_that.traits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits)?  $default,) {final _that = this;
switch (_that) {
case _RaceOption() when $default != null:
return $default(_that.id,_that.name,_that.abilityBonuses,_that.traits);case _:
  return null;

}
}

}

/// @nodoc


class _RaceOption extends RaceOption {
  const _RaceOption({required this.id, required this.name, required  Map<String, dynamic> abilityBonuses, required  List<RaceTrait> traits}): _abilityBonuses = abilityBonuses,_traits = traits,super._();
  

@override final  int id;
@override final  String name;
 final  Map<String, dynamic> _abilityBonuses;
@override Map<String, dynamic> get abilityBonuses {
  if (_abilityBonuses is EqualUnmodifiableMapView) return _abilityBonuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_abilityBonuses);
}

 final  List<RaceTrait> _traits;
@override List<RaceTrait> get traits {
  if (_traits is EqualUnmodifiableListView) return _traits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_traits);
}


/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaceOptionCopyWith<_RaceOption> get copyWith => __$RaceOptionCopyWithImpl<_RaceOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaceOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._abilityBonuses, _abilityBonuses)&&const DeepCollectionEquality().equals(other._traits, _traits));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_abilityBonuses),const DeepCollectionEquality().hash(_traits));

@override
String toString() {
  return 'RaceOption(id: $id, name: $name, abilityBonuses: $abilityBonuses, traits: $traits)';
}


}

/// @nodoc
abstract mixin class _$RaceOptionCopyWith<$Res> implements $RaceOptionCopyWith<$Res> {
  factory _$RaceOptionCopyWith(_RaceOption value, $Res Function(_RaceOption) _then) = __$RaceOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, Map<String, dynamic> abilityBonuses, List<RaceTrait> traits
});




}
/// @nodoc
class __$RaceOptionCopyWithImpl<$Res>
    implements _$RaceOptionCopyWith<$Res> {
  __$RaceOptionCopyWithImpl(this._self, this._then);

  final _RaceOption _self;
  final $Res Function(_RaceOption) _then;

/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? abilityBonuses = null,Object? traits = null,}) {
  return _then(_RaceOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,abilityBonuses: null == abilityBonuses ? _self._abilityBonuses : abilityBonuses // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,traits: null == traits ? _self._traits : traits // ignore: cast_nullable_to_non_nullable
as List<RaceTrait>,
  ));
}


}

// dart format on
