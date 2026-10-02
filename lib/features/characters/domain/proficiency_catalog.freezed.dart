// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proficiency_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProficiencyCatalogWeapon {

/// `items.id`.
 int get id;/// Nom français (`translations`, `entity_type = 'item'`).
 String get name;/// `weapon_properties.damage_dice` (ex. « 1d8 »), `null` pour une arme
/// sans dé de dégâts direct (ex. le filet).
 String? get damageDice;/// `weapon_properties.damage_type` (ex. « tranchant »).
 String? get damageType;/// `weapon_properties.properties` (ex. « légère », « finesse »).
 List<String> get properties;
/// Create a copy of ProficiencyCatalogWeapon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProficiencyCatalogWeaponCopyWith<ProficiencyCatalogWeapon> get copyWith => _$ProficiencyCatalogWeaponCopyWithImpl<ProficiencyCatalogWeapon>(this as ProficiencyCatalogWeapon, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProficiencyCatalogWeapon&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.damageDice, damageDice) || other.damageDice == damageDice)&&(identical(other.damageType, damageType) || other.damageType == damageType)&&const DeepCollectionEquality().equals(other.properties, properties));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,damageDice,damageType,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'ProficiencyCatalogWeapon(id: $id, name: $name, damageDice: $damageDice, damageType: $damageType, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $ProficiencyCatalogWeaponCopyWith<$Res>  {
  factory $ProficiencyCatalogWeaponCopyWith(ProficiencyCatalogWeapon value, $Res Function(ProficiencyCatalogWeapon) _then) = _$ProficiencyCatalogWeaponCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? damageDice, String? damageType, List<String> properties
});




}
/// @nodoc
class _$ProficiencyCatalogWeaponCopyWithImpl<$Res>
    implements $ProficiencyCatalogWeaponCopyWith<$Res> {
  _$ProficiencyCatalogWeaponCopyWithImpl(this._self, this._then);

  final ProficiencyCatalogWeapon _self;
  final $Res Function(ProficiencyCatalogWeapon) _then;

/// Create a copy of ProficiencyCatalogWeapon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? damageDice = freezed,Object? damageType = freezed,Object? properties = null,}) {
  return _then(ProficiencyCatalogWeapon(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,damageDice: freezed == damageDice ? _self.damageDice : damageDice // ignore: cast_nullable_to_non_nullable
as String?,damageType: freezed == damageType ? _self.damageType : damageType // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProficiencyCatalogWeapon].
extension ProficiencyCatalogWeaponPatterns on ProficiencyCatalogWeapon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProficiencyCatalogWeapon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProficiencyCatalogWeapon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProficiencyCatalogWeapon value)  $default,){
final _that = this;
switch (_that) {
case _ProficiencyCatalogWeapon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProficiencyCatalogWeapon value)?  $default,){
final _that = this;
switch (_that) {
case _ProficiencyCatalogWeapon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? damageDice,  String? damageType,  List<String> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProficiencyCatalogWeapon() when $default != null:
return $default(_that.id,_that.name,_that.damageDice,_that.damageType,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? damageDice,  String? damageType,  List<String> properties)  $default,) {final _that = this;
switch (_that) {
case _ProficiencyCatalogWeapon():
return $default(_that.id,_that.name,_that.damageDice,_that.damageType,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? damageDice,  String? damageType,  List<String> properties)?  $default,) {final _that = this;
switch (_that) {
case _ProficiencyCatalogWeapon() when $default != null:
return $default(_that.id,_that.name,_that.damageDice,_that.damageType,_that.properties);case _:
  return null;

}
}

}

/// @nodoc


class _ProficiencyCatalogWeapon implements ProficiencyCatalogWeapon {
  const _ProficiencyCatalogWeapon({required this.id, required this.name, this.damageDice, this.damageType,  List<String> properties = const <String>[]}): _properties = properties;
  

/// `items.id`.
@override final  int id;
/// Nom français (`translations`, `entity_type = 'item'`).
@override final  String name;
/// `weapon_properties.damage_dice` (ex. « 1d8 »), `null` pour une arme
/// sans dé de dégâts direct (ex. le filet).
@override final  String? damageDice;
/// `weapon_properties.damage_type` (ex. « tranchant »).
@override final  String? damageType;
/// `weapon_properties.properties` (ex. « légère », « finesse »).
 final  List<String> _properties;
/// `weapon_properties.properties` (ex. « légère », « finesse »).
@override@JsonKey() List<String> get properties {
  if (_properties is EqualUnmodifiableListView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_properties);
}


/// Create a copy of ProficiencyCatalogWeapon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProficiencyCatalogWeaponCopyWith<_ProficiencyCatalogWeapon> get copyWith => __$ProficiencyCatalogWeaponCopyWithImpl<_ProficiencyCatalogWeapon>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProficiencyCatalogWeapon&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.damageDice, damageDice) || other.damageDice == damageDice)&&(identical(other.damageType, damageType) || other.damageType == damageType)&&const DeepCollectionEquality().equals(other._properties, _properties));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,damageDice,damageType,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'ProficiencyCatalogWeapon(id: $id, name: $name, damageDice: $damageDice, damageType: $damageType, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$ProficiencyCatalogWeaponCopyWith<$Res> implements $ProficiencyCatalogWeaponCopyWith<$Res> {
  factory _$ProficiencyCatalogWeaponCopyWith(_ProficiencyCatalogWeapon value, $Res Function(_ProficiencyCatalogWeapon) _then) = __$ProficiencyCatalogWeaponCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? damageDice, String? damageType, List<String> properties
});




}
/// @nodoc
class __$ProficiencyCatalogWeaponCopyWithImpl<$Res>
    implements _$ProficiencyCatalogWeaponCopyWith<$Res> {
  __$ProficiencyCatalogWeaponCopyWithImpl(this._self, this._then);

  final _ProficiencyCatalogWeapon _self;
  final $Res Function(_ProficiencyCatalogWeapon) _then;

/// Create a copy of ProficiencyCatalogWeapon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? damageDice = freezed,Object? damageType = freezed,Object? properties = null,}) {
  return _then(_ProficiencyCatalogWeapon(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,damageDice: freezed == damageDice ? _self.damageDice : damageDice // ignore: cast_nullable_to_non_nullable
as String?,damageType: freezed == damageType ? _self.damageType : damageType // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$ProficiencyCatalogArmor {

/// `items.id`.
 int get id;/// Nom français (`translations`, `entity_type = 'item'`).
 String get name;/// `items.category` ('armure' ou 'bouclier') — distingue le gabarit
/// d'affichage du panneau "Infos" (armure complète vs bouclier "CA"
/// seule), voir `proficiency_detail_panel.dart::_ArmorDetailRow`.
 String get category;/// `armor_properties.ac_base` — pour un bouclier, un bonus (+2) plutôt
/// qu'une CA de base à proprement parler, même convention que
/// `CharacterInventoryArmorProperties.acBase`.
 int get acBase;/// `armor_properties.ac_dex_bonus` ('aucun'/'max_2'/'illimite') — voir
/// `ArmorProficiencyCategoryRules.categoryFor` pour la dérivation de
/// catégorie, `InventoryArmorDexBonusFormatter` pour son libellé FR.
 String get acDexBonus;/// `armor_properties.strength_requirement`, `null` si aucune force
/// minimale requise — omis du panneau "Infos" dans ce cas.
 int? get strengthRequirement; bool get stealthDisadvantage;
/// Create a copy of ProficiencyCatalogArmor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProficiencyCatalogArmorCopyWith<ProficiencyCatalogArmor> get copyWith => _$ProficiencyCatalogArmorCopyWithImpl<ProficiencyCatalogArmor>(this as ProficiencyCatalogArmor, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProficiencyCatalogArmor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.acBase, acBase) || other.acBase == acBase)&&(identical(other.acDexBonus, acDexBonus) || other.acDexBonus == acDexBonus)&&(identical(other.strengthRequirement, strengthRequirement) || other.strengthRequirement == strengthRequirement)&&(identical(other.stealthDisadvantage, stealthDisadvantage) || other.stealthDisadvantage == stealthDisadvantage));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category,acBase,acDexBonus,strengthRequirement,stealthDisadvantage);

@override
String toString() {
  return 'ProficiencyCatalogArmor(id: $id, name: $name, category: $category, acBase: $acBase, acDexBonus: $acDexBonus, strengthRequirement: $strengthRequirement, stealthDisadvantage: $stealthDisadvantage)';
}


}

/// @nodoc
abstract mixin class $ProficiencyCatalogArmorCopyWith<$Res>  {
  factory $ProficiencyCatalogArmorCopyWith(ProficiencyCatalogArmor value, $Res Function(ProficiencyCatalogArmor) _then) = _$ProficiencyCatalogArmorCopyWithImpl;
@useResult
$Res call({
 int id, String name, String category, int acBase, String acDexBonus, int? strengthRequirement, bool stealthDisadvantage
});




}
/// @nodoc
class _$ProficiencyCatalogArmorCopyWithImpl<$Res>
    implements $ProficiencyCatalogArmorCopyWith<$Res> {
  _$ProficiencyCatalogArmorCopyWithImpl(this._self, this._then);

  final ProficiencyCatalogArmor _self;
  final $Res Function(ProficiencyCatalogArmor) _then;

/// Create a copy of ProficiencyCatalogArmor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? acBase = null,Object? acDexBonus = null,Object? strengthRequirement = freezed,Object? stealthDisadvantage = null,}) {
  return _then(ProficiencyCatalogArmor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,acBase: null == acBase ? _self.acBase : acBase // ignore: cast_nullable_to_non_nullable
as int,acDexBonus: null == acDexBonus ? _self.acDexBonus : acDexBonus // ignore: cast_nullable_to_non_nullable
as String,strengthRequirement: freezed == strengthRequirement ? _self.strengthRequirement : strengthRequirement // ignore: cast_nullable_to_non_nullable
as int?,stealthDisadvantage: null == stealthDisadvantage ? _self.stealthDisadvantage : stealthDisadvantage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProficiencyCatalogArmor].
extension ProficiencyCatalogArmorPatterns on ProficiencyCatalogArmor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProficiencyCatalogArmor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProficiencyCatalogArmor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProficiencyCatalogArmor value)  $default,){
final _that = this;
switch (_that) {
case _ProficiencyCatalogArmor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProficiencyCatalogArmor value)?  $default,){
final _that = this;
switch (_that) {
case _ProficiencyCatalogArmor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String category,  int acBase,  String acDexBonus,  int? strengthRequirement,  bool stealthDisadvantage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProficiencyCatalogArmor() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.acBase,_that.acDexBonus,_that.strengthRequirement,_that.stealthDisadvantage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String category,  int acBase,  String acDexBonus,  int? strengthRequirement,  bool stealthDisadvantage)  $default,) {final _that = this;
switch (_that) {
case _ProficiencyCatalogArmor():
return $default(_that.id,_that.name,_that.category,_that.acBase,_that.acDexBonus,_that.strengthRequirement,_that.stealthDisadvantage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String category,  int acBase,  String acDexBonus,  int? strengthRequirement,  bool stealthDisadvantage)?  $default,) {final _that = this;
switch (_that) {
case _ProficiencyCatalogArmor() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.acBase,_that.acDexBonus,_that.strengthRequirement,_that.stealthDisadvantage);case _:
  return null;

}
}

}

