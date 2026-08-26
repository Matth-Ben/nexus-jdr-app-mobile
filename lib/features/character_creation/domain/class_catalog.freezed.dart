// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClassCatalog {

 List<ClassOption> get classes;
/// Create a copy of ClassCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassCatalogCopyWith<ClassCatalog> get copyWith => _$ClassCatalogCopyWithImpl<ClassCatalog>(this as ClassCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassCatalog&&const DeepCollectionEquality().equals(other.classes, classes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(classes));

@override
String toString() {
  return 'ClassCatalog(classes: $classes)';
}


}

/// @nodoc
abstract mixin class $ClassCatalogCopyWith<$Res>  {
  factory $ClassCatalogCopyWith(ClassCatalog value, $Res Function(ClassCatalog) _then) = _$ClassCatalogCopyWithImpl;
@useResult
$Res call({
 List<ClassOption> classes
});




}
/// @nodoc
class _$ClassCatalogCopyWithImpl<$Res>
    implements $ClassCatalogCopyWith<$Res> {
  _$ClassCatalogCopyWithImpl(this._self, this._then);

  final ClassCatalog _self;
  final $Res Function(ClassCatalog) _then;

/// Create a copy of ClassCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? classes = null,}) {
  return _then(ClassCatalog(
classes: null == classes ? _self.classes : classes // ignore: cast_nullable_to_non_nullable
as List<ClassOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassCatalog].
extension ClassCatalogPatterns on ClassCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassCatalog value)  $default,){
final _that = this;
switch (_that) {
case _ClassCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _ClassCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ClassOption> classes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassCatalog() when $default != null:
return $default(_that.classes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ClassOption> classes)  $default,) {final _that = this;
switch (_that) {
case _ClassCatalog():
return $default(_that.classes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ClassOption> classes)?  $default,) {final _that = this;
switch (_that) {
case _ClassCatalog() when $default != null:
return $default(_that.classes);case _:
  return null;

}
}

}

/// @nodoc


class _ClassCatalog implements ClassCatalog {
  const _ClassCatalog({required  List<ClassOption> classes}): _classes = classes;
  

 final  List<ClassOption> _classes;
@override List<ClassOption> get classes {
  if (_classes is EqualUnmodifiableListView) return _classes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classes);
}


/// Create a copy of ClassCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassCatalogCopyWith<_ClassCatalog> get copyWith => __$ClassCatalogCopyWithImpl<_ClassCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassCatalog&&const DeepCollectionEquality().equals(other._classes, _classes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_classes));

@override
String toString() {
  return 'ClassCatalog(classes: $classes)';
}


}

/// @nodoc
abstract mixin class _$ClassCatalogCopyWith<$Res> implements $ClassCatalogCopyWith<$Res> {
  factory _$ClassCatalogCopyWith(_ClassCatalog value, $Res Function(_ClassCatalog) _then) = __$ClassCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<ClassOption> classes
});




}
/// @nodoc
class __$ClassCatalogCopyWithImpl<$Res>
    implements _$ClassCatalogCopyWith<$Res> {
  __$ClassCatalogCopyWithImpl(this._self, this._then);

  final _ClassCatalog _self;
  final $Res Function(_ClassCatalog) _then;

/// Create a copy of ClassCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? classes = null,}) {
  return _then(_ClassCatalog(
classes: null == classes ? _self._classes : classes // ignore: cast_nullable_to_non_nullable
as List<ClassOption>,
  ));
}


}

// dart format on
