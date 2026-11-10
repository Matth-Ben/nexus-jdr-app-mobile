import 'dart:async';

import 'package:personnages/core/network/connectivity_checker.dart';

/// Double de [ConnectivityChecker] à état et flux contrôlables par le test
/// (harnais de la file hors-ligne).
///
/// - [connected] : valeur renvoyée par [hasConnection] ;
/// - [goOffline] / [goOnline] : change l'état ; [goOnline] émet aussi
///   l'événement de retour du réseau, comme le vrai
///   [ConnectivityPlusChecker] sur une transition hors-ligne -> en ligne ;
/// - [emitRestored] : émet l'événement sans changer l'état (réseau instable).
class FakeConnectivityChecker implements ConnectivityChecker {
  FakeConnectivityChecker({this.connected = true});

  bool connected;
  final _restored = StreamController<bool>.broadcast();

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => _restored.stream;

  void goOffline() => connected = false;

  void goOnline() {
    connected = true;
    emitRestored();
  }

  void emitRestored() => _restored.add(true);

  Future<void> close() => _restored.close();
}
