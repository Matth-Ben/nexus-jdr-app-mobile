/// `character_spells.status` — remplace les chaînes brutes `'connu'`/
/// `'préparé'`/`'inné'` dispersées dans ~20 fichiers (dette D04,
/// `docs/dette-technique.md`). La colonne reste une chaîne côté Supabase
/// (contrainte `CHECK`, hors périmètre de ce chantier — aucune migration de
/// schéma) : [value] est la conversion vers cette chaîne, [fromValue] la
/// conversion depuis une ligne lue, toutes deux à n'appeler qu'à la frontière
/// avec Supabase (requêtes PostgREST, lignes brutes `Map<String, dynamic>`)
/// — jamais ailleurs, où ce type doit circuler tel quel.
enum SpellStatus {
  /// Sort appris définitivement (classes « à sorts connus » : Barde,
  /// Ensorceleur, Occultiste, Rôdeur), ou sort de la liste de classe d'un
  /// lanceur à préparation jamais encore préparé (repli historique, voir
  /// `characters/data/character_spell_row_mapper.dart`).
  known('connu'),

  /// Sort choisi aujourd'hui parmi les sorts accessibles (classes « à
  /// préparation » : Clerc, Druide, Magicien, Paladin, Artificier), ou sort
  /// accordé automatiquement par une sous-classe (toujours préparé).
  prepared('préparé'),

  /// Sort inné (racial, ou importé depuis un export aidedd.org) : se lance
  /// sans emplacement, sans notion de préparation.
  innate('inné');

  const SpellStatus(this.value);

  /// Valeur stockée dans `character_spells.status` côté Supabase.
  final String value;

  /// Résout une valeur brute lue en base vers son [SpellStatus] — [fallback]
  /// ([known] par défaut, le repli historique déjà en place avant cet enum)
  /// pour toute valeur `null`/inattendue (ne devrait arriver que pour une
  /// ligne absente de `character_spells`, jamais pour une valeur stockée :
  /// la contrainte `CHECK` côté base n'autorise que ces 3 valeurs).
  static SpellStatus fromValue(
    String? value, {
    SpellStatus fallback = SpellStatus.known,
  }) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return fallback;
  }
}
