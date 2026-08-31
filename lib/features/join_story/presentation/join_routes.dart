/// Construit les routes du flux "Rejoindre une histoire" — seul point du
/// module qui réinjecte le code d'invitation dans une URL, pour ne jamais
/// dupliquer (et risquer d'oublier une fois) l'encodage correct de [code].
///
/// **Pourquoi pas une simple interpolation de chaîne** (`'/join/step-2?code=$code'`,
/// piège trouvé en revue de code) : à l'étape 1/4 (saisie manuelle), [code]
/// est déjà filtré par `JoinCodeStepScreen` (`FilteringTextInputFormatter`,
/// alphanumérique uniquement) — mais le point d'entrée par deep link
/// universel (`/join/:code` dans `core/router/app_router.dart`) résout
/// [code] directement depuis le segment de chemin BRUT de l'URL entrante,
/// sans repasser par ce filtre. Un code contenant `#` tronque alors
/// silencieusement la query d'une interpolation brute (`code=AB#frag` →
/// `code: AB`, le reste interprété comme un fragment d'URL) ; un code
/// contenant `&` y injecte un paramètre de query supplémentaire. `Uri(path:
/// ..., queryParameters: {'code': code})` échappe correctement ces deux cas
/// (et tout autre caractère spécial d'URL) — utilisé ici pour les 3 routes
/// qui réinjectent un code déjà résolu (jamais pour la saisie initiale de
/// l'étape 1/4 elle-même, qui n'a rien à réinjecter).
abstract final class JoinRoutes {
  /// Étape 1/4 — [initialCode] préremplit le champ (bouton "Modifier le
  /// code" de l'étape 2/4 en cas de code invalide/invitation désactivée).
  static String code({String? initialCode}) {
    return Uri(
      path: '/join',
      queryParameters: initialCode == null ? null : {'code': initialCode},
    ).toString();
  }

  /// Étape 2/4 — confirmation (nom + couverture de l'histoire).
  static String confirmation(String code) {
    return Uri(
      path: '/join/step-2',
      queryParameters: {'code': code},
    ).toString();
  }

  /// Étape 3/4 — choix du personnage à rattacher.
  static String character(String code) {
    return Uri(
      path: '/join/step-3',
      queryParameters: {'code': code},
    ).toString();
  }
}