/// @nodoc


class _ProficiencyCatalogArmor implements ProficiencyCatalogArmor {
  const _ProficiencyCatalogArmor({required this.id, required this.name, required this.category, required this.acBase, required this.acDexBonus, this.strengthRequirement, this.stealthDisadvantage = false});
  

/// `items.id`.
@override final  int id;
/// Nom français (`translations`, `entity_type = 'item'`).
@override final  String name;
/// `items.category` ('armure' ou 'bouclier') — distingue le gabarit
/// d'affichage du panneau "Infos" (armure complète vs bouclier "CA"
/// seule), voir `proficiency_detail_panel.dart::_ArmorDetailRow`.
@override final  String category;
/// `armor_properties.ac_base` — pour un bouclier, un bonus (+2) plutôt
/// qu'une CA de base à proprement parler, même convention que
/// `CharacterInventoryArmorProperties.acBase`.
@override final  int acBase;
/// `armor_properties.ac_dex_bonus` ('aucun'/'max_2'/'illimite') — voir
/// `ArmorProficiencyCategoryRules.categoryFor` pour la dérivation de
/// catégorie, `InventoryArmorDexBonusFormatter` pour son libellé FR.
@override final  String acDexBonus;
/// `armor_properties.strength_requirement`, `null` si aucune force
/// minimale requise — omis du panneau "Infos" dans ce cas.
@override final  int? strengthRequirement;
@override@JsonKey() final  bool stealthDisadvantage;

/// Create a copy of ProficiencyCatalogArmor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProficiencyCatalogArmorCopyWith<_ProficiencyCatalogArmor> get copyWith => __$ProficiencyCatalogArmorCopyWithImpl<_ProficiencyCatalogArmor>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProficiencyCatalogArmor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.acBase, acBase) || other.acBase == acBase)&&(identical(other.acDexBonus, acDexBonus) || other.acDexBonus == acDexBonus)&&(identical(other.strengthRequirement, strengthRequirement) || other.strengthRequirement == strengthRequirement)&&(identical(other.stealthDisadvantage, stealthDisadvantage) || other.stealthDisadvantage == stealthDisadvantage));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category,acBase,acDexBonus,strengthRequirement,stealthDisadvantage);

@override
String toString() {
  return 'ProficiencyCatalogArmor(id: $id, name: $name, category: $category, acBase: $acBase, acDexBonus: $acDexBonus, strengthRequirement: $strengthRequirement, stealthDisadvantage: $stealthDisadvantage)';
}


}

