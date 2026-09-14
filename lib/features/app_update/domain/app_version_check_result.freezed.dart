// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_version_check_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppVersionCheckResult {

 AppVersionStatus get status; String get installedVersion; String get minimumVersion; String get latestVersion;
/// Create a copy of AppVersionCheckResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppVersionCheckResultCopyWith<AppVersionCheckResult> get copyWith => _$AppVersionCheckResultCopyWithImpl<AppVersionCheckResult>(this as AppVersionCheckResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppVersionCheckResult&&(identical(other.status, status) || other.status == status)&&(identical(other.installedVersion, installedVersion) || other.installedVersion == installedVersion)&&(identical(other.minimumVersion, minimumVersion) || other.minimumVersion == minimumVersion)&&(identical(other.latestVersion, latestVersion) || other.latestVersion == latestVersion));
}


@override
int get hashCode => Object.hash(runtimeType,status,installedVersion,minimumVersion,latestVersion);

@override
String toString() {
  return 'AppVersionCheckResult(status: $status, installedVersion: $installedVersion, minimumVersion: $minimumVersion, latestVersion: $latestVersion)';
}


}

/// @nodoc
abstract mixin class $AppVersionCheckResultCopyWith<$Res>  {
  factory $AppVersionCheckResultCopyWith(AppVersionCheckResult value, $Res Function(AppVersionCheckResult) _then) = _$AppVersionCheckResultCopyWithImpl;
@useResult
$Res call({
 AppVersionStatus status, String installedVersion, String minimumVersion, String latestVersion
});




}
/// @nodoc
class _$AppVersionCheckResultCopyWithImpl<$Res>
    implements $AppVersionCheckResultCopyWith<$Res> {
  _$AppVersionCheckResultCopyWithImpl(this._self, this._then);

  final AppVersionCheckResult _self;
  final $Res Function(AppVersionCheckResult) _then;

/// Create a copy of AppVersionCheckResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? installedVersion = null,Object? minimumVersion = null,Object? latestVersion = null,}) {
  return _then(AppVersionCheckResult(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppVersionStatus,installedVersion: null == installedVersion ? _self.installedVersion : installedVersion // ignore: cast_nullable_to_non_nullable
as String,minimumVersion: null == minimumVersion ? _self.minimumVersion : minimumVersion // ignore: cast_nullable_to_non_nullable
as String,latestVersion: null == latestVersion ? _self.latestVersion : latestVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppVersionCheckResult].
extension AppVersionCheckResultPatterns on AppVersionCheckResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppVersionCheckResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppVersionCheckResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppVersionCheckResult value)  $default,){
final _that = this;
switch (_that) {
case _AppVersionCheckResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppVersionCheckResult value)?  $default,){
final _that = this;
switch (_that) {
case _AppVersionCheckResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppVersionStatus status,  String installedVersion,  String minimumVersion,  String latestVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppVersionCheckResult() when $default != null:
return $default(_that.status,_that.installedVersion,_that.minimumVersion,_that.latestVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppVersionStatus status,  String installedVersion,  String minimumVersion,  String latestVersion)  $default,) {final _that = this;
switch (_that) {
case _AppVersionCheckResult():
return $default(_that.status,_that.installedVersion,_that.minimumVersion,_that.latestVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppVersionStatus status,  String installedVersion,  String minimumVersion,  String latestVersion)?  $default,) {final _that = this;
switch (_that) {
case _AppVersionCheckResult() when $default != null:
return $default(_that.status,_that.installedVersion,_that.minimumVersion,_that.latestVersion);case _:
  return null;

}
}

}

/// @nodoc


class _AppVersionCheckResult implements AppVersionCheckResult {
  const _AppVersionCheckResult({required this.status, required this.installedVersion, required this.minimumVersion, required this.latestVersion});
  

@override final  AppVersionStatus status;
@override final  String installedVersion;
@override final  String minimumVersion;
@override final  String latestVersion;

/// Create a copy of AppVersionCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppVersionCheckResultCopyWith<_AppVersionCheckResult> get copyWith => __$AppVersionCheckResultCopyWithImpl<_AppVersionCheckResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppVersionCheckResult&&(identical(other.status, status) || other.status == status)&&(identical(other.installedVersion, installedVersion) || other.installedVersion == installedVersion)&&(identical(other.minimumVersion, minimumVersion) || other.minimumVersion == minimumVersion)&&(identical(other.latestVersion, latestVersion) || other.latestVersion == latestVersion));
}


@override
int get hashCode => Object.hash(runtimeType,status,installedVersion,minimumVersion,latestVersion);

@override
String toString() {
  return 'AppVersionCheckResult(status: $status, installedVersion: $installedVersion, minimumVersion: $minimumVersion, latestVersion: $latestVersion)';
}


}

/// @nodoc
abstract mixin class _$AppVersionCheckResultCopyWith<$Res> implements $AppVersionCheckResultCopyWith<$Res> {
  factory _$AppVersionCheckResultCopyWith(_AppVersionCheckResult value, $Res Function(_AppVersionCheckResult) _then) = __$AppVersionCheckResultCopyWithImpl;
@override @useResult
$Res call({
 AppVersionStatus status, String installedVersion, String minimumVersion, String latestVersion
});




}
/// @nodoc
class __$AppVersionCheckResultCopyWithImpl<$Res>
    implements _$AppVersionCheckResultCopyWith<$Res> {
  __$AppVersionCheckResultCopyWithImpl(this._self, this._then);

  final _AppVersionCheckResult _self;
  final $Res Function(_AppVersionCheckResult) _then;

/// Create a copy of AppVersionCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? installedVersion = null,Object? minimumVersion = null,Object? latestVersion = null,}) {
  return _then(_AppVersionCheckResult(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppVersionStatus,installedVersion: null == installedVersion ? _self.installedVersion : installedVersion // ignore: cast_nullable_to_non_nullable
as String,minimumVersion: null == minimumVersion ? _self.minimumVersion : minimumVersion // ignore: cast_nullable_to_non_nullable
as String,latestVersion: null == latestVersion ? _self.latestVersion : latestVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
