/// Formatte un modificateur/bonus signé pour l'affichage ("+2"/"−1") — utilisé
/// par la grille de caractéristiques et la carte "Jets de sauvegarde" de la
/// fiche personnage (spec visuelle : "signe explicite (+2/−1, vrai signe
/// moins Unicode)").
///
/// Partagé entre les deux widgets plutôt que dupliqué : contrairement aux
/// mappers `data/`, c'est une règle de formatage strictement identique dans
/// les deux cas (pas deux règles métier distinctes qui pourraient diverger
/// avec le temps) — voir le commentaire de classe de `RaceRowMapper` pour le
/// rationale habituel de duplication de ce dépôt, qui ne s'applique donc pas
/// ici.
abstract final class SignedModifierFormatter {
  /// U+2212 (signe moins mathématique), pas le trait d'union ASCII '-' —
  /// exigé explicitement par la spec visuelle.
  static const String _minusSign = '−';

  static String format(int value) {
    return value < 0 ? '$_minusSign${-value}' : '+$value';
  }
}
