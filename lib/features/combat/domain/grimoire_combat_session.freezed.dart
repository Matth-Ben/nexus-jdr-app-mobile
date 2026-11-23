// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grimoire_combat_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrimoireCombatSession {

 GrimoireCombatView get view; GrimoireLinkStatus get link;/// Entrée dans l'état [link] courant (horloge de Nexus).
 DateTime? get linkSince;/// `is_leader` de `api_v1.group_live_channels` : le compte mène ce combat
/// depuis Grimoire (bandeau d'information, aucun contrôle).
 bool get isLeader;/// Incrémenté à chaque lot d'évènements reçus ([events]).
 int get eventSerial; List<GrimoireCombatEvent> get events;
/// Create a copy of GrimoireCombatSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireCombatSessionCopyWith<GrimoireCombatSession> get copyWith => _$GrimoireCombatSessionCopyWithImpl<GrimoireCombatSession>(this as GrimoireCombatSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireCombatSession&&(identical(other.view, view) || other.view == view)&&(identical(other.link, link) || other.link == link)&&(identical(other.linkSince, linkSince) || other.linkSince == linkSince)&&(identical(other.isLeader, isLeader) || other.isLeader == isLeader)&&(identical(other.eventSerial, eventSerial) || other.eventSerial == eventSerial)&&const DeepCollectionEquality().equals(other.events, events));
}


@override
int get hashCode => Object.hash(runtimeType,view,link,linkSince,isLeader,eventSerial,const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'GrimoireCombatSession(view: $view, link: $link, linkSince: $linkSince, isLeader: $isLeader, eventSerial: $eventSerial, events: $events)';
}


}

/// @nodoc
abstract mixin class $GrimoireCombatSessionCopyWith<$Res>  {
  factory $GrimoireCombatSessionCopyWith(GrimoireCombatSession value, $Res Function(GrimoireCombatSession) _then) = _$GrimoireCombatSessionCopyWithImpl;
@useResult
$Res call({
 GrimoireCombatView view, GrimoireLinkStatus link, DateTime? linkSince, bool isLeader, int eventSerial, List<GrimoireCombatEvent> events
});


$GrimoireCombatViewCopyWith<$Res> get view;

}
/// @nodoc
class _$GrimoireCombatSessionCopyWithImpl<$Res>
    implements $GrimoireCombatSessionCopyWith<$Res> {
  _$GrimoireCombatSessionCopyWithImpl(this._self, this._then);

  final GrimoireCombatSession _self;
  final $Res Function(GrimoireCombatSession) _then;

/// Create a copy of GrimoireCombatSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? view = null,Object? link = null,Object? linkSince = freezed,Object? isLeader = null,Object? eventSerial = null,Object? events = null,}) {
  return _then(GrimoireCombatSession(
view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as GrimoireCombatView,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as GrimoireLinkStatus,linkSince: freezed == linkSince ? _self.linkSince : linkSince // ignore: cast_nullable_to_non_nullable
as DateTime?,isLeader: null == isLeader ? _self.isLeader : isLeader // ignore: cast_nullable_to_non_nullable
as bool,eventSerial: null == eventSerial ? _self.eventSerial : eventSerial // ignore: cast_nullable_to_non_nullable
as int,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<GrimoireCombatEvent>,
  ));
}
/// Create a copy of GrimoireCombatSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GrimoireCombatViewCopyWith<$Res> get view {
  
  return $GrimoireCombatViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}


