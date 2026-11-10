import 'dart:async';

import 'package:personnages/core/network/connectivity_checker.dart';

/// Double de [ConnectivityChecker] à état et flux contrôlables par le test
/// (harnais de la file hors-ligne).
///
/// - [connected] : valeur renvoyée par [hasConnection] ;
/// - [goOffline] / [goOnline] : change l'état ; [goOffline] émet sur
///   [onConnectivityChanged] (`false`), [goOnline] émet sur
///   [onConnectivityChanged] (`true`) ET l'événement de retour du réseau
///   [onConnectivityRestored], comme le vrai [ConnectivityPlusChecker] sur
///   une transition hors-ligne -> en ligne ;
/// - [emitRestored] : émet l'événement sans changer l'état (réseau instable).
class FakeConnectivityChecker implements ConnectivityChecker {
  FakeConnectivityChecker({this.connected = true});

  bool connected;
  final _restored = StreamController<bool>.broadcast();
  final _changed = StreamController<bool>.broadcast();

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => _restored.stream;

  @override
  Stream<bool> get onConnectivityChanged => _changed.stream;

  void goOffline() {
    connected = false;
    _changed.add(false);
  }

  void goOnline() {
    connected = true;
    _changed.add(true);
    emitRestored();
  }

  void emitRestored() => _restored.add(true);

  Future<void> close() async {
    await _restored.close();
    await _changed.close();
  }
}
