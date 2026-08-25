// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subrace_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubraceOption {

 int get id; int get raceId; String get name; Map<String, dynamic> get abilityBonuses; List<RaceTrait> get traits;
/// Create a copy of SubraceOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubraceOptionCopyWith<SubraceOption> get copyWith => _$SubraceOptionCopyWithImpl<SubraceOption>(this as SubraceOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubraceOption&&(identical(other.id, id) || other.id == id)&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.abilityBonuses, abilityBonuses)&&const DeepCollectionEquality().equals(other.traits, traits));
}


@override
int get hashCode => Object.hash(runtimeType,id,raceId,name,const DeepCollectionEquality().hash(abilityBonuses),const DeepCollectionEquality().hash(traits));

@override
String toString() {
  return 'SubraceOption(id: $id, raceId: $raceId, name: $name, abilityBonuses: $abilityBonuses, traits: $traits)';
}


}

/// @nodoc
abstract mixin class $SubraceOptionCopyWith<$Res>  {
  factory $SubraceOptionCopyWith(SubraceOption value, $Res Function(SubraceOption) _then) = _$SubraceOptionCopyWithImpl;
@useResult
$Res call({
 int id, int raceId, String name, Map<String, dynamic> abilityBonuses, List<RaceTrait> traits
});




}
/// @nodoc
class _$SubraceOptionCopyWithImpl<$Res>
    implements $SubraceOptionCopyWith<$Res> {
  _$SubraceOptionCopyWithImpl(this._self, this._then);

  final SubraceOption _self;
  final $Res Function(SubraceOption) _then;

/// Create a copy of SubraceOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? raceId = null,Object? name = null,Object? abilityBonuses = null,Object? traits = null,}) {
  return _then(SubraceOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,raceId: null == raceId ? _self.raceId : raceId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,abilityBonuses: null == abilityBonuses ? _self.abilityBonuses : abilityBonuses // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,traits: null == traits ? _self.traits : traits // ignore: cast_nullable_to_non_nullable
as List<RaceTrait>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubraceOption].
extension SubraceOptionPatterns on SubraceOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubraceOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubraceOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubraceOption value)  $default,){
final _that = this;
switch (_that) {
case _SubraceOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubraceOption value)?  $default,){
final _that = this;
switch (_that) {
case _SubraceOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int raceId,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubraceOption() when $default != null:
return $default(_that.id,_that.raceId,_that.name,_that.abilityBonuses,_that.traits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int raceId,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits)  $default,) {final _that = this;
switch (_that) {
case _SubraceOption():
return $default(_that.id,_that.raceId,_that.name,_that.abilityBonuses,_that.traits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int raceId,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits)?  $default,) {final _that = this;
switch (_that) {
case _SubraceOption() when $default != null:
return $default(_that.id,_that.raceId,_that.name,_that.abilityBonuses,_that.traits);case _:
  return null;

}
}

}

/// @nodoc


class _SubraceOption extends SubraceOption {
  const _SubraceOption({required this.id, required this.raceId, required this.name, required  Map<String, dynamic> abilityBonuses, required  List<RaceTrait> traits}): _abilityBonuses = abilityBonuses,_traits = traits,super._();
  

@override final  int id;
@override final  int raceId;
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


/// Create a copy of SubraceOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubraceOptionCopyWith<_SubraceOption> get copyWith => __$SubraceOptionCopyWithImpl<_SubraceOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubraceOption&&(identical(other.id, id) || other.id == id)&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._abilityBonuses, _abilityBonuses)&&const DeepCollectionEquality().equals(other._traits, _traits));
}


@override
int get hashCode => Object.hash(runtimeType,id,raceId,name,const DeepCollectionEquality().hash(_abilityBonuses),const DeepCollectionEquality().hash(_traits));

@override
String toString() {
  return 'SubraceOption(id: $id, raceId: $raceId, name: $name, abilityBonuses: $abilityBonuses, traits: $traits)';
}


}

/// @nodoc
abstract mixin class _$SubraceOptionCopyWith<$Res> implements $SubraceOptionCopyWith<$Res> {
  factory _$SubraceOptionCopyWith(_SubraceOption value, $Res Function(_SubraceOption) _then) = __$SubraceOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, int raceId, String name, Map<String, dynamic> abilityBonuses, List<RaceTrait> traits
});




}
/// @nodoc
class __$SubraceOptionCopyWithImpl<$Res>
    implements _$SubraceOptionCopyWith<$Res> {
  __$SubraceOptionCopyWithImpl(this._self, this._then);

  final _SubraceOption _self;
  final $Res Function(_SubraceOption) _then;

/// Create a copy of SubraceOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? raceId = null,Object? name = null,Object? abilityBonuses = null,Object? traits = null,}) {
  return _then(_SubraceOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,raceId: null == raceId ? _self.raceId : raceId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,abilityBonuses: null == abilityBonuses ? _self._abilityBonuses : abilityBonuses // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,traits: null == traits ? _self._traits : traits // ignore: cast_nullable_to_non_nullable
as List<RaceTrait>,
  ));
}


}

// dart format on