/// Adds pattern-matching-related methods to [GrimoireCombatSession].
extension GrimoireCombatSessionPatterns on GrimoireCombatSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrimoireCombatSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrimoireCombatSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrimoireCombatSession value)  $default,){
final _that = this;
switch (_that) {
case _GrimoireCombatSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrimoireCombatSession value)?  $default,){
final _that = this;
switch (_that) {
case _GrimoireCombatSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GrimoireCombatView view,  GrimoireLinkStatus link,  DateTime? linkSince,  bool isLeader,  int eventSerial,  List<GrimoireCombatEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrimoireCombatSession() when $default != null:
return $default(_that.view,_that.link,_that.linkSince,_that.isLeader,_that.eventSerial,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GrimoireCombatView view,  GrimoireLinkStatus link,  DateTime? linkSince,  bool isLeader,  int eventSerial,  List<GrimoireCombatEvent> events)  $default,) {final _that = this;
switch (_that) {
case _GrimoireCombatSession():
return $default(_that.view,_that.link,_that.linkSince,_that.isLeader,_that.eventSerial,_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GrimoireCombatView view,  GrimoireLinkStatus link,  DateTime? linkSince,  bool isLeader,  int eventSerial,  List<GrimoireCombatEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _GrimoireCombatSession() when $default != null:
return $default(_that.view,_that.link,_that.linkSince,_that.isLeader,_that.eventSerial,_that.events);case _:
  return null;

}
}

}

/// @nodoc


class _GrimoireCombatSession extends GrimoireCombatSession {
  const _GrimoireCombatSession({this.view = const GrimoireCombatView(), this.link = GrimoireLinkStatus.idle, this.linkSince, this.isLeader = false, this.eventSerial = 0,  List<GrimoireCombatEvent> events = const <GrimoireCombatEvent>[]}): _events = events,super._();
  

@override@JsonKey() final  GrimoireCombatView view;
@override@JsonKey() final  GrimoireLinkStatus link;
/// Entrée dans l'état [link] courant (horloge de Nexus).
@override final  DateTime? linkSince;
/// `is_leader` de `api_v1.group_live_channels` : le compte mène ce combat
/// depuis Grimoire (bandeau d'information, aucun contrôle).
@override@JsonKey() final  bool isLeader;
/// Incrémenté à chaque lot d'évènements reçus ([events]).
@override@JsonKey() final  int eventSerial;
 final  List<GrimoireCombatEvent> _events;
@override@JsonKey() List<GrimoireCombatEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of GrimoireCombatSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrimoireCombatSessionCopyWith<_GrimoireCombatSession> get copyWith => __$GrimoireCombatSessionCopyWithImpl<_GrimoireCombatSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrimoireCombatSession&&(identical(other.view, view) || other.view == view)&&(identical(other.link, link) || other.link == link)&&(identical(other.linkSince, linkSince) || other.linkSince == linkSince)&&(identical(other.isLeader, isLeader) || other.isLeader == isLeader)&&(identical(other.eventSerial, eventSerial) || other.eventSerial == eventSerial)&&const DeepCollectionEquality().equals(other._events, _events));
}


@override
int get hashCode => Object.hash(runtimeType,view,link,linkSince,isLeader,eventSerial,const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'GrimoireCombatSession(view: $view, link: $link, linkSince: $linkSince, isLeader: $isLeader, eventSerial: $eventSerial, events: $events)';
}


}

/// @nodoc
abstract mixin class _$GrimoireCombatSessionCopyWith<$Res> implements $GrimoireCombatSessionCopyWith<$Res> {
  factory _$GrimoireCombatSessionCopyWith(_GrimoireCombatSession value, $Res Function(_GrimoireCombatSession) _then) = __$GrimoireCombatSessionCopyWithImpl;
@override @useResult
$Res call({
 GrimoireCombatView view, GrimoireLinkStatus link, DateTime? linkSince, bool isLeader, int eventSerial, List<GrimoireCombatEvent> events
});


@override $GrimoireCombatViewCopyWith<$Res> get view;

}
/// @nodoc
class __$GrimoireCombatSessionCopyWithImpl<$Res>
    implements _$GrimoireCombatSessionCopyWith<$Res> {
  __$GrimoireCombatSessionCopyWithImpl(this._self, this._then);

  final _GrimoireCombatSession _self;
  final $Res Function(_GrimoireCombatSession) _then;

/// Create a copy of GrimoireCombatSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? view = null,Object? link = null,Object? linkSince = freezed,Object? isLeader = null,Object? eventSerial = null,Object? events = null,}) {
  return _then(_GrimoireCombatSession(
view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as GrimoireCombatView,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as GrimoireLinkStatus,linkSince: freezed == linkSince ? _self.linkSince : linkSince // ignore: cast_nullable_to_non_nullable
as DateTime?,isLeader: null == isLeader ? _self.isLeader : isLeader // ignore: cast_nullable_to_non_nullable
as bool,eventSerial: null == eventSerial ? _self.eventSerial : eventSerial // ignore: cast_nullable_to_non_nullable
as int,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<GrimoireCombatEvent>,
  ));
}

/// Create a copy of GrimoireCombatSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GrimoireCombatViewCopyWith<$Res> get view {
  
  return $GrimoireCombatViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

// dart format on