/// @nodoc
abstract mixin class _$ProficiencyCatalogArmorCopyWith<$Res> implements $ProficiencyCatalogArmorCopyWith<$Res> {
  factory _$ProficiencyCatalogArmorCopyWith(_ProficiencyCatalogArmor value, $Res Function(_ProficiencyCatalogArmor) _then) = __$ProficiencyCatalogArmorCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String category, int acBase, String acDexBonus, int? strengthRequirement, bool stealthDisadvantage
});




}
/// @nodoc
class __$ProficiencyCatalogArmorCopyWithImpl<$Res>
    implements _$ProficiencyCatalogArmorCopyWith<$Res> {
  __$ProficiencyCatalogArmorCopyWithImpl(this._self, this._then);

  final _ProficiencyCatalogArmor _self;
  final $Res Function(_ProficiencyCatalogArmor) _then;

/// Create a copy of ProficiencyCatalogArmor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? acBase = null,Object? acDexBonus = null,Object? strengthRequirement = freezed,Object? stealthDisadvantage = null,}) {
  return _then(_ProficiencyCatalogArmor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,acBase: null == acBase ? _self.acBase : acBase // ignore: cast_nullable_to_non_nullable
as int,acDexBonus: null == acDexBonus ? _self.acDexBonus : acDexBonus // ignore: cast_nullable_to_non_nullable
as String,strengthRequirement: freezed == strengthRequirement ? _self.strengthRequirement : strengthRequirement // ignore: cast_nullable_to_non_nullable
as int?,stealthDisadvantage: null == stealthDisadvantage ? _self.stealthDisadvantage : stealthDisadvantage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ProficiencyCatalog {

 List<ProficiencyCatalogWeapon> get weapons; List<ProficiencyCatalogArmor> get armors; List<ProficiencyCatalogArmor> get shields;
/// Create a copy of ProficiencyCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProficiencyCatalogCopyWith<ProficiencyCatalog> get copyWith => _$ProficiencyCatalogCopyWithImpl<ProficiencyCatalog>(this as ProficiencyCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProficiencyCatalog&&const DeepCollectionEquality().equals(other.weapons, weapons)&&const DeepCollectionEquality().equals(other.armors, armors)&&const DeepCollectionEquality().equals(other.shields, shields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(weapons),const DeepCollectionEquality().hash(armors),const DeepCollectionEquality().hash(shields));

@override
String toString() {
  return 'ProficiencyCatalog(weapons: $weapons, armors: $armors, shields: $shields)';
}


}

/// @nodoc
abstract mixin class $ProficiencyCatalogCopyWith<$Res>  {
  factory $ProficiencyCatalogCopyWith(ProficiencyCatalog value, $Res Function(ProficiencyCatalog) _then) = _$ProficiencyCatalogCopyWithImpl;
@useResult
$Res call({
 List<ProficiencyCatalogWeapon> weapons, List<ProficiencyCatalogArmor> armors, List<ProficiencyCatalogArmor> shields
});




}
/// @nodoc
class _$ProficiencyCatalogCopyWithImpl<$Res>
    implements $ProficiencyCatalogCopyWith<$Res> {
  _$ProficiencyCatalogCopyWithImpl(this._self, this._then);

  final ProficiencyCatalog _self;
  final $Res Function(ProficiencyCatalog) _then;

/// Create a copy of ProficiencyCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weapons = null,Object? armors = null,Object? shields = null,}) {
  return _then(ProficiencyCatalog(
weapons: null == weapons ? _self.weapons : weapons // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogWeapon>,armors: null == armors ? _self.armors : armors // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogArmor>,shields: null == shields ? _self.shields : shields // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogArmor>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProficiencyCatalog].
extension ProficiencyCatalogPatterns on ProficiencyCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProficiencyCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProficiencyCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProficiencyCatalog value)  $default,){
final _that = this;
switch (_that) {
case _ProficiencyCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProficiencyCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _ProficiencyCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProficiencyCatalogWeapon> weapons,  List<ProficiencyCatalogArmor> armors,  List<ProficiencyCatalogArmor> shields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProficiencyCatalog() when $default != null:
return $default(_that.weapons,_that.armors,_that.shields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProficiencyCatalogWeapon> weapons,  List<ProficiencyCatalogArmor> armors,  List<ProficiencyCatalogArmor> shields)  $default,) {final _that = this;
switch (_that) {
case _ProficiencyCatalog():
return $default(_that.weapons,_that.armors,_that.shields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProficiencyCatalogWeapon> weapons,  List<ProficiencyCatalogArmor> armors,  List<ProficiencyCatalogArmor> shields)?  $default,) {final _that = this;
switch (_that) {
case _ProficiencyCatalog() when $default != null:
return $default(_that.weapons,_that.armors,_that.shields);case _:
  return null;

}
}

}

/// @nodoc


class _ProficiencyCatalog implements ProficiencyCatalog {
  const _ProficiencyCatalog({ List<ProficiencyCatalogWeapon> weapons = const <ProficiencyCatalogWeapon>[],  List<ProficiencyCatalogArmor> armors = const <ProficiencyCatalogArmor>[],  List<ProficiencyCatalogArmor> shields = const <ProficiencyCatalogArmor>[]}): _weapons = weapons,_armors = armors,_shields = shields;
  

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

 final  List<ProficiencyCatalogArmor> _shields;
@override@JsonKey() List<ProficiencyCatalogArmor> get shields {
  if (_shields is EqualUnmodifiableListView) return _shields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shields);
}


/// Create a copy of ProficiencyCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProficiencyCatalogCopyWith<_ProficiencyCatalog> get copyWith => __$ProficiencyCatalogCopyWithImpl<_ProficiencyCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProficiencyCatalog&&const DeepCollectionEquality().equals(other._weapons, _weapons)&&const DeepCollectionEquality().equals(other._armors, _armors)&&const DeepCollectionEquality().equals(other._shields, _shields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_weapons),const DeepCollectionEquality().hash(_armors),const DeepCollectionEquality().hash(_shields));

@override
String toString() {
  return 'ProficiencyCatalog(weapons: $weapons, armors: $armors, shields: $shields)';
}


}

/// @nodoc
abstract mixin class _$ProficiencyCatalogCopyWith<$Res> implements $ProficiencyCatalogCopyWith<$Res> {
  factory _$ProficiencyCatalogCopyWith(_ProficiencyCatalog value, $Res Function(_ProficiencyCatalog) _then) = __$ProficiencyCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<ProficiencyCatalogWeapon> weapons, List<ProficiencyCatalogArmor> armors, List<ProficiencyCatalogArmor> shields
});




}
/// @nodoc
class __$ProficiencyCatalogCopyWithImpl<$Res>
    implements _$ProficiencyCatalogCopyWith<$Res> {
  __$ProficiencyCatalogCopyWithImpl(this._self, this._then);

  final _ProficiencyCatalog _self;
  final $Res Function(_ProficiencyCatalog) _then;

/// Create a copy of ProficiencyCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weapons = null,Object? armors = null,Object? shields = null,}) {
  return _then(_ProficiencyCatalog(
weapons: null == weapons ? _self._weapons : weapons // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogWeapon>,armors: null == armors ? _self._armors : armors // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogArmor>,shields: null == shields ? _self._shields : shields // ignore: cast_nullable_to_non_nullable
as List<ProficiencyCatalogArmor>,
  ));
}


}

// dart format on
