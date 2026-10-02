// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proficiency_token_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProficiencyTokenDetail {

 List<ProficiencyCatalogWeapon> get weapons; List<ProficiencyCatalogArmor> get armors;
/// Create a copy of ProficiencyTokenDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProficiencyTokenDetailCopyWith<ProficiencyTokenDetail> get copyWith => _$ProficiencyTokenDetailCopyWithImpl<ProficiencyTokenDetail>(this as ProficiencyTokenDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProficiencyTokenDetail&&const DeepCollectionEquality().equals(other.weapons, weapons)&&const DeepCollectionEquality().equals(other.armors, armors));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(weapons),const DeepCollectionEquality().hash(armors));

@override
String toString() {
  return 'ProficiencyTokenDetail(weapons: $weapons, armors: $armors)';
}


}

/// @nodoc
abstract mixin class $ProficiencyTokenDetailCopyWith<$Res>  {
  factory $ProficiencyTokenDetailCopyWith(ProficiencyTokenDetail value, $Res Function(ProficiencyTokenDetail) _then) = _$ProficiencyTokenDetailCopyWithImpl;
@useResult
$Res call({
 List<ProficiencyCatalogWeapon> weapons, List<ProficiencyCatalogArmor> armors
});




}
/// @nodoc
class _$ProficiencyTokenDetailCopyWithImpl<$Res>
    implements $ProficiencyTokenDetailCopyWith<$Res> {
  _$ProficiencyTokenDetailCopyWithImpl(this._self, this._then);

  final ProficiencyTokenDetail _self;
  final $Res Function(ProficiencyTokenDetail) _then;

/// Create a copy of ProficiencyTokenDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weapons = null,Object? armors = null,}) {
  return _then(ProficiencyTokenDetail(
weapons: null == weapons ? _self.weapons : weapons // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogWeapon>,armors: null == armors ? _self.armors : armors // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogArmor>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProficiencyTokenDetail].
extension ProficiencyTokenDetailPatterns on ProficiencyTokenDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProficiencyTokenDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProficiencyTokenDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProficiencyTokenDetail value)  $default,){
final _that = this;
switch (_that) {
case _ProficiencyTokenDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProficiencyTokenDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ProficiencyTokenDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProficiencyCatalogWeapon> weapons,  List<ProficiencyCatalogArmor> armors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProficiencyTokenDetail() when $default != null:
return $default(_that.weapons,_that.armors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProficiencyCatalogWeapon> weapons,  List<ProficiencyCatalogArmor> armors)  $default,) {final _that = this;
switch (_that) {
case _ProficiencyTokenDetail():
return $default(_that.weapons,_that.armors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProficiencyCatalogWeapon> weapons,  List<ProficiencyCatalogArmor> armors)?  $default,) {final _that = this;
switch (_that) {
case _ProficiencyTokenDetail() when $default != null:
return $default(_that.weapons,_that.armors);case _:
  return null;

}
}

}

/// @nodoc


class _ProficiencyTokenDetail implements ProficiencyTokenDetail {
  const _ProficiencyTokenDetail({ List<ProficiencyCatalogWeapon> weapons = const <ProficiencyCatalogWeapon>[],  List<ProficiencyCatalogArmor> armors = const <ProficiencyCatalogArmor>[]}): _weapons = weapons,_armors = armors;
  

 final  List<ProficiencyCatalogWeapon> _weapons;
@override@JsonKey() List<ProficiencyCatalogWeapon> get weapons {
  if (_weapons is EqualUnmodifiableListView) return _weapons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weapons);
}

 final  List<ProficiencyCatalogArmor> _armors;
@override@JsonKey() List<ProficiencyCatalogArmor> get armors {
  if (_armors is EqualUnmodifiableListView) return _armors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_armors);
}


/// Create a copy of ProficiencyTokenDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProficiencyTokenDetailCopyWith<_ProficiencyTokenDetail> get copyWith => __$ProficiencyTokenDetailCopyWithImpl<_ProficiencyTokenDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProficiencyTokenDetail&&const DeepCollectionEquality().equals(other._weapons, _weapons)&&const DeepCollectionEquality().equals(other._armors, _armors));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_weapons),const DeepCollectionEquality().hash(_armors));

@override
String toString() {
  return 'ProficiencyTokenDetail(weapons: $weapons, armors: $armors)';
}


}

/// @nodoc
abstract mixin class _$ProficiencyTokenDetailCopyWith<$Res> implements $ProficiencyTokenDetailCopyWith<$Res> {
  factory _$ProficiencyTokenDetailCopyWith(_ProficiencyTokenDetail value, $Res Function(_ProficiencyTokenDetail) _then) = __$ProficiencyTokenDetailCopyWithImpl;
@override @useResult
$Res call({
 List<ProficiencyCatalogWeapon> weapons, List<ProficiencyCatalogArmor> armors
});




}
/// @nodoc
class __$ProficiencyTokenDetailCopyWithImpl<$Res>
    implements _$ProficiencyTokenDetailCopyWith<$Res> {
  __$ProficiencyTokenDetailCopyWithImpl(this._self, this._then);

  final _ProficiencyTokenDetail _self;
  final $Res Function(_ProficiencyTokenDetail) _then;

/// Create a copy of ProficiencyTokenDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weapons = null,Object? armors = null,}) {
  return _then(_ProficiencyTokenDetail(
weapons: null == weapons ? _self._weapons : weapons // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogWeapon>,armors: null == armors ? _self._armors : armors // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogArmor>,
  ));
}


}

// dart format on
