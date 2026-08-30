import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction de vérification de connectivité réseau, au-dessus de
/// `package:connectivity_plus` — jamais utilisé directement ailleurs dans ce
/// dépôt, pour que les tests puissent injecter un double sans jamais toucher
/// au canal de plateforme réel (indisponible dans `flutter test` en dehors
/// d'un appareil/simulateur, voir [ConnectivityPlusChecker]).
///
/// Consommé par `SupabaseCharacterRepository.updateHp`/`addXp`
/// (`features/characters/data/character_repository.dart` — vérification
/// *avant* toute tentative réseau, voir leur documentation pour le rationale
/// de ce choix plutôt que de deviner depuis le type d'exception levée) et par
/// `features/characters/presentation/providers/character_write_sync_coordinator.dart`
/// (déclenche une tentative de synchro des écritures PV/XP en attente à
/// chaque retour de connectivité).
abstract class ConnectivityChecker {
  /// `true` si au moins une interface réseau est actuellement considérée
  /// connectée (Wi-Fi, données mobiles, ethernet...). Ne garantit pas un
  /// accès Internet effectif de bout en bout (un portail captif, par
  /// exemple, resterait "connecté" ici) — suffisant pour ce dépôt : voir la
  /// documentation d'[updateHp]/[addXp] sur les deux cas distingués
  /// (connectivité absente vs. connectivité présente mais écriture réseau en
  /// échec, ce second cas n'étant volontairement jamais mis en file).
  Future<bool> hasConnection();

  /// Émet `true` à chaque fois que la connectivité passe d'un état déconnecté
  /// à un état connecté — jamais d'événement pour un passage connecté vers
  /// déconnecté, ni pour un changement d'interface connectée vers une autre
  /// interface elle aussi connectée.
  Stream<bool> get onConnectivityRestored;
}

/// Implémentation réelle, au-dessus de [Connectivity]. [connectivity]
/// injectable pour les tests bas niveau de cette classe précise (aucun test
/// de ce genre n'existe encore dans ce dépôt : les consommateurs de
/// [ConnectivityChecker] injectent plutôt un double de l'abstraction
/// elle-même, jamais un [Connectivity] factice).
class ConnectivityPlusChecker implements ConnectivityChecker {
  ConnectivityPlusChecker([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  @override
  Stream<bool> get onConnectivityRestored => _connectivity.onConnectivityChanged
      .map(_isConnected)
      .where((connected) => connected);

  static bool _isConnected(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
