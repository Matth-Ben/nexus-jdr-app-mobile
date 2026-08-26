// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItemCatalog {

 List<ItemOption> get items;
/// Create a copy of ItemCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemCatalogCopyWith<ItemCatalog> get copyWith => _$ItemCatalogCopyWithImpl<ItemCatalog>(this as ItemCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemCatalog&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'ItemCatalog(items: $items)';
}


}

/// @nodoc
abstract mixin class $ItemCatalogCopyWith<$Res>  {
  factory $ItemCatalogCopyWith(ItemCatalog value, $Res Function(ItemCatalog) _then) = _$ItemCatalogCopyWithImpl;
@useResult
$Res call({
 List<ItemOption> items
});




}
/// @nodoc
class _$ItemCatalogCopyWithImpl<$Res>
    implements $ItemCatalogCopyWith<$Res> {
  _$ItemCatalogCopyWithImpl(this._self, this._then);

  final ItemCatalog _self;
  final $Res Function(ItemCatalog) _then;

/// Create a copy of ItemCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(ItemCatalog(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ItemOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemCatalog].
extension ItemCatalogPatterns on ItemCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemCatalog value)  $default,){
final _that = this;
switch (_that) {
case _ItemCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _ItemCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ItemOption> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemCatalog() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ItemOption> items)  $default,) {final _that = this;
switch (_that) {
case _ItemCatalog():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ItemOption> items)?  $default,) {final _that = this;
switch (_that) {
case _ItemCatalog() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _ItemCatalog implements ItemCatalog {
  const _ItemCatalog({required  List<ItemOption> items}): _items = items;
  

 final  List<ItemOption> _items;
@override List<ItemOption> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ItemCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemCatalogCopyWith<_ItemCatalog> get copyWith => __$ItemCatalogCopyWithImpl<_ItemCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemCatalog&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ItemCatalog(items: $items)';
}


}

/// @nodoc
abstract mixin class _$ItemCatalogCopyWith<$Res> implements $ItemCatalogCopyWith<$Res> {
  factory _$ItemCatalogCopyWith(_ItemCatalog value, $Res Function(_ItemCatalog) _then) = __$ItemCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<ItemOption> items
});




}
/// @nodoc
class __$ItemCatalogCopyWithImpl<$Res>
    implements _$ItemCatalogCopyWith<$Res> {
  __$ItemCatalogCopyWithImpl(this._self, this._then);

  final _ItemCatalog _self;
  final $Res Function(_ItemCatalog) _then;

/// Create a copy of ItemCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_ItemCatalog(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ItemOption>,
  ));
}


}

// dart format on
