/// Comparaison sémantique de deux numéros de version `major.minor.patch`
/// (format des colonnes `app_versions.minimum_supported_version`/
/// `latest_version`, voir `data/app_version_repository.dart`, et de
/// `PackageInfo.version`).
///
/// Toujours une comparaison **numérique** segment par segment, jamais une
/// comparaison de chaînes : `"1.2.0"` doit être considérée strictement
/// inférieure à `"1.10.0"` (une comparaison lexicographique de chaînes
/// classerait `"1.10.0"` avant `"1.2.0"`, `'1' < '2'`).
abstract final class AppVersionComparator {
  /// Compare [a] à [b] : négatif si `a < b`, zéro si égales, positif si
  /// `a > b` — même contrat que `Comparable.compareTo`.
  ///
  /// Un segment manquant ou non numérique (version malformée, ne devrait
  /// jamais arriver pour des colonnes contrôlées côté serveur, mais jamais
  /// supposé côté client) est traité comme `0`, plutôt que de lever une
  /// exception : une comparaison "raisonnable mais imprécise" est préférable
  /// ici à un crash qui bloquerait tout affichage de l'app.
  static int compare(String a, String b) {
    final segmentsA = _parse(a);
    final segmentsB = _parse(b);
    for (var i = 0; i < 3; i++) {
      final result = segmentsA[i].compareTo(segmentsB[i]);
      if (result != 0) return result;
    }
    return 0;
  }

  /// `true` si [a] est strictement inférieure à [b] — sucre au-dessus de
  /// [compare], pour les points d'appel qui n'ont besoin que de ce test
  /// (résolution de statut, voir `presentation/providers/app_version_providers.dart`).
  static bool isLowerThan(String a, String b) => compare(a, b) < 0;

  static List<int> _parse(String version) {
    final rawSegments = version.split('.');
    return List<int>.generate(3, (index) {
      if (index >= rawSegments.length) return 0;
      return int.tryParse(rawSegments[index].trim()) ?? 0;
    });
  }
}
