/// Construit les routes du flux "Rejoindre un groupe" — calque exact de
/// `features/join_story/presentation/join_routes.dart::JoinRoutes` (voir sa
/// documentation de classe pour le rationale complet de l'encodage `Uri`
/// plutôt qu'une interpolation de chaîne brute), adapté à 3 étapes au lieu de
/// 4 (pas de deep link universel pour ce flux, contrairement à
/// `/join/:code`) — voir `docs/cahier-des-charges/12-partage-et-groupes.md`
/// section 2.
abstract final class GroupJoinRoutes {
  /// Étape 1/3 — saisie du code.
  static String code({String? initialCode}) {
    return Uri(
      path: '/groups/join',
      queryParameters: initialCode == null ? null : {'code': initialCode},
    ).toString();
  }

  /// Étape 2/3 — confirmation (nom + nombre de membres du groupe).
  static String confirmation(String code) {
    return Uri(
      path: '/groups/join/step-2',
      queryParameters: {'code': code},
    ).toString();
  }

  /// Étape 3/3 — choix du personnage à rattacher.
  static String character(String code) {
    return Uri(
      path: '/groups/join/step-3',
      queryParameters: {'code': code},
    ).toString();
  }
}
